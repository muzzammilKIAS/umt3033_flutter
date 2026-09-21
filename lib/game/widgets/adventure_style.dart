import 'package:flutter/material.dart';
import '../engine/avatar_art.dart';

const navy = Color(0xFF102D3D);
const emerald = Color(0xFF167F70);
const gold = Color(0xFFF0C56B);
const cream = Color(0xFFF7F3E9);
const sky = Color(0xFFC6E5EA);

ThemeData adventureTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  scaffoldBackgroundColor: cream,
  colorScheme: ColorScheme.fromSeed(
    seedColor: emerald,
    primary: emerald,
    secondary: gold,
    surface: cream,
    onSurface: navy,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: cream,
    foregroundColor: navy,
    elevation: 0,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: navy,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  ),
);

class GameFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  const GameFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });
  @override
  Widget build(BuildContext context) => Theme(
    data: adventureTheme(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          actions: actions,
        ),
        body: SafeArea(child: child),
      ),
    ),
  );
}

class AdventureCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  const AdventureCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(24),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: navy.withValues(alpha: .06)),
      boxShadow: [
        BoxShadow(
          color: navy.withValues(alpha: .04),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

class ArabicText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  const ArabicText(this.text, {super.key, this.size = 32, this.color = navy});
  @override
  Widget build(BuildContext context) => Text(
    text,
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.right,
    style: TextStyle(
      fontFamily: 'Amiri',
      fontSize: size,
      height: 1.9,
      color: color,
    ),
  );
}

class AvatarBadge extends StatelessWidget {
  final int avatar;
  final double size;
  const AvatarBadge(this.avatar, {super.key, this.size = 52});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: sky.withValues(alpha: .6),
      borderRadius: BorderRadius.circular(size / 3),
    ),
    child: CustomPaint(painter: AvatarPainter(avatar)),
  );
}

class AvatarPainter extends CustomPainter {
  final int avatar;
  AvatarPainter(this.avatar);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height * .86);
    canvas.scale(size.height / 70);
    drawAvatar(canvas, avatar, 0, false);
    canvas.restore();
  }

  @override
  bool shouldRepaint(AvatarPainter oldDelegate) => avatar != oldDelegate.avatar;
}
