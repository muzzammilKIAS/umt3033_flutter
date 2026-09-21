import 'dart:math';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import '../models/race_state.dart';
import 'avatar_art.dart';
import 'course_geometry.dart';
import 'environment_art.dart';
import 'prop_art.dart';

class AdventureGame extends FlameGame with KeyboardEvents {
  final RunState run;
  final int avatar, level;
  final CourseGeometry course;
  final void Function(int index) onGate;
  final void Function() onChanged, onFinish;
  double x = 60,
      y = CourseGeometry.floor,
      vy = 0,
      _accumulator = 0,
      _elapsed = 0;
  double worldTime = 0, boost = 0;
  bool left = false,
      right = false,
      grounded = true,
      blocked = false,
      frozen = false;
  bool _jumpHeld = false;
  final Set<int> _collected = {};
  AdventureGame({
    required this.run,
    required int gates,
    required this.avatar,
    required this.level,
    required this.onGate,
    required this.onChanged,
    required this.onFinish,
  }) : course = CourseGeometry(gates) {
    x = course.respawnX(run.checkpoint);
    // Do not award a second set of gems after a refreshed checkpoint.
    for (var i = 0; i < run.checkpoint * 2; i++) {
      _collected.add(i);
    }
  }
  void clearInput() {
    left = false;
    right = false;
    _jumpHeld = false;
  }

  void jump() {
    if (grounded && !blocked && !frozen) {
      vy = -640;
      grounded = false;
    }
  }

  void releaseGate(bool correct) {
    blocked = false;
    if (correct) boost = 3;
  }

