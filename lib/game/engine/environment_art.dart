import 'dart:math';
import 'dart:ui';

/// Original architectural landmarks; sacred texts/figures are never scenery.
///
/// Every world is layered vector art: a gradient sky, a glowing celestial body,
/// drifting clouds or stars, two hazy parallax ridges, a detailed landmark band
/// and foreground planting. Nothing here is sampled from an external sprite.

class _Palette {
  final Color skyTop, skyMid, skyLow, haze;
  final Color ridge, cityFar;
  final Color stone, stoneShade, stoneLight;
  final Color dome, trim, glass;
  final Color foliage, foliageDark, trunk;
  final Color valley, valleyDeep;
  final bool night;
  const _Palette({
    required this.skyTop,
    required this.skyMid,
    required this.skyLow,
    required this.haze,
    required this.ridge,
    required this.cityFar,
    required this.stone,
    required this.stoneShade,
    required this.stoneLight,
    required this.dome,
    required this.trim,
    required this.glass,
    required this.foliage,
    required this.foliageDark,
    required this.trunk,
    required this.valley,
    required this.valleyDeep,
    this.night = false,
  });
}

const _worlds = <_Palette>[
  // 1 — Campus, Islamic finance institution, Islamic bank. Clear morning.
  _Palette(
    skyTop: Color(0xFF9FD6E8),
    skyMid: Color(0xFFCCEAF0),
    skyLow: Color(0xFFF0F6E9),
    haze: Color(0xFFD5EAE6),
    ridge: Color(0xFFA9CFCC),
    cityFar: Color(0xFF8FB9BB),
    stone: Color(0xFFF4ECDB),
    stoneShade: Color(0xFFD9CDB4),
    stoneLight: Color(0xFFFDF8EC),
    dome: Color(0xFF167F70),
    trim: Color(0xFFF0C56B),
    glass: Color(0xFF8FC8CE),
    foliage: Color(0xFF6FA98D),
    foliageDark: Color(0xFF477F6C),
    trunk: Color(0xFF8A6A4F),
    valley: Color(0xFF3A6560),
    valleyDeep: Color(0xFF1C3836),
  ),
  // 2 — Knowledge garden, hadith library, investment district. Lush.
  _Palette(
    skyTop: Color(0xFFB6DCC9),
    skyMid: Color(0xFFD9EDD8),
    skyLow: Color(0xFFF4F7E4),
    haze: Color(0xFFD3E7CF),
    ridge: Color(0xFFA5C8A6),
    cityFar: Color(0xFF8BAF90),
    stone: Color(0xFFF2EAD4),
    stoneShade: Color(0xFFD5C9AB),
    stoneLight: Color(0xFFFCF7E7),
    dome: Color(0xFF2E7D62),
    trim: Color(0xFFE0B457),
    glass: Color(0xFFA7CBB2),
    foliage: Color(0xFF5E9C6E),
    foliageDark: Color(0xFF3C7454),
    trunk: Color(0xFF7D6144),
    valley: Color(0xFF3B6247),
    valleyDeep: Color(0xFF1C3526),
  ),
  // 3 — Marketplace, takaful, Baitul Mal treasury. Warm sand and gold.
  _Palette(
    skyTop: Color(0xFFF2CE9B),
    skyMid: Color(0xFFF9E6C6),
    skyLow: Color(0xFFFDF5E4),
    haze: Color(0xFFEBD5AE),
    ridge: Color(0xFFDCBF96),
    cityFar: Color(0xFFC8A87F),
    stone: Color(0xFFF7EBD2),
    stoneShade: Color(0xFFDCC49C),
    stoneLight: Color(0xFFFFF8EA),
    dome: Color(0xFFB4763C),
    trim: Color(0xFFE9B44C),
    glass: Color(0xFFD9B98A),
    foliage: Color(0xFF8AA36B),
    foliageDark: Color(0xFF657F4E),
    trunk: Color(0xFF8B6A45),
    valley: Color(0xFF7C6342),
    valleyDeep: Color(0xFF433520),
  ),
  // 4 — Community finance, Ar-Rahn gold quarter, currency city. Cool civic.
  _Palette(
    skyTop: Color(0xFFA8CFE2),
    skyMid: Color(0xFFD1E7EF),
    skyLow: Color(0xFFEFF5F1),
    haze: Color(0xFFCADFE8),
    ridge: Color(0xFFA1C1D0),
    cityFar: Color(0xFF8AACC0),
    stone: Color(0xFFEFF1E7),
    stoneShade: Color(0xFFCFD5C9),
    stoneLight: Color(0xFFFBFCF4),
    dome: Color(0xFF2F6E8F),
    trim: Color(0xFFE3C06A),
    glass: Color(0xFF9CC3D4),
    foliage: Color(0xFF6C9E97),
    foliageDark: Color(0xFF477974),
    trunk: Color(0xFF7A6250),
    valley: Color(0xFF3D5F6B),
    valleyDeep: Color(0xFF1F343C),
  ),
  // 5 — The Grand Muamalat Vault. Night observatory.
  _Palette(
    skyTop: Color(0xFF101D33),
    skyMid: Color(0xFF1E3454),
    skyLow: Color(0xFF3B5578),
    haze: Color(0xFF2B4366),
    ridge: Color(0xFF243B5C),
    cityFar: Color(0xFF2C4870),
    stone: Color(0xFF2E4466),
    stoneShade: Color(0xFF223451),
    stoneLight: Color(0xFF3D5880),
    dome: Color(0xFFD9A441),
    trim: Color(0xFFF0C56B),
    glass: Color(0xFFF6D98E),
    foliage: Color(0xFF2E5262),
    foliageDark: Color(0xFF203D4B),
    trunk: Color(0xFF3A3A46),
    valley: Color(0xFF16273A),
    valleyDeep: Color(0xFF080F18),
    night: true,
  ),
];

