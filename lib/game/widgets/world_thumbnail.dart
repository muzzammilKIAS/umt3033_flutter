import 'package:flutter/material.dart';
import '../engine/avatar_art.dart';
import '../engine/course_geometry.dart';
import '../engine/environment_art.dart';
import '../engine/prop_art.dart';
import 'adventure_style.dart';

/// A world card header painted with the same scenery the level renders, so the
/// map promises exactly what the player is about to run through.
class WorldThumbnail extends StatelessWidget {
  final int level;
  final int avatar;
  final double height;
  const WorldThumbnail({
    super.key,
    required this.level,
    required this.avatar,
    this.height = 156,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _WorldPainter(level, avatar)),
  );
}

class _WorldPainter extends CustomPainter {
  final int level, avatar;
  _WorldPainter(this.level, this.avatar);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // Frame the band just above the horizon: skyline, planting and terrain.
    final scale = size.height / 215;
    canvas.scale(scale);
    canvas.translate(0, -270);
    final width = size.width / scale;
    drawEnvironment(canvas, width, 150, 2.4, level, 1);
    final pal = propsFor(level);
    drawGround(canvas, Rect.fromLTWH(0, CourseGeometry.floor, width, 90), pal);
    drawGem(canvas, width * .72, CourseGeometry.floor - 74, 2.4, 0);
    canvas.save();
    canvas.translate(width * .18, CourseGeometry.floor);
    drawAvatar(canvas, avatar, 2.4, true);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WorldPainter old) =>
      old.level != level || old.avatar != avatar;
}

/// The world number and title sit on the artwork, so the card reads as a place.
class WorldCard extends StatelessWidget {
  final int level;
  final int avatar;
  final int stars;
  final String title, zones;
  final Widget action;
  final String? best;
  const WorldCard({
    super.key,
    required this.level,
    required this.avatar,
    required this.stars,
    required this.title,
    required this.zones,
    required this.action,
    this.best,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: navy.withValues(alpha: .07)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: .07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              WorldThumbnail(level: level, avatar: avatar),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        navy.withValues(alpha: .74),
                        navy.withValues(alpha: .16),
                        Colors.transparent,
                      ],
                      stops: const [0, .55, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 22,
                top: 20,
                right: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'WORLD 0$level',
                          style: const TextStyle(
                            color: gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 2.4,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          children: List.generate(
                            3,
                            (i) => Icon(
                              i < stars
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 16,
                              color: i < stars
                                  ? gold
                                  : cream.withValues(alpha: .45),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: cream,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zones,
                  style: const TextStyle(height: 1.6, color: Color(0xFF5B7280)),
                ),
                if (best != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.military_tech_rounded,
                        size: 17,
                        color: emerald,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        best!,
                        style: const TextStyle(
                          color: emerald,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                action,
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
