import 'dart:math';
import 'dart:ui';

/// Original geometric student/explorer art; no external sprite dependencies.
///
/// The origin is the character's feet. The figure is about 64 units tall and
/// is drawn back-to-front: shadow, far limbs, torso, near limbs, head.

class _Look {
  final Color coat, coatDark, coatLight, trouser, skin, skinShade, hair;
  final bool veiled, capped;
  const _Look({
    required this.coat,
    required this.coatDark,
    required this.coatLight,
    required this.trouser,
    required this.skin,
    required this.skinShade,
    required this.hair,
    required this.veiled,
    required this.capped,
  });
}

const _looks = <_Look>[
  // Adam — student, emerald coat.
  _Look(
    coat: Color(0xFF167F70),
    coatDark: Color(0xFF0F5E54),
    coatLight: Color(0xFF3FA08F),
    trouser: Color(0xFF23384A),
    skin: Color(0xFFE4B48C),
    skinShade: Color(0xFFC8946C),
    hair: Color(0xFF2B2622),
    veiled: false,
    capped: false,
  ),
  // Hana — student, indigo tunic and veil.
  _Look(
    coat: Color(0xFF526BA0),
    coatDark: Color(0xFF3B4F7C),
    coatLight: Color(0xFF7489BB),
    trouser: Color(0xFF2B3550),
    skin: Color(0xFFEFC49E),
    skinShade: Color(0xFFD2A078),
    hair: Color(0xFF3A2F2A),
    veiled: true,
    capped: false,
  ),
  // Rayyan — explorer, amber field coat and cap.
  _Look(
    coat: Color(0xFFB27442),
    coatDark: Color(0xFF8C5A31),
    coatLight: Color(0xFFCE9463),
    trouser: Color(0xFF3B3A34),
    skin: Color(0xFFD9A57C),
    skinShade: Color(0xFFBB855F),
    hair: Color(0xFF241F1C),
    veiled: false,
    capped: true,
  ),
  // Maryam — explorer, plum tunic and veil.
  _Look(
    coat: Color(0xFF834D70),
    coatDark: Color(0xFF653956),
    coatLight: Color(0xFFA36D90),
    trouser: Color(0xFF39293A),
    skin: Color(0xFFE8BC96),
    skinShade: Color(0xFFCB9871),
    hair: Color(0xFF322722),
    veiled: true,
    capped: true,
  ),
];

const _gold = Color(0xFFF0C56B);
const _ink = Color(0xFF16232B);

void drawAvatar(Canvas canvas, int avatar, double stride, bool running) {
  final look = _looks[avatar % 4];
  final p = Paint();
  final swing = running ? sin(stride * 12) : 0.0;
  final bob = running ? (cos(stride * 24) * .9 - .9) : 0.0;

  // Contact shadow keeps the figure planted instead of floating.
  p.color = const Color(0x2E102D3D);
  canvas.drawOval(Rect.fromLTWH(-15, -5.5, 30, 9), p);
  p.color = const Color(0x22102D3D);
  canvas.drawOval(Rect.fromLTWH(-19, -4.5, 38, 7), p);

  canvas.save();
  canvas.translate(0, bob);

  _leg(canvas, p, look, swing * .46, true);
  _arm(canvas, p, look, -swing * .5, true);
  _torso(canvas, p, look);
  _leg(canvas, p, look, -swing * .46, false);
  _arm(canvas, p, look, swing * .5, false);
  _head(canvas, p, look);

  canvas.restore();
}

/// Legs pivot at the hip so a run reads as a scissor, not a single block.
void _leg(Canvas canvas, Paint p, _Look look, double angle, bool far) {
  canvas.save();
  canvas.translate(far ? -6.0 : 4.6, -21.5);
  canvas.rotate(angle);
  p.color = far ? Color.lerp(look.trouser, _ink, .3)! : look.trouser;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-3.6, -1, 7.2, 20),
      const Radius.circular(3.6),
    ),
    p,
  );
  p.color = far ? const Color(0xFF16232B) : const Color(0xFF243440);
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      const Rect.fromLTWH(-4.4, 15.4, 10.6, 5.4),
      topLeft: const Radius.circular(2.4),
      topRight: const Radius.circular(2.4),
      bottomLeft: const Radius.circular(2.6),
      bottomRight: const Radius.circular(2.6),
    ),
    p,
  );
  canvas.restore();
}

void _arm(Canvas canvas, Paint p, _Look look, double angle, bool far) {
  canvas.save();
  canvas.translate(far ? -11.5 : 11.5, -40);
  canvas.rotate(angle);
  p.color = far ? look.coatDark : look.coatLight;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-2.9, -2.4, 5.8, 19),
      const Radius.circular(2.9),
    ),
    p,
  );
  p.color = far ? look.skinShade : look.skin;
  canvas.drawCircle(const Offset(0, 18), 3.2, p);
  canvas.restore();
}