const _horizon = 450.0;

void drawEnvironment(
  Canvas canvas,
  double width,
  double cameraX,
  double time,
  int level,
  int zone,
) {
  final w = _worlds[(level - 1).clamp(0, 4)];
  final p = Paint();

  _sky(canvas, p, width, w);
  _celestial(canvas, p, width, time, w);
  if (w.night) {
    _stars(canvas, p, width, time);
  } else {
    _clouds(canvas, p, width, cameraX, time, w);
  }
  _ridge(canvas, p, width, cameraX * .05, w.ridge, 122, 260, 26, 4.0);
  _ridge(canvas, p, width, cameraX * .09, w.haze, 88, 210, 18, 1.7);
  _farCity(canvas, p, width, cameraX * .16, w);
  // Depth is staged: each band forward is larger and less washed out, so the
  // playfield stays the most readable thing on screen.
  _planting(canvas, p, width, cameraX * .24, time, level, _hazed(w, .46), .72);
  _landmarks(canvas, p, width, cameraX * .34, time, level, zone, _hazed(w, .2));
  _berm(canvas, p, width, cameraX * .44, w);
  _veil(canvas, p, width, w);
  _valley(canvas, p, width, w);
  _shrubs(canvas, p, width, cameraX * .6, w);
}

/// Atmospheric perspective: everything distant drifts toward the sky colour.
_Palette _hazed(_Palette w, double t) {
  Color f(Color c) => Color.lerp(c, w.skyLow, t)!;
  return _Palette(
    skyTop: w.skyTop,
    skyMid: w.skyMid,
    skyLow: w.skyLow,
    haze: w.haze,
    ridge: f(w.ridge),
    cityFar: f(w.cityFar),
    stone: f(w.stone),
    stoneShade: f(w.stoneShade),
    stoneLight: f(w.stoneLight),
    dome: f(w.dome),
    trim: f(w.trim),
    glass: f(w.glass),
    foliage: f(w.foliage),
    foliageDark: f(w.foliageDark),
    trunk: f(w.trunk),
    valley: w.valley,
    valleyDeep: w.valleyDeep,
    night: w.night,
  );
}

/// One soft wash unifies the background and separates it from the props.
void _veil(Canvas canvas, Paint p, double width, _Palette w) {
  p.shader = Gradient.linear(const Offset(0, 170), const Offset(0, _horizon), [
    w.skyLow.withValues(alpha: 0),
    w.skyLow.withValues(alpha: .3),
  ]);
  canvas.drawRect(Rect.fromLTWH(0, 170, width, _horizon - 170 + 2), p);
  p.shader = null;
}

