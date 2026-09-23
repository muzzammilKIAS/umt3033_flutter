import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../engine/avatar_art.dart';
import '../models/race_state.dart';
import 'adventure_style.dart';

class RaceBoard extends StatefulWidget {
  final RaceRoom room;
  const RaceBoard({super.key, required this.room});

  @override
  State<RaceBoard> createState() => _RaceBoardState();
}

class _RaceBoardState extends State<RaceBoard> with SingleTickerProviderStateMixin {
  // One shared clock drives every lane's run-cycle animation, instead of a
  // ticker per player -- so 50 avatars on a projector stay cheap to repaint.
  late final Ticker _ticker;
  double _worldTime = 0;
  double _lastPaint = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _worldTime = elapsed.inMicroseconds / 1e6;
      // ~30fps is plenty for a leg-scissor run cycle and keeps a full
      // classroom of lanes light to repaint.
      if (_worldTime - _lastPaint >= 1 / 30) {
        _lastPaint = _worldTime;
        setState(() {});
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  RaceRoom get room => widget.room;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final players = room.ranked;
      final compact = players.length > 20;
      final columns = constraints.maxWidth < 700
          ? 1
          : compact
          ? (constraints.maxWidth >= 1000 ? 4 : 3)
          : players.length > 10
          ? 2
          : 1;
      final gap = compact ? 6.0 : 8.0;
      final rows = (players.length / columns).ceil().clamp(1, 50);
      final height = ((constraints.maxHeight - gap * (rows - 1)) / rows).clamp(
        compact ? 28.0 : 38.0,
        compact ? 54.0 : 90.0,
      );
      // All players rendered, never top-N only. Small screens can scroll; the
      // projector uses compact columns to keep a 50-person class in view.
      // Top aligned so the lanes stay under the zone labels above the board.
      return Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: gap,
            children: players
                .asMap()
                .entries
                .map(
                  (e) => SizedBox(
                    key: ValueKey(e.value.id),
                    width:
                        (constraints.maxWidth - 12 * (columns - 1)) / columns,
                    height: height,
                    child: _RaceLane(
                      player: e.value,
                      rank: e.key + 1,
                      compact: compact,
                      worldTime: _worldTime,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
    },
  );
}

const _podium = [Color(0xFFF0C56B), Color(0xFFCBD5DA), Color(0xFFD69B6A)];

class _RaceLane extends StatelessWidget {
  final RacePlayer player;
  final int rank;
  final bool compact;
  final double worldTime;
  const _RaceLane({
    required this.player,
    required this.rank,
    required this.worldTime,
    required this.compact,
  });
  @override
  Widget build(BuildContext context) {
    final medal = rank <= 3 ? _podium[rank - 1] : null;
    final done = player.run.finished;
    final badge = compact ? 18.0 : 26.0;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: rank <= 3
              ? [const Color(0xFF235063), const Color(0xFF1A3F51)]
              : [const Color(0xFF1A3D4D), const Color(0xFF163645)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? gold.withValues(alpha: .75)
              : (medal ?? cream).withValues(alpha: medal != null ? .35 : .08),
          width: done ? 1.6 : 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 84 : 140,
            child: Row(
              children: [
                Container(
                  width: badge,
                  height: badge,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: medal ?? cream.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: medal != null ? navy : cream,
                      fontSize: compact ? 10 : 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 5 : 9),
                Expanded(
                  child: Text(
                    player.nickname,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: player.connected
                          ? cream
                          : cream.withValues(alpha: .4),
                      fontSize: compact ? 10 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(
                begin: 0,
                end: player.run.progress.clamp(0, 1),
              ),
              builder: (context, value, _) => LayoutBuilder(
                builder: (context, c) {
                  final marker = compact ? 26.0 : 36.0;
                  final travel = (c.maxWidth - marker).clamp(0.0, c.maxWidth);
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: compact ? 7 : 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF12303E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Ground already covered, in the world's own colours.
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: compact ? 7 : 10,
                          width: marker / 2 + travel * value,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [emerald, gold],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      // Zone boundaries.
                      ...[.333, .667].map(
                        (p) => Align(
                          alignment: Alignment(-1 + p * 2, 0),
                          child: Container(
                            width: 2,
                            height: compact ? 13 : 18,
                            decoration: BoxDecoration(
                              color: cream.withValues(alpha: .3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.flag_rounded,
                          size: compact ? 13 : 18,
                          color: done ? gold : cream.withValues(alpha: .45),
                        ),
                      ),
                      Positioned(
                        left: travel * value,
                        child: LiveAvatarMarker(
                          avatar: player.avatar,
                          size: marker,
                          worldTime: worldTime,
                          running: player.connected && !done,
                          checkpoint: player.run.checkpoint,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SizedBox(width: compact ? 6 : 12),
          SizedBox(
            width: compact ? 48 : 92,
            // A short lane keeps the score only; the gate count needs room.
            child: LayoutBuilder(
              builder: (context, c) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    done
                        ? '✓ ${player.run.score}'
                        : '${(player.run.progress * 100).round()}%',
                    style: TextStyle(
                      color: gold,
                      fontSize: compact ? 11 : 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!compact && c.maxHeight >= 48)
                    Text(
                      '${player.run.correct} gates',
                      style: TextStyle(
                        color: sky.withValues(alpha: .75),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The marker riding each lane: a continuously running figure (driven by the
/// board's shared clock, same run-cycle as real gameplay) that hops each
/// time the player's synced checkpoint advances -- i.e. every time they
/// actually clear a question gate live, not a simulated bounce.
class LiveAvatarMarker extends StatefulWidget {
  final int avatar;
  final double size;
  final double worldTime;
  final bool running;
  final int checkpoint;
  const LiveAvatarMarker({
    super.key,
    required this.avatar,
    required this.size,
    required this.worldTime,
    required this.running,
    required this.checkpoint,
  });

  @override
  State<LiveAvatarMarker> createState() => _LiveAvatarState();
}

class _LiveAvatarState extends State<LiveAvatarMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(LiveAvatarMarker old) {
    super.didUpdateWidget(old);
    if (widget.checkpoint > old.checkpoint) {
      _hop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hop,
      builder: (context, child) {
        final lift = sin(_hop.value * pi) * widget.size * .45;
        return Transform.translate(
          offset: Offset(0, -lift),
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: sky.withValues(alpha: .6),
          borderRadius: BorderRadius.circular(widget.size / 3),
        ),
        child: CustomPaint(
          painter: _LiveAvatarPainter(
            avatar: widget.avatar,
            stride: widget.worldTime,
            running: widget.running,
          ),
        ),
      ),
    );
  }
}

class _LiveAvatarPainter extends CustomPainter {
  final int avatar;
  final double stride;
  final bool running;
  _LiveAvatarPainter({
    required this.avatar,
    required this.stride,
    required this.running,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height * .86);
    canvas.scale(size.height / 70);
    drawAvatar(canvas, avatar, stride, running);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LiveAvatarPainter oldDelegate) =>
      avatar != oldDelegate.avatar ||
      stride != oldDelegate.stride ||
      running != oldDelegate.running;
}
