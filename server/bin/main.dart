// Standalone WebSocket game server for Arabic Muamalat Adventure.
//
// Rooms are kept in memory only (no database): one small Dart isolate is
// plenty for a classroom-sized room, and it matches how Render's free/
// starter web services can restart at any time anyway. All room rules come
// from package:game_shared, so this server enforces exactly what the local
// browser-tab preview already enforces -- one engine, not a reimplementation.
//
// Wire protocol: one JSON object per WebSocket text frame.
//   Client -> server (request, includes "id" for correlation):
//     {"id":1,"op":"create","userId":"u1","level":2}
//     {"id":2,"op":"join","userId":"u1","code":"ABC234","nickname":"Ali","avatar":0}
//     {"id":3,"op":"watch","code":"ABC234"}
//     {"id":4,"op":"publish","userId":"u1","code":"ABC234","round":0,"state":{...}}
//     {"id":5,"op":"control","userId":"u1","code":"ABC234","action":"start"}
//     {"id":6,"op":"leave","userId":"u1","code":"ABC234"}
//   Server -> client (response, echoes "id"):
//     {"id":1,"ok":true,"code":"ABC234"}
//     {"id":2,"ok":false,"error":"Room not found. Check the code."}
//   Server -> client (push, no "id", sent to every connection watching that
//   room whenever it changes, and once immediately after "watch"):
//     {"op":"room","code":"ABC234","room":{...raw...}}   // or "room": null

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:game_shared/race_state.dart';
import 'package:game_shared/room_engine.dart';
import 'package:game_shared/room_logic.dart';

final Map<String, Map<String, dynamic>> _rooms = {};
final Map<String, Set<WebSocket>> _watchers = {};
final Map<WebSocket, _Conn> _conns = {};

class _Conn {
  final Set<String> watching = {};
  // code -> userId, for every room this connection has joined/published as,
  // so a disconnect marks the right players offline.
  final Map<String, String> identities = {};
}

int get _now => DateTime.now().millisecondsSinceEpoch;

void _broadcast(String code) {
  final raw = _rooms[code];
  final message = jsonEncode({'op': 'room', 'code': code, 'room': raw});
  for (final ws in _watchers[code] ?? const <WebSocket>{}) {
    ws.add(message);
  }
}

void _reply(WebSocket ws, dynamic id, Map<String, dynamic> fields) {
  ws.add(jsonEncode({'id': id, ...fields}));
}

