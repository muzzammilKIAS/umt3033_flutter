import 'dart:math';
import 'dart:ui';

/// Original props: terrain, collectibles, knowledge gates and the finish vault.
/// Collision geometry lives in [CourseGeometry]; nothing here changes gameplay.

class PropPalette {
  final Color crust, crustLight, soil, soilDeep, seam;
  final Color ledge, ledgeTop, ledgeEdge;
  const PropPalette({
    required this.crust,
    required this.crustLight,
    required this.soil,
    required this.soilDeep,
    required this.seam,
    required this.ledge,
    required this.ledgeTop,
    required this.ledgeEdge,
  });
}

const _props = <PropPalette>[
  PropPalette(
    crust: Color(0xFF5FA88C),
    crustLight: Color(0xFF7EC3A4),
    soil: Color(0xFF3D6F6B),
    soilDeep: Color(0xFF27514F),
    seam: Color(0xFF356160),
    ledge: Color(0xFF3D6F6B),
    ledgeTop: Color(0xFF7EC3A4),
    ledgeEdge: Color(0xFF27514F),
  ),
  PropPalette(
    crust: Color(0xFF63A86B),
    crustLight: Color(0xFF85C489),
    soil: Color(0xFF4A6F4C),
    soilDeep: Color(0xFF2F4E36),
    seam: Color(0xFF3E6042),
    ledge: Color(0xFF4A6F4C),
    ledgeTop: Color(0xFF85C489),
    ledgeEdge: Color(0xFF2F4E36),
  ),
  PropPalette(
    crust: Color(0xFFD8B478),
    crustLight: Color(0xFFEBCE9A),
    soil: Color(0xFF9E7E52),
    soilDeep: Color(0xFF6F5738),
    seam: Color(0xFF8A6C46),
    ledge: Color(0xFF9E7E52),
    ledgeTop: Color(0xFFEBCE9A),
    ledgeEdge: Color(0xFF6F5738),
  ),
  PropPalette(
    crust: Color(0xFF6BA39C),
    crustLight: Color(0xFF8CC0B8),
    soil: Color(0xFF446C74),
    soilDeep: Color(0xFF2C4B55),
    seam: Color(0xFF3A5D66),
    ledge: Color(0xFF446C74),
    ledgeTop: Color(0xFF8CC0B8),
    ledgeEdge: Color(0xFF2C4B55),
  ),
  PropPalette(
    crust: Color(0xFF3E5C7A),
    crustLight: Color(0xFF56779A),
    soil: Color(0xFF263C55),
    soilDeep: Color(0xFF16273A),
    seam: Color(0xFF1E3149),
    ledge: Color(0xFF263C55),
    ledgeTop: Color(0xFF56779A),
    ledgeEdge: Color(0xFF16273A),
  ),
];

PropPalette propsFor(int level) => _props[(level - 1).clamp(0, 4)];

const _gold = Color(0xFFF0C56B);
const _goldDeep = Color(0xFFD9A441);
const _emerald = Color(0xFF167F70);
const _cream = Color(0xFFF7F3E9);
const _ink = Color(0xFF102D3D);