/// A planted berm that hides where the landmarks meet the ground.
void _berm(Canvas canvas, Paint p, double width, double shift, _Palette w) {
  final path = Path()..moveTo(-20, _horizon + 6);
  for (var x = -20.0; x <= width + 20; x += 16) {
    final t = (x + shift) / 118;
    path.lineTo(x, _horizon - 15 - sin(t) * 4 - sin(t * 2.7) * 2.4);
  }
  path
    ..lineTo(width + 20, _horizon + 6)
    ..close();
  p.color = Color.lerp(w.foliage, w.skyLow, .28)!;
  canvas.drawPath(path, p);
  p.color = Color.lerp(w.foliageDark, w.skyLow, .34)!;
  canvas.drawRect(Rect.fromLTWH(0, _horizon - 6, width, 8), p);
}

/// Low bushes just above the terrain line, the nearest scenery layer.
void _shrubs(Canvas canvas, Paint p, double width, double shift, _Palette w) {
  const spacing = 143.0;
  final offset = shift % spacing;
  for (var i = -1; i < width / spacing + 1; i++) {
    final bx = i * spacing - offset;
    p.color = w.foliageDark;
    canvas.drawOval(Rect.fromLTWH(bx, _horizon - 19, 46, 22), p);
    canvas.drawOval(Rect.fromLTWH(bx + 30, _horizon - 14, 32, 17), p);
    p.color = w.foliage;
    canvas.drawOval(Rect.fromLTWH(bx + 5, _horizon - 20, 30, 15), p);
  }
}

void _sky(Canvas canvas, Paint p, double width, _Palette w) {
  p
    ..shader = Gradient.linear(
      Offset.zero,
      const Offset(0, _horizon),
      [w.skyTop, w.skyMid, w.skyLow],
      [0, .58, 1],
    )
    ..color = w.skyTop;
  canvas.drawRect(Rect.fromLTWH(0, 0, width, _horizon + 2), p);
  p.shader = null;
}

void _celestial(Canvas canvas, Paint p, double width, double time, _Palette w) {
  final cx = width * .78, cy = w.night ? 92.0 : 104.0;
  final r = w.night ? 26.0 : 40.0;
  // A wide, very soft halo keeps the light source from looking like a sticker.
  p.shader = Gradient.radial(
    Offset(cx, cy),
    r * 4.4,
    [
      w.night ? const Color(0x55A9C6F5) : const Color(0x88FFF3CD),
      const Color(0x00FFFFFF),
    ],
    [0, 1],
  );
  canvas.drawCircle(Offset(cx, cy), r * 4.4, p);
  p.shader = null;
  p.color = w.night ? const Color(0xFFEFF3FF) : const Color(0xFFFFF6DA);
  canvas.drawCircle(Offset(cx, cy), r, p);
  if (w.night) {
    // Crescent: the sky colour is punched back over the disc.
    p.color = w.skyTop;
    canvas.drawCircle(Offset(cx + 11, cy - 8), r * .92, p);
  } else {
    p.color = const Color(0x66FFFFFF);
    canvas.drawCircle(Offset(cx, cy), r * 1.22, p);
  }
}

void _stars(Canvas canvas, Paint p, double width, double time) {
  for (var i = 0; i < width / 26 + 2; i++) {
    final sx = i * 26.0 + (i * 53 % 19);
    final sy = 18 + ((i * 71) % 230).toDouble();
    final twinkle = .45 + .55 * (sin(time * 1.6 + i * 1.7) * .5 + .5);
    p.color = Color.lerp(
      const Color(0x00FFFFFF),
      const Color(0xFFE8F0FF),
      twinkle,
    )!;
    canvas.drawCircle(Offset(sx, sy), i % 7 == 0 ? 1.9 : 1.0, p);
  }
}