void _handle(WebSocket ws, Map<String, dynamic> msg) {
  final id = msg['id'];
  final op = msg['op'] as String?;
  final conn = _conns[ws]!;
  try {
    switch (op) {
      case 'create':
        {
          final userId = msg['userId'] as String;
          final level = (msg['level'] as num).toInt();
          final code = roomCode();
          _rooms[code] = RoomEngine.create(userId, level, _now);
          _reply(ws, id, {'ok': true, 'code': code});
          return;
        }
      case 'join':
        {
          final userId = msg['userId'] as String;
          final code = cleanCode(msg['code'] as String);
          final raw = _rooms[code] ?? {};
          _rooms[code] = RoomEngine.join(
            raw,
            code,
            userId,
            msg['nickname'] as String,
            (msg['avatar'] as num).toInt(),
            _now,
          );
          conn.identities[code] = userId;
          _reply(ws, id, {'ok': true});
          _broadcast(code);
          return;
        }
      case 'watch':
        {
          final code = cleanCode(msg['code'] as String);
          conn.watching.add(code);
          (_watchers[code] ??= {}).add(ws);
          _reply(ws, id, {'ok': true});
          _reply(ws, null, {'op': 'room', 'code': code, 'room': _rooms[code]});
          return;
        }
      case 'unwatch':
        {
          final code = cleanCode(msg['code'] as String);
          conn.watching.remove(code);
          _watchers[code]?.remove(ws);
          _reply(ws, id, {'ok': true});
          return;
        }
      case 'publish':
        {
          final userId = msg['userId'] as String;
          final code = cleanCode(msg['code'] as String);
          final raw = _rooms[code];
          if (raw != null) {
            final next = RoomEngine.publish(
              raw,
              userId,
              (msg['round'] as num).toInt(),
              RunState.fromJson(msg['state']),
            );
            if (next != null) {
              _rooms[code] = next;
              conn.identities[code] = userId;
              _broadcast(code);
            }
          }
          _reply(ws, id, {'ok': true});
          return;
        }
      case 'control':
        {
          final userId = msg['userId'] as String;
          final code = cleanCode(msg['code'] as String);
          final raw = _rooms[code] ?? {};
          final next = RoomEngine.control(
            raw,
            code,
            userId,
            msg['action'] as String,
            _now,
            level: (msg['level'] as num?)?.toInt(),
            playerId: msg['playerId'] as String?,
          );
          if (next == null) {
            _rooms.remove(code);
          } else {
            _rooms[code] = next;
          }
          _reply(ws, id, {'ok': true});
          _broadcast(code);
          if (next == null) {
            for (final w in _watchers.remove(code) ?? const <WebSocket>{}) {
              _conns[w]?.watching.remove(code);
            }
          }
          return;
        }
      case 'leave':
        {
          final userId = msg['userId'] as String;
          final code = cleanCode(msg['code'] as String);
          final raw = _rooms[code];
          if (raw != null) {
            final next = RoomEngine.leave(raw, userId);
            if (next != null) {
              _rooms[code] = next;
              _broadcast(code);
            }
          }
          conn.identities.remove(code);
          _reply(ws, id, {'ok': true});
          return;
        }
      default:
        _reply(ws, id, {'ok': false, 'error': 'Unknown operation.'});
    }
  } on StateError catch (e) {
    _reply(ws, id, {'ok': false, 'error': e.message});
  } catch (e) {
    _reply(ws, id, {'ok': false, 'error': 'Server error: $e'});
  }
}

void _onDisconnect(WebSocket ws) {
  final conn = _conns.remove(ws);
  if (conn == null) return;
  for (final code in conn.watching) {
    _watchers[code]?.remove(ws);
  }
  for (final entry in conn.identities.entries) {
    final raw = _rooms[entry.key];
    if (raw == null) continue;
    final next = RoomEngine.leave(raw, entry.value);
    if (next != null) {
      _rooms[entry.key] = next;
      _broadcast(entry.key);
    }
  }
}

// Rooms mirror the six-hour expiry in their own metadata; sweep here so
// abandoned rooms do not sit in memory forever between deploys.
void _sweepExpired() {
  final now = _now;
  final expired = _rooms.entries
      .where((e) => (e.value['metadata']?['expiresAt'] as num? ?? 0) < now)
      .map((e) => e.key)
      .toList();
  for (final code in expired) {
    _rooms.remove(code);
    for (final w in _watchers.remove(code) ?? const <WebSocket>{}) {
      _conns[w]?.watching.remove(code);
      w.add(jsonEncode({'op': 'room', 'code': code, 'room': null}));
    }
  }
}

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  Timer.periodic(const Duration(minutes: 5), (_) => _sweepExpired());

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Adventure game server listening on :$port');

  await for (final request in server) {
    if (request.uri.path == '/healthz') {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('ok');
      await request.response.close();
      continue;
    }
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response
        ..statusCode = HttpStatus.upgradeRequired
        ..write('WebSocket endpoint. Connect with a WS client.');
      await request.response.close();
      continue;
    }
    final ws = await WebSocketTransformer.upgrade(request);
    _conns[ws] = _Conn();
    ws.listen(
      (data) {
        try {
          final msg = jsonDecode(data as String) as Map<String, dynamic>;
          _handle(ws, msg);
        } catch (e) {
          ws.add(jsonEncode({'ok': false, 'error': 'Bad message: $e'}));
        }
      },
      onDone: () => _onDisconnect(ws),
      onError: (_) => _onDisconnect(ws),
      cancelOnError: true,
    );
  }
}
