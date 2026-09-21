import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/race_state.dart';
import '../utils/browser.dart';
import 'room_service.dart';

/// Same-origin browser-tab preview, explicitly NOT a classroom server.
class LocalRoomService implements RoomService {
  final SharedPreferences prefs;
  @override
  final String userId;
  LocalRoomService(this.prefs, this.userId);
  static Future<LocalRoomService> open() async {
    final id = sessionRead('adventure_demo_id') ?? 'demo_${roomCode()}';
    sessionWrite('adventure_demo_id', id);
    return LocalRoomService(await SharedPreferences.getInstance(), id);
  }

  @override
  String get label => 'LOCAL PREVIEW • same browser only';
  @override
  bool get isDemo => true;
  @override
  int get nowMs => DateTime.now().millisecondsSinceEpoch;
  @override
  Stream<bool> get connection => Stream.value(true);
  String _key(String code) => 'adventure_demo_room_$code';
  Future<Map<String, dynamic>> _read(String code) async {
    await prefs.reload();
    return jsonMap(jsonDecode(prefs.getString(_key(code)) ?? '{}'));
  }

  Future<void> _write(String code, Map<String, dynamic> value) =>
      prefs.setString(_key(code), jsonEncode(value));
  @override
  Future<String> create(int level) async {
    final code = roomCode();
    await _write(code, {
      'metadata': newMetadata(userId, level, nowMs),
      'players': {},
    });
    return code;
  }

  @override
  Future<void> join(String code, String nickname, int avatar) async {
    final raw = await _read(code);
    if (raw.isEmpty) throw StateError('Room not found. Check the code.');
    final room = RaceRoom.fromJson(code, raw);
    if (room.expiresAt < nowMs) throw StateError('This room has expired.');
    final players = jsonMap(raw['players']);
    if (jsonMap(raw['blocked'])[userId] == true) {
      throw StateError('You have been removed from this room.');
    }
    if (players.containsKey(userId)) {
      final player = jsonMap(players[userId]);
      player['connected'] = true;
      players[userId] = player;
    } else {
      if (room.locked || room.phase != RoomPhase.lobby) {
        throw StateError('Room is locked or already racing.');
      }
      if (players.length >= 50) throw StateError('Room is full (50 players).');
      final name = validateNickname(nickname);
      if (room.players.any(
        (p) => p.nickname.toLowerCase() == name.toLowerCase(),
      )) {
        throw StateError('That nickname is already in use.');
      }
      players[userId] = RacePlayer(
        id: userId,
        nickname: name,
        avatar: avatar,
        round: room.round,
      ).toJson();
    }
    raw['players'] = players;
    await _write(code, raw);
  }

  @override
  Stream<RaceRoom?> watch(String code, {bool ownOnly = false}) async* {
    String last = '';
    await for (final _ in Stream.periodic(const Duration(milliseconds: 400))) {
      final raw = await _read(code), encoded = jsonEncode(raw);
      if (encoded == last) continue;
      last = encoded;
      yield raw.isEmpty ? null : RaceRoom.fromJson(code, raw);
    }
  }

  @override
  Future<void> publish(String code, int round, RunState state) async {
    final raw = await _read(code), players = jsonMap(raw['players']);
    final meta = jsonMap(raw['metadata']);
    if (!players.containsKey(userId) ||
        meta['round'] != round ||
        !['playing', 'countdown'].contains(meta['phase'])) {
      return;
    }
    final player = jsonMap(players[userId]);
    player['run'] = state.toJson();
    player['connected'] = true;
    players[userId] = player;
    raw['players'] = players;
    await _write(code, raw);
  }

  @override
  Future<void> control(
    String code,
    String action, {
    int? level,
    String? playerId,
  }) async {
    final raw = await _read(code), room = RaceRoom.fromJson(code, raw);
    if (room.hostId != userId) {
      throw StateError('Only the host can control the room.');
    }
    if (action == 'delete') {
      await prefs.remove(_key(code));
      return;
    }
    if (action == 'remove') {
      final players = jsonMap(raw['players']);
      players.remove(playerId);
      raw['blocked'] = {...jsonMap(raw['blocked']), playerId!: true};
      raw['players'] = players;
    } else {
      final meta = jsonMap(raw['metadata']);
      meta.addAll(controlChanges(room, action, nowMs, level: level));
      raw['metadata'] = meta;
      if (action == 'next' || action == 'restart') {
        raw['players'] = {
          for (final p in room.players)
            p.id: RacePlayer(
              id: p.id,
              nickname: p.nickname,
              avatar: p.avatar,
              round: room.round + 1,
              connected: p.connected,
            ).toJson(),
        };
      }
    }
    await _write(code, raw);
  }

  @override
  Future<void> leave(String code) async {
    final raw = await _read(code), players = jsonMap(raw['players']);
    if (!players.containsKey(userId)) return;
    final p = jsonMap(players[userId]);
    p['connected'] = false;
    players[userId] = p;
    raw['players'] = players;
    await _write(code, raw);
  }

  @override
  Future<void> dispose() async {}
}