void _clouds(
  Canvas canvas,
  Paint p,
  double width,
  double cameraX,
  double time,
  _Palette w,
) {
  for (var band = 0; band < 2; band++) {
    final spacing = band == 0 ? 330.0 : 470.0;
    final speed = band == 0 ? .06 : .03;
    final y = band == 0 ? 96.0 : 158.0;
    final scale = band == 0 ? 1.0 : .72;
    p.color = Color.lerp(
      const Color(0x00FFFFFF),
      const Color(0xFFFFFFFF),
      band == 0 ? .82 : .5,
    )!;
    for (var i = -1; i < width / spacing + 1; i++) {
      final cx = i * spacing - (cameraX * speed + time * 5) % spacing;
      _cloud(canvas, p, cx, y + sin(i * 1.3) * 12, scale);
    }
  }
}

void _cloud(Canvas canvas, Paint p, double x, double y, double s) {
  canvas.drawOval(Rect.fromLTWH(x, y, 96 * s, 30 * s), p);
  canvas.drawOval(Rect.fromLTWH(x + 18 * s, y - 15 * s, 54 * s, 36 * s), p);
  canvas.drawOval(Rect.fromLTWH(x + 46 * s, y - 7 * s, 42 * s, 28 * s), p);
}

/// A soft rolling silhouette; the sine sum keeps it from reading as a wave.
void _ridge(
  Canvas canvas,
  Paint p,
  double width,
  double shift,
  Color color,
  double height,
  double wavelength,
  double amplitude,
  double phase,
) {
  final path = Path()..moveTo(-40, _horizon + 4);
  for (var x = -40.0; x <= width + 40; x += 14) {
    final t = (x + shift) / wavelength;
    final y =
        _horizon -
        height -
        sin(t + phase) * amplitude -
        sin(t * 2.3 + phase * 1.7) * amplitude * .42;
    path.lineTo(x, y);
  }
  path
    ..lineTo(width + 40, _horizon + 4)
    ..close();
  p.color = color;
  canvas.drawPath(path, p);
}

void _farCity(Canvas canvas, Paint p, double width, double shift, _Palette w) {
  const spacing = 148.0;
  final offset = shift % spacing;
  p.color = w.cityFar;
  for (var i = -1; i < width / spacing + 1; i++) {
    final bx = i * spacing - offset;
    final k = (i.abs() * 7) % 5;
    final h = 62.0 + k * 21;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(bx, _horizon - h, 92, h + 4),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      ),
      p,
    );
    if (k.isEven) {
      // A dome and a slim minaret break up the block rhythm.
      canvas.drawPath(_onionDome(bx + 46, _horizon - h, 54, 34), p);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx + 96, _horizon - h - 40, 11, h + 44),
          const Radius.circular(5),
        ),
        p,
      );
      canvas.drawCircle(Offset(bx + 101.5, _horizon - h - 42), 7.5, p);
    }
  }
}

/// Below the horizon the pits between platforms read as depth, not as sky.
void _valley(Canvas canvas, Paint p, double width, _Palette w) {
  p.shader = Gradient.linear(const Offset(0, _horizon), const Offset(0, 560), [
    w.valley,
    w.valleyDeep,
  ]);
  canvas.drawRect(Rect.fromLTWH(0, _horizon, width, 120), p);
  p.shader = null;
}

// ---------------------------------------------------------------------------
// Landmarks
// ---------------------------------------------------------------------------

void _landmarks(
  Canvas canvas,
  Paint p,
  double width,
  double shift,
  double time,
  int level,
  int zone,
  _Palette w,
) {
  const spacing = 358.0;
  final offset = shift % spacing;
  for (var i = -1; i < width / spacing + 1; i++) {
    final bx = i * spacing - offset;
    final h = 96.0 + ((i.abs() + level * 2 + zone) % 3) * 21;
    if (level == 1 && zone == 0) {
      _campus(canvas, p, bx, h, w);
    } else if (level == 1 || (level == 4 && zone == 2)) {
      _bank(canvas, p, bx, h, w);
    } else if (level == 2 && zone == 1) {
      _library(canvas, p, bx, h, w);
    } else if (level == 2) {
      _garden(canvas, p, bx, h, w);
    } else if (level == 3 && zone == 0) {
      _bazaar(canvas, p, bx, h, w);
    } else if (level == 3 || level == 4) {
      _treasury(canvas, p, bx, h, w);
    } else {
      _observatory(canvas, p, bx, h, time, w);
    }
  }
}

