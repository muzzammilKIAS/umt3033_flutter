import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/race_state.dart';
import 'room_service.dart';

class FirebaseRoomService implements RoomService {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const configured = apiKey != '';
  final FirebaseDatabase db;
  @override
  final String userId;
  int _offset = 0;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  FirebaseRoomService(this.db, this.userId);
  static Future<FirebaseRoomService> open() async {
    final app = Firebase.apps.isEmpty
        ? await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: apiKey,
              appId: String.fromEnvironment('FIREBASE_APP_ID'),
              messagingSenderId: String.fromEnvironment(
                'FIREBASE_MESSAGING_SENDER_ID',
              ),
              projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
              authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
              databaseURL: String.fromEnvironment('FIREBASE_DATABASE_URL'),
            ),
          )
        : Firebase.app();
    final auth = FirebaseAuth.instanceFor(app: app);
    await auth.setPersistence(Persistence.SESSION);
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
    final db = FirebaseDatabase.instanceFor(app: app);
    final service = FirebaseRoomService(db, user.uid);
    service._subscriptions.add(
      db.ref('.info/serverTimeOffset').onValue.listen((e) {
        service._offset = (e.snapshot.value as num?)?.toInt() ?? 0;
      }),
    );
    return service;
  }

  @override
  String get label => 'LIVE CLASSROOM';
  @override
  bool get isDemo => false;
  @override
  int get nowMs => DateTime.now().millisecondsSinceEpoch + _offset;
  @override
  Stream<bool> get connection =>
      db.ref('.info/connected').onValue.map((e) => e.snapshot.value == true);
  DatabaseReference _room(String code) => db.ref('rooms/$code');
  @override
  Future<String> create(int level) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = roomCode();
      final result = await _room(code).runTransaction((raw) {
        if (raw != null) return Transaction.abort();
        return Transaction.success({
          'metadata': newMetadata(userId, level, nowMs),
        });
      }, applyLocally: false);
      if (result.committed) return code;
    }
    throw StateError('Could not reserve a room. Please try again.');
  }

  @override
  Future<void> join(String code, String nickname, int avatar) async {
    final snapshot = await _room(code).get();
    if (!snapshot.exists) throw StateError('Room not found. Check the code.');
    final room = RaceRoom.fromJson(code, snapshot.value);
    if (room.expiresAt < nowMs) throw StateError('This room has expired.');
    final existing = room.players.where((p) => p.id == userId);
    if (existing.isEmpty) {
      if (room.locked || room.phase != RoomPhase.lobby) {
        throw StateError('Room is locked or already racing.');
      }
      if (room.players.length >= 50) {
        throw StateError('Room is full (50 players).');
      }
      final name = validateNickname(nickname);
      final claim = _room(code).child('names/${name.toLowerCase()}');
      final reserved = await claim.runTransaction(
        (value) => value == null || value == userId
            ? Transaction.success(userId)
            : Transaction.abort(),
        applyLocally: false,
      );
      if (!reserved.committed) {
        throw StateError('That nickname is already in use.');
      }
      try {
        await _room(code)
            .child('players/$userId')
            .set(
              RacePlayer(
                id: userId,
                nickname: name,
                avatar: avatar,
                round: room.round,
              ).toJson(),
            );
      } catch (_) {
        await claim.remove();
        rethrow;
      }
    }
    final presence = _room(code).child('players/$userId/connected');
    _subscriptions.add(
      connection.listen((connected) async {
        if (!connected) return;
        try {
          await presence.onDisconnect().set(false);
          await presence.set(true);
        } catch (_) {
          /* kicked or room removed: watch stream handles it */
        }
      }),
    );
  }

  @override
  Stream<RaceRoom?> watch(String code, {bool ownOnly = false}) {
    if (!ownOnly) {
      return _room(code).onValue.map(
        (e) => e.snapshot.exists
            ? RaceRoom.fromJson(code, e.snapshot.value)
            : null,
      );
    }
    // Students subscribe to metadata + their own run during the race.
    // Full rosters are needed only in the lobby and results, keeping live
    // traffic proportional to class size rather than peers squared.
    late StreamController<RaceRoom?> controller;
    StreamSubscription<DatabaseEvent>? metadataSub, playersSub;
    Map<String, dynamic> metadata = {}, players = {};
    bool ready = false;
    bool? watchingSelf;
    void emit() {
      if (ready && metadata.isNotEmpty && !controller.isClosed) {
        controller.add(
          RaceRoom.fromJson(code, {'metadata': metadata, 'players': players}),
        );
      }
    }

    controller = StreamController<RaceRoom?>(
      onListen: () {
        metadataSub = _room(code).child('metadata').onValue.listen((event) {
          metadata = jsonMap(event.snapshot.value);
          if (metadata.isEmpty) {
            controller.add(null);
            return;
          }
          final self = [
            'countdown',
            'playing',
            'paused',
          ].contains(metadata['phase']);
          if (watchingSelf != self) {
            watchingSelf = self;
            ready = false;
            playersSub?.cancel();
            final ref = _room(code).child(self ? 'players/$userId' : 'players');
            playersSub = ref.onValue.listen((event) {
              players = self
                  ? (event.snapshot.exists
                        ? {userId: event.snapshot.value}
                        : {})
                  : jsonMap(event.snapshot.value);
              ready = true;
              emit();
            }, onError: controller.addError);
          } else {
            emit();
          }
        }, onError: controller.addError);
      },
      onCancel: () async {
        await metadataSub?.cancel();
        await playersSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> publish(String code, int round, RunState state) async {
    await _room(
      code,
    ).child('players/$userId').update({'run': state.toJson(), 'round': round});
  }

  @override
  Future<void> control(
    String code,
    String action, {
    int? level,
    String? playerId,
  }) async {
    final room = RaceRoom.fromJson(code, (await _room(code).get()).value);
    if (room.hostId != userId) {
      throw StateError('Only the host can control this room.');
    }
    if (action == 'delete') {
      await _room(code).remove();
      return;
    }
    if (action == 'remove') {
      final player = room.players.firstWhere((p) => p.id == playerId);
      await _room(code).update({
        'players/$playerId': null,
        'blocked/$playerId': true,
        'names/${player.nickname.toLowerCase()}': null,
      });
      return;
    }
    final changes = controlChanges(room, action, nowMs, level: level);
    if (action == 'start') changes['startAt'] = ServerValue.timestamp;
    final update = {
      for (final e in changes.entries) 'metadata/${e.key}': e.value,
    };
    if (action == 'next' || action == 'restart') {
      for (final player in room.players) {
        update['players/${player.id}'] = RacePlayer(
          id: player.id,
          nickname: player.nickname,
          avatar: player.avatar,
          connected: player.connected,
          round: room.round + 1,
        ).toJson();
      }
    }
    await _room(code).update(update);
  }

  @override
  Future<void> leave(String code) async {
    await _room(code).child('players/$userId/connected').set(false);
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }
}
