import 'dart:async';
import 'dart:convert';
import 'package:game_shared/room_engine.dart';
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
    await _write(code, RoomEngine.create(userId, level, nowMs));
    return code;
  }

  @override
  Future<void> join(String code, String nickname, int avatar) async {
    final raw = await _read(code);
    await _write(
      code,
      RoomEngine.join(raw, code, userId, nickname, avatar, nowMs),
    );
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
    final raw = await _read(code);
    final next = RoomEngine.publish(raw, userId, round, state);
    if (next != null) await _write(code, next);
  }

  @override
  Future<void> control(
    String code,
    String action, {
    int? level,
    String? playerId,
  }) async {
    final raw = await _read(code);
    final next = RoomEngine.control(
      raw,
      code,
      userId,
      action,
      nowMs,
      level: level,
      playerId: playerId,
    );
    if (next == null) {
      await prefs.remove(_key(code));
    } else {
      await _write(code, next);
    }
  }

  @override
  Future<void> leave(String code) async {
    final raw = await _read(code);
    final next = RoomEngine.leave(raw, userId);
    if (next != null) await _write(code, next);
  }

  @override
  Future<void> dispose() async {}
}