/// Solid terrain: a lit crust over layered soil with quiet masonry seams.
void drawGround(Canvas canvas, Rect r, PropPalette pal) {
  final p = Paint();
  p.shader = Gradient.linear(Offset(r.left, r.top), Offset(r.left, r.bottom), [
    pal.soil,
    pal.soilDeep,
  ]);
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      r,
      topLeft: const Radius.circular(9),
      topRight: const Radius.circular(9),
    ),
    p,
  );
  p.shader = null;

  // Offset masonry: each course is lit on top and shaded underneath, which
  // gives the slab depth without a busy grid.
  canvas.save();
  canvas.clipRRect(
    RRect.fromRectAndCorners(
      r,
      topLeft: const Radius.circular(9),
      topRight: const Radius.circular(9),
    ),
  );
  var course = 0;
  for (var y = r.top + 21; y < r.bottom; y += 27) {
    p.color = pal.seam.withValues(alpha: .85);
    canvas.drawRect(Rect.fromLTWH(r.left, y, r.width, 2), p);
    p.color = Color.lerp(pal.soil, const Color(0xFFFFFFFF), .07)!;
    canvas.drawRect(Rect.fromLTWH(r.left, y + 2, r.width, 2.4), p);
    for (var x = r.left + (course.isEven ? 30 : 68); x < r.right; x += 76) {
      p.color = pal.seam.withValues(alpha: .7);
      canvas.drawRect(Rect.fromLTWH(x, y, 2, 27), p);
    }
    course++;
  }
  // Pebbles catch a little light in the soil.
  p.color = Color.lerp(pal.soil, const Color(0xFFFFFFFF), .12)!;
  for (var x = r.left + 22; x < r.right - 10; x += 63) {
    canvas.drawCircle(Offset(x, r.top + 36), 2.1, p);
    canvas.drawCircle(Offset(x + 27, r.top + 62), 1.6, p);
  }
  // Both cut faces are darker, so a pit reads as a real edge.
  p.shader = Gradient.linear(Offset(r.left, 0), Offset(r.left + 16, 0), [
    pal.soilDeep.withValues(alpha: .55),
    pal.soilDeep.withValues(alpha: 0),
  ]);
  canvas.drawRect(Rect.fromLTWH(r.left, r.top, 16, r.height), p);
  p.shader = Gradient.linear(Offset(r.right - 16, 0), Offset(r.right, 0), [
    pal.soilDeep.withValues(alpha: 0),
    pal.soilDeep.withValues(alpha: .55),
  ]);
  canvas.drawRect(Rect.fromLTWH(r.right - 16, r.top, 16, r.height), p);
  p.shader = null;
  canvas.restore();

  // Crust.
  p.shader = Gradient.linear(
    Offset(r.left, r.top),
    Offset(r.left, r.top + 19),
    [pal.crustLight, pal.crust],
  );
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      Rect.fromLTWH(r.left, r.top, r.width, 18),
      topLeft: const Radius.circular(9),
      topRight: const Radius.circular(9),
    ),
    p,
  );
  p.shader = null;
  p.color = Color.lerp(pal.crustLight, const Color(0xFFFFFFFF), .3)!;
  canvas.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 3), p);
  p.color = pal.soilDeep.withValues(alpha: .4);
  canvas.drawRect(Rect.fromLTWH(r.left, r.top + 18, r.width, 3), p);

  // Tufts along the rim.
  p.color = pal.crust;
  for (var x = r.left + 16; x < r.right - 8; x += 52) {
    canvas.drawOval(Rect.fromLTWH(x, r.top - 5, 14, 9), p);
    canvas.drawOval(Rect.fromLTWH(x + 20, r.top - 3.5, 10, 7), p);
  }
  p.color = Color.lerp(pal.crustLight, const Color(0xFFFFFFFF), .25)!;
  for (var x = r.left + 19; x < r.right - 8; x += 52) {
    canvas.drawOval(Rect.fromLTWH(x, r.top - 4, 7, 4.5), p);
  }
}

/// A floating ledge: capsule, lit rim, grounded underside.
void drawLedge(Canvas canvas, Rect r, PropPalette pal) {
  final p = Paint();
  p.color = _ink.withValues(alpha: .1);
  canvas.drawOval(Rect.fromLTWH(r.left + 8, r.bottom + 1, r.width - 16, 6), p);
  // A shallow underside below the collision box reads as thickness without
  // changing where the player actually lands.
  p.color = pal.ledgeEdge;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(r.left + 6, r.top + 3, r.width - 12, r.height),
      Radius.circular(r.height * .5),
    ),
    p,
  );
  p.shader = Gradient.linear(Offset(r.left, r.top), Offset(r.left, r.bottom), [
    pal.ledge,
    pal.ledgeEdge,
  ]);
  canvas.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(r.height / 2)),
    p,
  );
  p.shader = null;
  p.color = pal.ledgeTop;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(r.left + 3, r.top + 1.4, r.width - 6, r.height * .38),
      Radius.circular(r.height * .2),
    ),
    p,
  );
  p.color = _gold.withValues(alpha: .5);
  canvas.drawCircle(Offset(r.left + 6, r.center.dy), 1.7, p);
  canvas.drawCircle(Offset(r.right - 6, r.center.dy), 1.7, p);
}