  @override
  Color backgroundColor() => const Color(0xFFC6E5EA);
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    left =
        keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    right =
        keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);
    final jumping = keysPressed.contains(LogicalKeyboardKey.space);
    if (jumping && !_jumpHeld) jump();
    _jumpHeld = jumping;
    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (frozen || run.finished) return;
    // Bounded fixed-step collision simulation is stable across device frame rates.
    _accumulator += min(dt, .1);
    while (_accumulator >= 1 / 120) {
      _step(1 / 120);
      _accumulator -= 1 / 120;
    }
  }

  void _step(double dt) {
    worldTime += dt;
    _elapsed += dt * 1000;
    if (_elapsed >= 1) {
      final ms = _elapsed.floor();
      run.elapsedMs += ms;
      _elapsed -= ms;
    }
    if (blocked) return;
    if (boost > 0) boost -= dt;
    final velocity = (right ? 1 : 0) - (left ? 1 : 0);
    x = (x + velocity * (boost > 0 ? 340 : 255) * dt).clamp(
      course.respawnX(run.checkpoint) - 30,
      course.length,
    );
    final previousY = y;
    vy += 1700 * dt;
    y += vy * dt;
    grounded = false;
    final segment = (x / CourseGeometry.segment).floor();
    for (
      var index = max(0, segment - 1);
      index <= min(course.gates, segment + 1);
      index++
    ) {
      final platforms = index == course.gates
          ? [
              Rect.fromLTWH(
                index * CourseGeometry.segment,
                CourseGeometry.floor,
                500,
                100,
              ),
            ]
          : course.platforms(index, worldTime);
      for (final platform in platforms) {
        if (vy >= 0 &&
            previousY <= platform.top + 1 &&
            y >= platform.top &&
            x + 11 > platform.left &&
            x - 11 < platform.right) {
          y = platform.top;
          vy = 0;
          grounded = true;
        }
      }
      if (index < course.gates) {
        final barrierX = index * CourseGeometry.segment + 880;
        final barrierY = CourseGeometry.floor - 24 - 12 * sin(worldTime * 2);
        if ((x - barrierX).abs() < 27 &&
            y > barrierY - 8 &&
            y - 56 < barrierY + 24) {
          _respawn();
        }
        for (var gem = 0; gem < 2; gem++) {
          final id = index * 2 + gem;
          final gx = index * CourseGeometry.segment + (gem == 0 ? 360 : 550);
          final gy = CourseGeometry.floor - (gem == 0 ? 120 : 160);
          if (!_collected.contains(id) &&
              (x - gx).abs() < 32 &&
              (y - 30 - gy).abs() < 46) {
            _collected.add(id);
            // Capped to two gems per completed/current segment on recovery.
            if (run.gems < (run.checkpoint + 1) * 2) run.collect();
            onChanged();
          }
        }
      }
    }
    if (y > 650) _respawn();
    if (run.checkpoint < course.gates &&
        x >= course.gateX(run.checkpoint) - 45) {
      x = course.gateX(run.checkpoint) - 45;
      blocked = true;
      clearInput();
      onGate(run.checkpoint);
    }
    run.progress = min(.999, x / course.length);
    if (run.checkpoint == course.gates && x >= course.length - 80) {
      run.finish();
      clearInput();
      onFinish();
    }
  }

  void _respawn() {
    x = course.respawnX(run.checkpoint);
    y = CourseGeometry.floor;
    vy = 0;
    run.elapsedMs += 2000;
    boost = 1;
    onChanged();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final scale = size.y / 540;
    if (scale <= 0) return;
    final width = size.x / scale;
    final cameraX = (x - width * .32)
        .clamp(0.0, max(0.0, course.length - width))
        .toDouble();
    canvas.save();
    canvas.scale(scale);
    final zone = level == 5
        ? (run.checkpoint < 3
              ? 0
              : run.checkpoint < 6
              ? 1
              : 2)
        : (run.checkpoint ~/ 3).clamp(0, 2);
    drawEnvironment(canvas, width, cameraX, worldTime, level, zone);
    canvas.save();
    canvas.translate(-cameraX, 0);
    final first = max(0, (cameraX / CourseGeometry.segment).floor());
    final last = min(
      course.gates,
      ((cameraX + width) / CourseGeometry.segment).ceil(),
    );
    final p = Paint();
    final pal = propsFor(level);
    for (var i = first; i <= last; i++) {
      final platforms = i == course.gates
          ? [
              Rect.fromLTWH(
                i * CourseGeometry.segment,
                CourseGeometry.floor,
                500,
                100,
              ),
            ]
          : course.platforms(i, worldTime);
      for (final r in platforms) {
        if (r.height > 30) {
          drawGround(canvas, r, pal);
        } else {
          drawLedge(canvas, r, pal);
        }
      }
      if (i == course.gates) {
        drawFinish(canvas, course.length - 110, worldTime);
        continue;
      }
      final base = i * CourseGeometry.segment;
      drawHazard(
        canvas,
        base + 880,
        CourseGeometry.floor - 24 - 12 * sin(worldTime * 2),
        worldTime,
      );
      for (var gem = 0; gem < 2; gem++) {
        if (_collected.contains(i * 2 + gem)) continue;
        drawGem(
          canvas,
          base + (gem == 0 ? 360 : 550),
          CourseGeometry.floor -
              (gem == 0 ? 120 : 160) +
              sin(worldTime * 3 + gem) * 4,
          worldTime,
          gem,
        );
      }
      drawGate(canvas, course.gateX(i), worldTime, i < run.checkpoint);
    }
    canvas.save();
    canvas.translate(x, y);
    if (boost > 0) {
      // A speed trail after a correct answer.
      p.shader = Gradient.radial(const Offset(0, -26), 40, [
        const Color(0x66F0C56B),
        const Color(0x00F0C56B),
      ]);
      canvas.drawCircle(const Offset(0, -26), 40, p);
      p.shader = null;
      p.color = const Color(0x55F0C56B);
      for (var k = 1; k <= 3; k++) {
        canvas.drawOval(
          Rect.fromLTWH(-22.0 - k * 11, -34.0 + k * 3, 16, 5.0 - k * .6),
          p,
        );
      }
    }
    drawAvatar(canvas, avatar, worldTime, left || right);
    canvas.restore();
    canvas.restore();
    canvas.restore();
  }
}
