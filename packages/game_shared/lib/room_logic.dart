import 'dart:math';
import 'race_state.dart';

/// Pure room state-machine helpers shared between the Flutter client's
/// [RoomService] implementations and the standalone game server: room code
/// generation, validation, and the phase transitions a host action causes.
/// No I/O, no Flutter -- safe to run on any Dart VM.

String roomCode() {
  const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random.secure();
  return List.generate(
    6,
    (_) => letters[random.nextInt(letters.length)],
  ).join();
}

String cleanCode(String code) => code.trim().toUpperCase();
String validateNickname(String value) {
  final name = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (name.length < 2 ||
      name.length > 20 ||
      RegExp(r'[.#$\[\]/\x00-\x1f]').hasMatch(name)) {
    throw StateError(
      'Use a nickname of 2–20 letters or numbers, without . # \$ / [ ].',
    );
  }
  return name;
}

Map<String, dynamic> newMetadata(String host, int level, int now) => {
  'hostId': host,
  'level': level,
  'round': 0,
  'phase': 'lobby',
  'locked': false,
  'startAt': 0,
  'pausedAt': 0,
  'pausedMs': 0,
  'expiresAt': now + 6 * 60 * 60 * 1000,
};

Map<String, dynamic> controlChanges(
  RaceRoom room,
  String action,
  int now, {
  int? level,
}) {
  switch (action) {
    case 'start':
      if (room.phase != RoomPhase.lobby || room.players.isEmpty) {
        throw StateError('Join at least one player before starting.');
      }
      return {
        'phase': 'countdown',
        'startAt': now,
        'locked': true,
        'pausedMs': 0,
      };
    case 'pause':
      if (room.phase != RoomPhase.playing &&
          room.phase != RoomPhase.countdown) {
        throw StateError('Race is not running.');
      }
      if (now < room.startAt + 3000) {
        throw StateError('Wait until GO before pausing.');
      }
      return {'phase': 'paused', 'pausedAt': now};
    case 'resume':
      if (room.phase != RoomPhase.paused) {
        throw StateError('Race is not paused.');
      }
      return {
        'phase': 'playing',
        'pausedMs': room.pausedMs + now - room.pausedAt,
        'pausedAt': 0,
      };
    case 'end':
      return {'phase': 'results', 'locked': true};
    case 'lock':
      return {'locked': !room.locked};
    case 'restart':
    case 'next':
      return {
        'phase': 'lobby',
        'level': level ?? room.level,
        'round': room.round + 1,
        'startAt': 0,
        'pausedAt': 0,
        'pausedMs': 0,
        'locked': false,
      };
    default:
      throw StateError('Unknown host action.');
  }
}
