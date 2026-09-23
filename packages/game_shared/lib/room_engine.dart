import 'race_state.dart';
import 'room_logic.dart';

/// Pure room state transitions against the same raw JSON shape used
/// throughout the app (`{metadata, players, blocked}`), so the client's
/// LocalRoomService (browser-tab preview) and the standalone game server
/// enforce identical rules -- one engine, not two copies to keep in sync.
///
/// Every function takes the current raw room map and returns the next one,
/// or throws a [StateError] with a message safe to show the player. None of
/// this does I/O; the caller (server or LocalRoomService) owns storage and
/// broadcasting.
class RoomEngine {
  static Map<String, dynamic> create(String hostId, int level, int now) => {
    'metadata': newMetadata(hostId, level, now),
    'players': {},
  };

  static Map<String, dynamic> join(
    Map<String, dynamic> raw,
    String code,
    String userId,
    String nickname,
    int avatar,
    int now,
  ) {
    if (raw.isEmpty) throw StateError('Room not found. Check the code.');
    final room = RaceRoom.fromJson(code, raw);
    if (room.expiresAt < now) throw StateError('This room has expired.');
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
    return {...raw, 'players': players};
  }

  static Map<String, dynamic>? publish(
    Map<String, dynamic> raw,
    String userId,
    int round,
    RunState state,
  ) {
    final players = jsonMap(raw['players']);
    final meta = jsonMap(raw['metadata']);
    if (!players.containsKey(userId) ||
        meta['round'] != round ||
        !['playing', 'countdown'].contains(meta['phase'])) {
      return null;
    }
    final player = jsonMap(players[userId]);
    player['run'] = state.toJson();
    player['connected'] = true;
    players[userId] = player;
    return {...raw, 'players': players};
  }

  /// Returns null when the action deletes the room.
  static Map<String, dynamic>? control(
    Map<String, dynamic> raw,
    String code,
    String userId,
    String action,
    int now, {
    int? level,
    String? playerId,
  }) {
    final room = RaceRoom.fromJson(code, raw);
    if (room.hostId != userId) {
      throw StateError('Only the host can control the room.');
    }
    if (action == 'delete') return null;
    var next = Map<String, dynamic>.from(raw);
    if (action == 'remove') {
      final players = jsonMap(next['players'])..remove(playerId);
      next['blocked'] = {...jsonMap(next['blocked']), playerId!: true};
      next['players'] = players;
    } else {
      final meta = jsonMap(next['metadata'])
        ..addAll(controlChanges(room, action, now, level: level));
      next['metadata'] = meta;
      if (action == 'next' || action == 'restart') {
        next['players'] = {
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
    return next;
  }

  static Map<String, dynamic>? leave(Map<String, dynamic> raw, String userId) {
    final players = jsonMap(raw['players']);
    if (!players.containsKey(userId)) return null;
    final p = jsonMap(players[userId]);
    p['connected'] = false;
    players[userId] = p;
    return {...raw, 'players': players};
  }
}
