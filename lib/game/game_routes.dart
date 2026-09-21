import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/room_screen.dart';
import 'screens/solo_play_route.dart';

Route<dynamic>? adventureRoute(RouteSettings settings) {
  final uri = Uri.tryParse(settings.name ?? '');
  if (uri == null || !uri.path.startsWith('/game')) return null;
  final Widget screen = switch (uri.path) {
    '/game/solo' => const SoloScreen(),
    '/game/play' => SoloPlayRoute(
      level: (int.tryParse(uri.queryParameters['level'] ?? '') ?? 1).clamp(
        1,
        5,
      ),
      avatar: (int.tryParse(uri.queryParameters['avatar'] ?? '') ?? 0).clamp(
        0,
        3,
      ),
    ),
    '/game/host' => RoomScreen(host: true, code: uri.queryParameters['room']),
    '/game/join' ||
    '/game/lobby' => RoomScreen(code: uri.queryParameters['room']),
    _ => const AdventureHomeScreen(),
  };
  return MaterialPageRoute(settings: settings, builder: (_) => screen);
}
