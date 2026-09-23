import 'dart:async';
import '../models/race_state.dart';
// roomCode, cleanCode, validateNickname, newMetadata and controlChanges now
// live in game_shared so the standalone game server enforces the exact same
// room rules instead of a duplicated copy.
export 'package:game_shared/room_logic.dart';

abstract class RoomService {
  String get userId;
  String get label;
  bool get isDemo;
  Stream<bool> get connection;
  int get nowMs;
  Future<String> create(int level);
  Future<void> join(String code, String nickname, int avatar);
  Stream<RaceRoom?> watch(String code, {bool ownOnly = false});
  Future<void> publish(String code, int round, RunState state);
  Future<void> control(
    String code,
    String action, {
    int? level,
    String? playerId,
  });
  Future<void> leave(String code);
  Future<void> dispose();
}
