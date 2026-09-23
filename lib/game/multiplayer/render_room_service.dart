import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/race_state.dart';
import '../utils/browser.dart';
import 'room_service.dart';

/// Talks to the standalone Dart game server (server/bin/main.dart) over a
/// single WebSocket, instead of Firebase. The wire protocol is documented
/// at the top of that file. Requests are correlated by an incrementing
/// "id"; the server also pushes unsolicited {"op":"room",...} messages to
/// every connection that asked to "watch" a room code.
class RenderRoomService implements RoomService {
  /// Set at build time with --dart-define=GAME_SERVER_WS_URL=wss://host/ws
  static const wsUrl = String.fromEnvironment('GAME_SERVER_WS_URL');
  static const configured = wsUrl != '';

  final WebSocketChannel _channel;
  @override
  final String userId;
  int _nextId = 1;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final Map<String, StreamController<RaceRoom?>> _roomControllers = {};
  final _connectionController = StreamController<bool>.broadcast();
  StreamSubscription<dynamic>? _sub;

  RenderRoomService(this._channel, this.userId) {
    _connectionController.add(true);
    _sub = _channel.stream.listen(
      _onMessage,
      onDone: () => _connectionController.add(false),
      onError: (_) => _connectionController.add(false),
    );
  }

  static Future<RenderRoomService> open() async {
    final id = sessionRead('adventure_render_id') ?? 'user_${roomCode()}';
    sessionWrite('adventure_render_id', id);
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    await channel.ready;
    return RenderRoomService(channel, id);
  }

  void _onMessage(dynamic data) {
    final msg = jsonDecode(data as String) as Map<String, dynamic>;
    if (msg['op'] == 'room') {
      final code = msg['code'] as String;
      final room = msg['room'];
      _roomControllers[code]?.add(
        room == null ? null : RaceRoom.fromJson(code, room),
      );
      return;
    }
    final id = msg['id'];
    final completer = id is int ? _pending.remove(id) : null;
    completer?.complete(msg);
  }

  Future<Map<String, dynamic>> _send(Map<String, dynamic> fields) {
    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _channel.sink.add(jsonEncode({'id': id, ...fields}));
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pending.remove(id);
        throw StateError('No response from the game server.');
      },
    );
  }

  Future<Map<String, dynamic>> _sendOk(Map<String, dynamic> fields) async {
    final reply = await _send(fields);
    if (reply['ok'] != true) {
      throw StateError(reply['error'] as String? ?? 'Request failed.');
    }
    return reply;
  }

  @override
  String get label => 'LIVE CLASSROOM';
  @override
  bool get isDemo => false;
  @override
  int get nowMs => DateTime.now().millisecondsSinceEpoch;
  @override
  Stream<bool> get connection => _connectionController.stream;

  @override
  Future<String> create(int level) async {
    final reply = await _sendOk({'op': 'create', 'userId': userId, 'level': level});
    return reply['code'] as String;
  }

  @override
  Future<void> join(String code, String nickname, int avatar) => _sendOk({
    'op': 'join',
    'userId': userId,
    'code': code,
    'nickname': nickname,
    'avatar': avatar,
  });

  @override
  Stream<RaceRoom?> watch(String code, {bool ownOnly = false}) {
    final controller = _roomControllers.putIfAbsent(
      code,
      () => StreamController<RaceRoom?>.broadcast(),
    );
    _sendOk({'op': 'watch', 'code': code});
    return controller.stream;
  }

  @override
  Future<void> publish(String code, int round, RunState state) => _sendOk({
    'op': 'publish',
    'userId': userId,
    'code': code,
    'round': round,
    'state': state.toJson(),
  });

  @override
  Future<void> control(
    String code,
    String action, {
    int? level,
    String? playerId,
  }) => _sendOk({
    'op': 'control',
    'userId': userId,
    'code': code,
    'action': action,
    'level': ?level,
    'playerId': ?playerId,
  });

  @override
  Future<void> leave(String code) =>
      _sendOk({'op': 'leave', 'userId': userId, 'code': code});

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    for (final c in _roomControllers.values) {
      await c.close();
    }
    await _connectionController.close();
    await _channel.sink.close();
  }
}