/// Shared body: a stone block with a lit top edge and a shaded right face.
void _body(Canvas canvas, Paint p, Rect r, _Palette w, {double radius = 7}) {
  p.color = w.stone;
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      r,
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    ),
    p,
  );
  p.color = w.stoneShade;
  canvas.drawRect(Rect.fromLTWH(r.right - 15, r.top + radius, 15, r.height), p);
  p.color = w.stoneLight;
  canvas.drawRect(Rect.fromLTWH(r.left, r.top, r.width - 15, 4), p);
}

Path _onionDome(double cx, double baseY, double width, double height) {
  final hw = width / 2;
  return Path()
    ..moveTo(cx - hw, baseY)
    ..cubicTo(
      cx - hw,
      baseY - height * .5,
      cx - hw * .8,
      baseY - height * .74,
      cx,
      baseY - height,
    )
    ..cubicTo(
      cx + hw * .8,
      baseY - height * .74,
      cx + hw,
      baseY - height * .5,
      cx + hw,
      baseY,
    )
    ..close();
}

Path _arch(double left, double top, double width, double height) {
  final r = width / 2;
  return Path()
    ..moveTo(left, top + height)
    ..lineTo(left, top + r)
    ..arcToPoint(Offset(left + width, top + r), radius: Radius.circular(r))
    ..lineTo(left + width, top + height)
    ..close();
}

void _domeAndFinial(
  Canvas canvas,
  Paint p,
  double cx,
  double baseY,
  double dw,
  double dh,
  _Palette w,
) {
  p.color = w.dome;
  canvas.drawPath(_onionDome(cx, baseY, dw, dh), p);
  // A highlight down the left of the dome gives it volume.
  p.color = Color.lerp(w.dome, const Color(0xFFFFFFFF), .22)!;
  canvas.drawPath(_onionDome(cx - dw * .16, baseY, dw * .52, dh * .9), p);
  p.color = w.trim;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 1.6, baseY - dh - 13, 3.2, 14),
      const Radius.circular(2),
    ),
    p,
  );
  canvas.drawCircle(Offset(cx, baseY - dh - 15), 3.4, p);
}

void _windows(
  Canvas canvas,
  Paint p,
  double left,
  double top,
  int count,
  double gap,
  double ww,
  double wh,
  _Palette w,
) {
  for (var k = 0; k < count; k++) {
    final x = left + k * gap;
    p.color = w.night ? w.glass : w.glass.withValues(alpha: .5);
    canvas.drawPath(_arch(x, top, ww, wh), p);
    p.color = w.trim.withValues(alpha: w.night ? .5 : .35);
    canvas.drawRect(Rect.fromLTWH(x, top + wh - 2, ww, 2), p);
  }
}

/// University campus: a wide hall with a colonnade and a clock gable.
void _campus(Canvas canvas, Paint p, double bx, double h, _Palette w) {
  final r = Rect.fromLTWH(bx, _horizon - h, 168, h);
  _body(canvas, p, r, w);
  p.color = w.dome;
  final gable = Path()
    ..moveTo(bx - 8, _horizon - h)
    ..lineTo(bx + 84, _horizon - h - 34)
    ..lineTo(bx + 176, _horizon - h)
    ..close();
  canvas.drawPath(gable, p);
  p.color = w.trim;
  canvas.drawCircle(Offset(bx + 84, _horizon - h - 11), 8, p);
  _windows(canvas, p, bx + 16, _horizon - h + 26, 5, 30, 18, h - 40, w);
  p.color = w.stoneShade;
  canvas.drawRect(Rect.fromLTWH(bx, _horizon - 12, 168, 12), p);
}

