import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/data_service.dart';
import '../data/question_bank.dart';
import '../models/curriculum.dart';
import '../models/race_state.dart';
import '../multiplayer/room_service.dart';
import '../multiplayer/render_room_service.dart';
import '../multiplayer/local_room_service.dart';
import '../utils/browser.dart';
import '../widgets/adventure_style.dart';
import '../widgets/race_board.dart';
import 'home_screen.dart';
import 'play_screen.dart';
import 'results_screen.dart';

class RoomScreen extends StatefulWidget {
  final bool host;
  final String? code;
  const RoomScreen({super.key, this.host = false, this.code});
  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _code = TextEditingController(), _name = TextEditingController();
  RoomService? _service;
  RaceRoom? _room;
  StreamSubscription<RaceRoom?>? _roomSub;
  StreamSubscription<bool>? _connectionSub;
  Timer? _clock;
  int _level = 1, _avatar = 0;
  bool _busy = false, _connected = true, _subscribed = false;
  String? _error, _activeCode;
  final Map<int, List<KnowledgeQuestion>> _questions = {};
  String _event = 'The adventure begins with your class.';
  @override
  void initState() {
    super.initState();
    _code.text = widget.code ?? '';
    _initialize();
    _clock = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted && _room != null && _service!.nowMs < _room!.startAt + 4000) {
        setState(() {});
      }
    });
  }

  Future<void> _initialize() async {
    try {
      final service = RenderRoomService.configured
          ? await RenderRoomService.open()
          : await LocalRoomService.open();
      if (!mounted) {
        await service.dispose();
        return;
      }
      setState(() => _service = service);
      _connectionSub = service.connection.listen((connected) {
        if (mounted) setState(() => _connected = connected);
      });
      final savedCode = sessionRead(
        widget.host ? 'adventure_host_room' : 'adventure_player_room',
      );
      if (savedCode != null &&
          savedCode.isNotEmpty &&
          (widget.code == null || widget.code == savedCode)) {
        if (!widget.host) {
          await service.join(savedCode, 'Returning explorer', 0);
        }
        _watch(savedCode);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Unable to connect: $e');
    }
  }

  Future<void> _action(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _watch(String code) {
    _roomSub?.cancel();
    _activeCode = code;
    _subscribed = true;
    sessionWrite(
      widget.host ? 'adventure_host_room' : 'adventure_player_room',
      code,
    );
    _roomSub = _service!
        .watch(code, ownOnly: !widget.host)
        .listen(
          (room) {
            if (!mounted) return;
            if (room != null && _room != null) {
              for (final p in room.players) {
                final old = _room!.players
                    .where((v) => v.id == p.id)
                    .firstOrNull;
                if (p.run.finished && old?.run.finished != true) {
                  _event = '${p.nickname} unlocked the final vault!';
                  break;
                }
                if (old != null && p.run.correct > old.run.correct) {
                  _event = '${p.nickname} opened a knowledge gate!';
                  break;
                }
              }
            }
            if (widget.host &&
                room != null &&
                !_busy &&
                room.players.isNotEmpty &&
                (room.phase == RoomPhase.playing ||
                    room.phase == RoomPhase.countdown) &&
                room.players.every((p) => p.run.finished)) {
              unawaited(_control('end'));
            }
            setState(() {
              _room = room;
              if (room == null) {
                _error =
                    'Room closed or not found. Create or join another room.';
                sessionWrite(
                  widget.host ? 'adventure_host_room' : 'adventure_player_room',
                  '',
                );
                _subscribed = false;
              } else if (widget.host && room.hostId != _service!.userId) {
                _error = 'This browser is not the room host.';
                _room = null;
                _subscribed = false;
              } else if (!widget.host &&
                  !room.players.any((p) => p.id == _service!.userId)) {
                sessionWrite('adventure_player_room', '');
                _error = 'You have been removed from this room.';
                _room = null;
                _subscribed = false;
              }
            });
          },
          onError: (Object e) {
            if (mounted) setState(() => _error = 'Room connection failed: $e');
          },
        );
    setState(() {});
  }

  Future<void> _control(String action, {int? level, String? playerId}) =>
      _action(
        () => _service!.control(
          _activeCode!,
          action,
          level: level,
          playerId: playerId,
        ),
      );
  @override
  void dispose() {
    _clock?.cancel();
    _roomSub?.cancel();
    _connectionSub?.cancel();
    if (_activeCode != null && !widget.host) {
      unawaited(_service?.leave(_activeCode!).catchError((_) {}));
    }
    _service?.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GameFrame(
    title: widget.host ? 'CLASSROOM / PROJECTOR' : 'JOIN THE ADVENTURE',
    actions: widget.host
        ? [
            IconButton(
              tooltip: 'Fullscreen projector',
              onPressed: () => _action(projectorFullscreen),
              icon: const Icon(Icons.fullscreen),
            ),
          ]
        : null,
    child: Column(
      children: [
        if (_service != null)
          Container(
            width: double.infinity,
            color: _service!.isDemo ? gold : emerald,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              _service!.isDemo
                  ? 'LOCAL PREVIEW • Open the join link in another tab. Phones require Firebase setup.'
                  : 'LIVE CLASSROOM • ${_connected ? 'Connected' : 'Reconnecting…'}',
              style: TextStyle(
                color: _service!.isDemo ? navy : cream,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (_error != null)
          MaterialBanner(
            content: Text(_error!),
            actions: [
              TextButton(
                onPressed: () => setState(() => _error = null),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        Expanded(
          child: _service == null
              ? Center(
                  child: _error == null
                      ? const CircularProgressIndicator()
                      : FilledButton(
                          onPressed: _initialize,
                          child: const Text('Retry connection'),
                        ),
                )
              : _room == null
              ? _setup()
              : widget.host
              ? _host()
              : _player(),
        ),
      ],
    ),
  );
  Widget _setup() => _subscribed
      ? const Center(child: CircularProgressIndicator())
      : Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  widget.host
                      ? 'An adventure, together.'
                      : 'Your class is waiting.',
                  style: const TextStyle(
                    fontSize: 32,
                    color: navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.host) ...[
                  const Text('SELECT WORLD'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _level,
                    items: adventureLevels
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text('${l.id}. ${l.title}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _level = v!),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _action(() async {
                            final code = await _service!.create(_level);
                            _watch(code);
                          }),
                    child: const Text('Create class game →'),
                  ),
                ] else ...[
                  TextField(
                    controller: _code,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Room code'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _name,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'Your nickname',
                    ),
                  ),
                  const SizedBox(height: 16),
                  AvatarPicker(
                    value: _avatar,
                    onChanged: (v) => setState(() => _avatar = v),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _action(() async {
                            final code = cleanCode(_code.text);
                            if (!RegExp(r'^[A-Z2-9]{6}$').hasMatch(code)) {
                              throw StateError(
                                'Enter the six-character room code.',
                              );
                            }
                            await _service!.join(code, _name.text, _avatar);
                            _watch(code);
                          }),
                    child: const Text('Join adventure →'),
                  ),
                ],
              ],
            ),
          ),
        );
  Widget _host() {
    final room = _room!;
    if (room.phase == RoomPhase.results || room.phase == RoomPhase.finished) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ResultsView(players: room.players, classroom: true),
          const SizedBox(height: 20),
          _controls(),
        ],
      );
    }
    if (room.phase == RoomPhase.lobby) {
      final url = joinUrl(Uri.base, room.code);
      return LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 850;
          // The QR has to be scannable from the back of a classroom, so it
          // takes as much of the projector height as the panel allows.
          final qrSize = wide
              ? (constraints.maxHeight * .46).clamp(240.0, 420.0)
              : 220.0;
          final qr = Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: navy.withValues(alpha: .18),
                  blurRadius: 34,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SCAN TO JOIN',
                  style: TextStyle(
                    color: emerald,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  label: 'Room join QR code',
                  child: QrImageView(
                    data: url,
                    size: qrSize,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  child: Text(
                    room.code,
                    style: TextStyle(
                      fontSize: wide ? 60 : 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                      color: navy,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Clipboard.setData(ClipboardData(text: url)),
                  icon: const Icon(Icons.link),
                  label: const Text('Copy join link'),
                ),
              ],
            ),
          );
          final roster = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WORLD ${room.level} • ${adventureLevels[room.level - 1].title}',
                style: const TextStyle(
                  color: gold,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'ARABIC MUAMALAT\nADVENTURE',
                style: TextStyle(
                  fontSize: wide ? 46 : 30,
                  height: 1.1,
                  letterSpacing: -1,
                  fontWeight: FontWeight.w800,
                  color: cream,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Icon(Icons.groups_rounded, color: gold, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Players joined: ${room.players.length} / 50',
                    style: TextStyle(
                      fontSize: wide ? 28 : 20,
                      fontWeight: FontWeight.w800,
                      color: cream,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (room.players.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 26,
                  ),
                  decoration: BoxDecoration(
                    color: cream.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cream.withValues(alpha: .14)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_iphone_rounded,
                        color: sky,
                        size: 30,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Waiting for explorers.\nScan the code, pick a nickname and you appear here.',
                          style: TextStyle(
                            color: sky.withValues(alpha: .92),
                            height: 1.7,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: room.players
                      .map(
                        (p) => Container(
                          padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
                          decoration: BoxDecoration(
                            color: cream.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: cream.withValues(alpha: .2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AvatarBadge(p.avatar, size: 32),
                              const SizedBox(width: 10),
                              Text(
                                p.nickname,
                                style: TextStyle(
                                  color: cream,
                                  fontWeight: FontWeight.w700,
                                  fontSize: wide ? 17 : 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                tooltip: 'Remove ${p.nickname}',
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                padding: EdgeInsets.zero,
                                iconSize: 17,
                                color: sky.withValues(alpha: .8),
                                onPressed: _busy
                                    ? null
                                    : () => _control('remove', playerId: p.id),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 26),
              _controls(dark: true),
            ],
          );
          return Container(
            color: navy,
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        qr,
                        const SizedBox(width: 44),
                        Expanded(child: roster),
                      ],
                    )
                  : Column(children: [qr, const SizedBox(height: 24), roster]),
            ),
          );
        },
      );
    }
    final seconds = ((room.startAt + 3000 - _service!.nowMs) / 1000).ceil();
    return Container(
      color: navy,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'LIVE CLASS RACE',
                  style: TextStyle(
                    color: cream,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                room.phase == RoomPhase.paused
                    ? 'PAUSED'
                    : seconds > 0
                    ? '$seconds'
                    : '${room.players.length} EXPLORERS',
                style: const TextStyle(
                  color: gold,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_event, style: const TextStyle(color: sky, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: adventureLevels[room.level - 1].zones
                .map(
                  (zone) => Expanded(
                    child: Text(
                      zone,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: gold, fontSize: 11),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Expanded(child: RaceBoard(room: room)),
          const SizedBox(height: 12),
          _controls(dark: true),
        ],
      ),
    );
  }

  Widget _controls({bool dark = false}) {
    final room = _room!;
    final enabled = !_busy && _connected;
    // The one action the lecturer needs is unmistakable; the rest stay quiet.
    Widget primary(String label, String action, {int? level}) => FilledButton(
      onPressed: enabled ? () => _control(action, level: level) : null,
      style: FilledButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: navy,
        disabledBackgroundColor: (dark ? cream : navy).withValues(alpha: .16),
        disabledForegroundColor: (dark ? cream : navy).withValues(alpha: .4),
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 22),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: 1.2,
        ),
      ),
      child: Text(label),
    );
    Widget button(String label, String action, {int? level}) => OutlinedButton(
      onPressed: enabled ? () => _control(action, level: level) : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: dark ? cream : navy,
        disabledForegroundColor: (dark ? cream : navy).withValues(alpha: .35),
        side: BorderSide(color: (dark ? cream : navy).withValues(alpha: .3)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    );
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (room.phase == RoomPhase.lobby) primary('START RACE', 'start'),
        if (room.phase == RoomPhase.playing ||
            room.phase == RoomPhase.countdown)
          button('Pause', 'pause'),
        if (room.phase == RoomPhase.paused) button('Resume', 'resume'),
        if (room.phase == RoomPhase.lobby)
          button(room.locked ? 'Unlock room' : 'Lock room', 'lock'),
        if (room.phase != RoomPhase.lobby && room.phase != RoomPhase.results)
          button('End & results', 'end'),
        if (room.phase == RoomPhase.results) ...[
          button('Restart world', 'restart'),
          primary('Next world →', 'next', level: room.level % 5 + 1),
          button('Close room', 'delete'),
        ],
        if (room.phase != RoomPhase.lobby && room.players.isNotEmpty)
          PopupMenuButton<String>(
            tooltip: 'Remove player',
            icon: Icon(
              Icons.person_remove_outlined,
              color: dark ? cream : navy,
            ),
            onSelected: (id) => _control('remove', playerId: id),
            itemBuilder: (_) => room.players
                .map((p) => PopupMenuItem(value: p.id, child: Text(p.nickname)))
                .toList(),
          ),
      ],
    );
  }

  Widget _player() {
    final room = _room!;
    final player = room.players
        .where((p) => p.id == _service!.userId)
        .firstOrNull;
    if (player == null) {
      return const Center(child: Text('You are no longer in this room.'));
    }
    if (room.phase == RoomPhase.lobby) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarBadge(player.avatar, size: 110),
              const SizedBox(height: 20),
              Text(
                'You’re in, ${player.nickname}.',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
              const SizedBox(height: 12),
              Text('Room ${room.code} • ${room.players.length} explorers'),
              const SizedBox(height: 16),
              const Text(
                'Waiting for your lecturer to start.\nHold left / right to move. Tap jump to cross gaps.\nRead each knowledge gate — every answer matters.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.8),
              ),
            ],
          ),
        ),
      );
    }
    if (room.phase == RoomPhase.results || room.phase == RoomPhase.finished) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ResultsView(players: room.players, classroom: true),
            const SizedBox(height: 20),
            const Text('Stay here for the next world.'),
          ],
        ),
      );
    }
    final remaining = ((room.startAt + 3000 - _service!.nowMs) / 1000).ceil();
    final go = _service!.nowMs - room.startAt - 3000;
    final cover = !_connected
        ? 'Reconnecting…'
        : room.phase == RoomPhase.paused
        ? 'Class race paused'
        : remaining > 0
        ? '$remaining'
        : go < 650
        ? 'GO!'
        : null;
    return PlayScreen(
      key: ValueKey('${room.code}:${room.round}'),
      level: room.level,
      questions: _questions.putIfAbsent(
        room.level,
        () => QuestionBank(context.read<DataService>()).forLevel(room.level),
      ),
      avatar: player.avatar,
      restored: player.run,
      multiplayer: true,
      paused: cover != null && cover != 'GO!',
      cover: cover,
      onPublish: (run) => _service!.publish(room.code, room.round, run),
    );
  }
}