/// A vocabulary gem: faceted, haloed and gently bobbing.
void drawGem(Canvas canvas, double x, double y, double time, int seed) {
  final p = Paint();
  final spin = sin(time * 2.2 + seed) * .5 + .5;
  final w = 7.5 + spin * 5.5;

  p.shader = Gradient.radial(Offset(x, y), 26, [
    _gold.withValues(alpha: .34),
    const Color(0x00000000),
  ]);
  canvas.drawCircle(Offset(x, y), 26, p);
  p.shader = null;

  final body = Path()
    ..moveTo(x, y - 14)
    ..lineTo(x + w, y - 3)
    ..lineTo(x, y + 14)
    ..lineTo(x - w, y - 3)
    ..close();
  p.color = _goldDeep;
  canvas.drawPath(body, p);
  // Left facet catches the light; right facet stays in shade.
  p.color = _gold;
  canvas.drawPath(
    Path()
      ..moveTo(x, y - 14)
      ..lineTo(x, y + 14)
      ..lineTo(x - w, y - 3)
      ..close(),
    p,
  );
  p.color = const Color(0xFFFFF0C8);
  canvas.drawPath(
    Path()
      ..moveTo(x, y - 14)
      ..lineTo(x - w * .52, y - 5.5)
      ..lineTo(x, y - 1)
      ..close(),
    p,
  );
  p.color = _ink.withValues(alpha: .18);
  canvas.drawPath(
    Path()
      ..moveTo(x, y - 14)
      ..lineTo(x + w, y - 3)
      ..lineTo(x, y + 14)
      ..close(),
    p,
  );

  // Sparkle.
  final s = 2.2 + spin * 2.4;
  p.color = const Color(0xFFFFFFFF).withValues(alpha: .55 + spin * .45);
  canvas.drawPath(
    Path()
      ..moveTo(x + 12, y - 15 - s)
      ..lineTo(x + 13.1, y - 15)
      ..lineTo(x + 12 + s, y - 13.9)
      ..lineTo(x + 13.1, y - 12.8)
      ..lineTo(x + 12, y - 13 + s)
      ..lineTo(x + 10.9, y - 12.8)
      ..lineTo(x + 12 - s, y - 13.9)
      ..lineTo(x + 10.9, y - 15)
      ..close(),
    p,
  );
}

/// A rolling hazard. Warning chevrons read as "do not touch" at speed.
void drawHazard(Canvas canvas, double x, double y, double time) {
  final p = Paint();
  p.color = _ink.withValues(alpha: .16);
  canvas.drawOval(Rect.fromLTWH(x - 16, y + 22, 32, 8), p);
  canvas.save();
  canvas.translate(x, y + 12);
  canvas.rotate(time * 2.4);
  p.color = const Color(0xFFB4562F);
  for (var k = 0; k < 8; k++) {
    canvas.save();
    canvas.rotate(k * pi / 4);
    canvas.drawPath(
      Path()
        ..moveTo(-3.4, -12)
        ..lineTo(0, -18.5)
        ..lineTo(3.4, -12)
        ..close(),
      p,
    );
    canvas.restore();
  }
  p.shader = Gradient.linear(const Offset(-13, -13), const Offset(13, 13), [
    const Color(0xFFE8A54B),
    const Color(0xFFA9622C),
  ]);
  canvas.drawCircle(Offset.zero, 13, p);
  p.shader = null;
  p.color = const Color(0xFF6B3A1E);
  for (var k = 0; k < 4; k++) {
    canvas.save();
    canvas.rotate(k * pi / 2 + .4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2, -11, 4, 7),
        const Radius.circular(2),
      ),
      p,
    );
    canvas.restore();
  }
  p.color = const Color(0xFFFCE3B4);
  canvas.drawCircle(const Offset(-3.4, -3.4), 3.4, p);
  canvas.restore();
}