/// Islamic bank / finance institution: dome, minarets, arched banking hall.
void _bank(Canvas canvas, Paint p, double bx, double h, _Palette w) {
  p.color = w.stoneShade;
  for (final mx in [bx + 4.0, bx + 150.0]) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(mx, _horizon - h - 52, 14, h + 52),
        const Radius.circular(6),
      ),
      p,
    );
  }
  p.color = w.trim;
  for (final mx in [bx + 11.0, bx + 157.0]) {
    canvas.drawCircle(Offset(mx, _horizon - h - 56), 9, p);
    canvas.drawRect(Rect.fromLTWH(mx - 9, _horizon - h - 30, 18, 3), p);
  }
  final r = Rect.fromLTWH(bx + 16, _horizon - h, 132, h);
  _body(canvas, p, r, w);
  _domeAndFinial(canvas, p, bx + 82, _horizon - h + 4, 76, 46, w);
  _windows(canvas, p, bx + 30, _horizon - h + 22, 4, 27, 17, h - 34, w);
  p.color = w.dome.withValues(alpha: .85);
  canvas.drawPath(_arch(bx + 68, _horizon - 46, 28, 46), p);
}

/// Hadith library: tall reading windows behind a stone screen.
void _library(Canvas canvas, Paint p, double bx, double h, _Palette w) {
  final r = Rect.fromLTWH(bx + 6, _horizon - h, 156, h);
  _body(canvas, p, r, w);
  p.color = w.dome;
  canvas.drawRect(Rect.fromLTWH(bx + 6, _horizon - h, 156, 11), p);
  for (var row = 0; row < 2; row++) {
    _windows(
      canvas,
      p,
      bx + 18,
      _horizon - h + 26 + row * (h * .45),
      6,
      24,
      15,
      h * .34,
      w,
    );
  }
  p.color = w.trim;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(bx + 74, _horizon - h - 22, 20, 24),
      const Radius.circular(6),
    ),
    p,
  );
}

/// Knowledge garden: low pavilions among cypress.
void _garden(Canvas canvas, Paint p, double bx, double h, _Palette w) {
  final r = Rect.fromLTWH(bx + 26, _horizon - h * .72, 116, h * .72);
  _body(canvas, p, r, w);
  _domeAndFinial(canvas, p, bx + 84, _horizon - h * .72 + 3, 64, 36, w);
  _windows(canvas, p, bx + 40, _horizon - h * .55, 3, 30, 18, h * .4, w);
  p.color = w.foliageDark;
  for (final cx in [bx + 8.0, bx + 158.0]) {
    canvas.drawPath(
      Path()
        ..moveTo(cx, _horizon)
        ..lineTo(cx + 11, _horizon - 96)
        ..lineTo(cx + 22, _horizon)
        ..close(),
      p,
    );
  }
}

/// Muamalat marketplace: striped awnings over an arcade.
void _bazaar(Canvas canvas, Paint p, double bx, double h, _Palette w) {
  final r = Rect.fromLTWH(bx, _horizon - h * .78, 172, h * .78);
  _body(canvas, p, r, w);
  _windows(canvas, p, bx + 14, _horizon - h * .62, 5, 30, 18, h * .4, w);
  for (var k = 0; k < 6; k++) {
    p.color = k.isEven ? w.dome : w.trim;
    final ax = bx + k * 29;
    canvas.drawPath(
      Path()
        ..moveTo(ax, _horizon - h * .78)
        ..lineTo(ax + 29, _horizon - h * .78)
        ..lineTo(ax + 24, _horizon - h * .78 - 22)
        ..lineTo(ax + 5, _horizon - h * .78 - 22)
        ..close(),
      p,
    );
  }
  p.color = w.stoneShade;
  canvas.drawRect(Rect.fromLTWH(bx, _horizon - 10, 172, 10), p);
}

/// Baitul Mal treasury / Ar-Rahn: a strongroom facade with a gold band.
void _treasury(Canvas canvas, Paint p, double bx, double h, _Palette w) {
  final r = Rect.fromLTWH(bx + 10, _horizon - h, 150, h);
  _body(canvas, p, r, w, radius: 12);
  p.color = w.trim;
  canvas.drawRect(Rect.fromLTWH(bx + 10, _horizon - h + 18, 150, 7), p);
  _domeAndFinial(canvas, p, bx + 85, _horizon - h + 2, 70, 40, w);
  _windows(canvas, p, bx + 26, _horizon - h + 40, 4, 32, 18, h - 58, w);
  p.color = w.dome;
  canvas.drawPath(_arch(bx + 70, _horizon - 52, 30, 52), p);
  p.color = w.trim;
  canvas.drawCircle(Offset(bx + 85, _horizon - 28), 5, p);
}

