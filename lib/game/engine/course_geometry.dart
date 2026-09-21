import 'dart:ui';
import 'dart:math';

class CourseGeometry {
  static const floor = 450.0;
  static const segment = 1100.0;
  final int gates;
  CourseGeometry(this.gates);
  double get length => gates * segment + 400;
  double gateX(int index) => (index + 1) * segment;
  double respawnX(int checkpoint) => checkpoint * segment + 60;
  List<Rect> platforms(int index, double time) {
    final x = index * segment;
    return [
      Rect.fromLTWH(x, floor, 610, 100),
      // A moving bridge offers a second route across the gap.
      Rect.fromLTWH(x + 643 + sin(time * 1.5) * 18, floor - 52, 50, 14),
      Rect.fromLTWH(x + 730, floor, 370, 100),
      Rect.fromLTWH(x + 300, floor - 76, 125, 16),
      Rect.fromLTWH(x + 495, floor - 115, 105, 16),
    ];
  }
}