/// A knowledge gate: an arch with a lantern that pulses until it is answered.
void drawGate(Canvas canvas, double x, double time, bool passed) {
  final p = Paint();
  final accent = passed ? _emerald : _gold;
  final pulse = passed ? 1.0 : .74 + .26 * (sin(time * 2.6) * .5 + .5);

  p.shader = Gradient.radial(Offset(x, 372), 92, [
    accent.withValues(alpha: .26 * pulse),
    const Color(0x00000000),
  ]);
  canvas.drawCircle(Offset(x, 372), 92, p);
  p.shader = null;

  // Pillars.
  p.color = _cream;
  for (final px in [x - 34.0, x + 22.0]) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px, 322, 12, 128),
        const Radius.circular(5),
      ),
      p,
    );
  }
  p.color = accent;
  for (final px in [x - 36.0, x + 20.0]) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(px, 316, 16, 8),
        const Radius.circular(3),
      ),
      p,
    );
  }

  // Arch head.
  p
    ..color = _cream
    ..style = PaintingStyle.stroke
    ..strokeWidth = 11
    ..strokeCap = StrokeCap.round;
  canvas.drawArc(Rect.fromLTWH(x - 34, 296, 68, 60), pi, pi, false, p);
  p
    ..color = accent
    ..strokeWidth = 4;
  canvas.drawArc(Rect.fromLTWH(x - 34, 296, 68, 60), pi, pi, false, p);
  p.style = PaintingStyle.fill;

  // Lantern.
  p.color = accent;
  canvas.drawPath(
    Path()
      ..moveTo(x, 288 - 5 * pulse)
      ..lineTo(x + 10, 304)
      ..lineTo(x, 320)
      ..lineTo(x - 10, 304)
      ..close(),
    p,
  );
  p.color = const Color(0xFFFFF6DC).withValues(alpha: pulse);
  canvas.drawCircle(Offset(x, 304), 4.2, p);

  // Banner between the pillars: a scroll when locked, a seal when passed.
  p.color = passed ? _emerald.withValues(alpha: .9) : _ink;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x - 22, 336, 44, 30),
      const Radius.circular(6),
    ),
    p,
  );
  p.color = _cream;
  if (passed) {
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(x - 8, 351)
        ..lineTo(x - 2, 357)
        ..lineTo(x + 9, 344),
      p,
    );
    p.style = PaintingStyle.fill;
  } else {
    for (var k = 0; k < 3; k++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 13, 343.0 + k * 6, k == 2 ? 16 : 26, 2.6),
          const Radius.circular(1.4),
        ),
        p,
      );
    }
  }
}

/// The Grand Muamalat Vault door, with pennants for the finish line.
void drawFinish(Canvas canvas, double x, double time) {
  final p = Paint();
  p.shader = Gradient.radial(Offset(x + 38, 386), 110, [
    _gold.withValues(alpha: .3),
    const Color(0x00000000),
  ]);
  canvas.drawCircle(Offset(x + 38, 386), 110, p);
  p.shader = null;

  // Mast and pennants.
  p.color = _cream;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 34, 236, 6, 86),
      const Radius.circular(3),
    ),
    p,
  );
  for (var k = 0; k < 3; k++) {
    p.color = k.isEven ? _emerald : _gold;
    final wave = sin(time * 3 + k) * 4;
    canvas.drawPath(
      Path()
        ..moveTo(x + 40, 242.0 + k * 20)
        ..lineTo(x + 78 + wave, 250.0 + k * 20)
        ..lineTo(x + 40, 258.0 + k * 20)
        ..close(),
      p,
    );
  }

  // Vault frame.
  p.color = _cream;
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      Rect.fromLTWH(x, 318, 76, 132),
      topLeft: const Radius.circular(38),
      topRight: const Radius.circular(38),
    ),
    p,
  );
  p.color = _goldDeep;
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      Rect.fromLTWH(x + 7, 325, 62, 125),
      topLeft: const Radius.circular(31),
      topRight: const Radius.circular(31),
    ),
    p,
  );
  p.shader = Gradient.linear(Offset(x + 7, 325), Offset(x + 69, 450), [
    _gold,
    _goldDeep,
  ]);
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      Rect.fromLTWH(x + 11, 329, 54, 121),
      topLeft: const Radius.circular(27),
      topRight: const Radius.circular(27),
    ),
    p,
  );
  p.shader = null;

  // Handwheel.
  final spin = time * .7;
  p.color = _emerald;
  canvas.drawCircle(Offset(x + 38, 388), 20, p);
  p.color = const Color(0xFF0F5E54);
  canvas.drawCircle(Offset(x + 38, 388), 13, p);
  p.color = _cream;
  canvas.save();
  canvas.translate(x + 38, 388);
  canvas.rotate(spin);
  for (var k = 0; k < 4; k++) {
    canvas.save();
    canvas.rotate(k * pi / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-1.8, -19, 3.6, 10),
        const Radius.circular(1.8),
      ),
      p,
    );
    canvas.restore();
  }
  canvas.restore();
  p.color = _gold;
  canvas.drawCircle(Offset(x + 38, 388), 4.6, p);
}