void _torso(Canvas canvas, Paint p, _Look look) {
  final body = RRect.fromRectAndCorners(
    const Rect.fromLTWH(-13, -45, 26, 28),
    topLeft: const Radius.circular(10),
    topRight: const Radius.circular(10),
    bottomLeft: const Radius.circular(5),
    bottomRight: const Radius.circular(5),
  );
  p.shader = Gradient.linear(
    const Offset(-13, -45),
    const Offset(13, -17),
    [look.coatLight, look.coat, look.coatDark],
    [0, .45, 1],
  );
  canvas.drawRRect(body, p);
  p.shader = null;

  // Collar.
  p.color = Color.lerp(look.coatLight, const Color(0xFFFFFFFF), .3)!;
  canvas.drawPath(
    Path()
      ..moveTo(-6, -45)
      ..lineTo(0, -37)
      ..lineTo(6, -45)
      ..close(),
    p,
  );
  // Satchel strap and belt: the student is carrying something.
  p.color = _gold;
  canvas.drawPath(
    Path()
      ..moveTo(-7.5, -45)
      ..lineTo(-1.5, -45)
      ..lineTo(9.5, -20)
      ..lineTo(4, -20)
      ..close(),
    p,
  );
  p.color = Color.lerp(look.coatDark, _ink, .35)!;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-13, -23, 26, 4.2),
      const Radius.circular(2),
    ),
    p,
  );
  p.color = _gold;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-2.2, -23.4, 4.6, 5),
      const Radius.circular(1.4),
    ),
    p,
  );
  // Satchel.
  p.color = Color.lerp(look.coatDark, _ink, .18)!;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(9, -31, 9, 11),
      const Radius.circular(2.6),
    ),
    p,
  );
  p.color = _gold;
  canvas.drawRect(const Rect.fromLTWH(9, -27.5, 9, 1.8), p);
}

void _head(Canvas canvas, Paint p, _Look look) {
  // Neck.
  p.color = look.skinShade;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-3.2, -49, 6.4, 6),
      const Radius.circular(2.6),
    ),
    p,
  );

  if (look.veiled) {
    // The veil is drawn behind the face, framing it.
    p.color = look.coatDark;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12.5, -62, 25, 30),
        const Radius.circular(12),
      ),
      p,
    );
    p.color = look.coat;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12.5, -62, 25, 24),
        const Radius.circular(12),
      ),
      p,
    );
  }

  // Face.
  p.color = look.skin;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-8.4, -60, 16.8, 18),
      const Radius.circular(8),
    ),
    p,
  );
  p.color = look.skinShade.withValues(alpha: .5);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(3.4, -60, 5, 18),
      const Radius.circular(6),
    ),
    p,
  );

  if (look.veiled) {
    // Veil edge over the brow.
    p.color = Color.lerp(look.coat, const Color(0xFFFFFFFF), .18)!;
    canvas.drawPath(
      Path()
        ..moveTo(-9.2, -60.5)
        ..quadraticBezierTo(0, -66.5, 9.2, -60.5)
        ..quadraticBezierTo(0, -57.5, -9.2, -60.5)
        ..close(),
      p,
    );
  } else {
    p.color = look.hair;
    canvas.drawPath(
      Path()
        ..moveTo(-8.6, -57.5)
        ..quadraticBezierTo(-9.4, -66, 0, -66)
        ..quadraticBezierTo(9.4, -66, 8.6, -57.5)
        ..quadraticBezierTo(4, -61.5, -8.6, -57.5)
        ..close(),
      p,
    );
    // Ear.
    p.color = look.skinShade;
    canvas.drawCircle(const Offset(-8.2, -50.5), 1.9, p);
  }

  if (look.capped) {
    p.color = _gold;
    canvas.drawPath(
      Path()
        ..moveTo(-9.5, -61.5)
        ..quadraticBezierTo(0, -70, 9.5, -61.5)
        ..close(),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12.5, -62.6, 25, 3.4),
        const Radius.circular(1.8),
      ),
      p,
    );
  }

  // Face: one eye, brow and a small smile read at game scale.
  p.color = _ink;
  canvas.drawOval(const Rect.fromLTWH(1.4, -54.6, 2.2, 2.8), p);
  p.color = _ink.withValues(alpha: .65);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(.9, -57, 3.4, 1.1),
      const Radius.circular(.6),
    ),
    p,
  );
  p
    ..color = const Color(0x99A9603F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
    ..strokeCap = StrokeCap.round;
  canvas.drawArc(
    const Rect.fromLTWH(-.6, -51.6, 5.4, 3.6),
    .25,
    pi * .55,
    false,
    p,
  );
  p.style = PaintingStyle.fill;
}