/// The Grand Vault observatory: a slit dome and a lantern that breathes.
void _observatory(
  Canvas canvas,
  Paint p,
  double bx,
  double h,
  double time,
  _Palette w,
) {
  final r = Rect.fromLTWH(bx + 18, _horizon - h, 136, h);
  _body(canvas, p, r, w, radius: 10);
  p.color = w.stoneLight;
  canvas.drawArc(
    Rect.fromLTWH(bx + 18, _horizon - h - 46, 136, 92),
    pi,
    pi,
    true,
    p,
  );
  p.color = w.skyTop;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(bx + 80, _horizon - h - 44, 12, 46),
      const Radius.circular(6),
    ),
    p,
  );
  final pulse = .72 + .28 * (sin(time * 1.8) * .5 + .5);
  p.shader = Gradient.radial(Offset(bx + 86, _horizon - h + 30), 46, [
    w.trim.withValues(alpha: .45 * pulse),
    const Color(0x00000000),
  ]);
  canvas.drawCircle(Offset(bx + 86, _horizon - h + 30), 46, p);
  p.shader = null;
  p.color = w.trim;
  canvas.drawCircle(Offset(bx + 86, _horizon - h + 30), 13 * pulse, p);
  _windows(canvas, p, bx + 32, _horizon - h + 58, 4, 30, 16, h - 76, w);
}

// ---------------------------------------------------------------------------
// Foreground planting
// ---------------------------------------------------------------------------

void _planting(
  Canvas canvas,
  Paint p,
  double width,
  double shift,
  double time,
  int level,
  _Palette w,
  double scale,
) {
  const spacing = 196.0;
  final offset = shift % spacing;
  for (var i = -1; i < width / spacing + 1; i++) {
    final bx = i * spacing - offset;
    final sway = sin(time * .9 + i) * 2.4;
    canvas.save();
    canvas.translate(bx, _horizon);
    canvas.scale(scale);
    if (level == 3) {
      _palm(canvas, p, sway, w);
    } else {
      _tree(canvas, p, sway, level, w);
    }
    canvas.restore();
  }
}

void _tree(Canvas canvas, Paint p, double sway, int level, _Palette w) {
  p.color = w.trunk;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, -78, 8, 80),
      const Radius.circular(4),
    ),
    p,
  );
  p.color = w.foliageDark;
  canvas.drawOval(Rect.fromLTWH(-28 + sway, -124, 64, 56), p);
  p.color = w.foliage;
  canvas.drawOval(Rect.fromLTWH(-21 + sway, -127, 51, 44), p);
  if (level == 2) {
    // The knowledge garden fruits; a small warm accent in the canopy.
    p.color = w.trim;
    for (var k = 0; k < 4; k++) {
      canvas.drawCircle(
        Offset(-10 + k * 12 + sway, -104 + sin(k * 2.1) * 11),
        3.2,
        p,
      );
    }
  }
}

void _palm(Canvas canvas, Paint p, double sway, _Palette w) {
  p.color = w.trunk;
  canvas.drawPath(
    Path()
      ..moveTo(0, 2)
      ..quadraticBezierTo(4, -56, 13 + sway, -108)
      ..lineTo(21 + sway, -106)
      ..quadraticBezierTo(11, -54, 8, 2)
      ..close(),
    p,
  );
  final top = Offset(17 + sway, -108);
  for (var k = 0; k < 6; k++) {
    final a = pi + k * (pi / 5.4);
    p.color = k.isEven ? w.foliageDark : w.foliage;
    final tip = Offset(top.dx + cos(a) * 48, top.dy + sin(a) * 31 + 9);
    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(
          (top.dx + tip.dx) / 2,
          min(top.dy, tip.dy) - 19,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          (top.dx + tip.dx) / 2,
          min(top.dy, tip.dy) - 6,
          top.dx,
          top.dy,
        )
        ..close(),
      p,
    );
  }
  p.color = w.trim;
  canvas.drawCircle(Offset(top.dx - 4, top.dy + 6), 3, p);
  canvas.drawCircle(Offset(top.dx + 5, top.dy + 9), 3, p);
}
