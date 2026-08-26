import 'package:flutter/material.dart';

/// Design tokens for the "Futura" violet/pink dashboard look: soft
/// lavender surfaces, a deep violet primary, and a magenta/pink accent,
/// with a cyan accent reserved for tertiary chart/legend use.
class AppColors {
  AppColors._();

  // ---- Light palette ----
  static const Color primaryDeepTeal = Color(0xFF5B3FBF);
  static const Color primaryDark = Color(0xFF3F2A8C);
  static const Color secondarySage = Color(0xFFEC5FB0);
  static const Color softSage = Color(0xFFD9CCF5);
  static const Color veryLightSage = Color(0xFFEFE8FC);
  static const Color mistBackground = Color(0xFFF6F3FC);
  static const Color warmIvory = Color(0xFFFBFAFE);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF241B3A);
  static const Color textSecondaryLight = Color(0xFF7A7291);
  static const Color borderLight = Color(0xFFE7E1F5);
  static const Color mutedChampagne = Color(0xFF5FD8D0);
  static const Color veryLightChampagne = Color(0xFFE1F8F6);

  // ---- Dark palette ----
  static const Color backgroundDark = Color(0xFF150F29);
  static const Color surfaceDark = Color(0xFF1F1638);
  static const Color elevatedSurfaceDark = Color(0xFF281C47);
  static const Color primaryTealDark = Color(0xFF9D7FFF);
  static const Color softTealDark = Color(0xFFFF7AC6);
  static const Color textPrimaryDark = Color(0xFFF1EDFF);
  static const Color textSecondaryDark = Color(0xFFB6AAD9);
  static const Color borderDark = Color(0xFF362A5C);
  static const Color mutedChampagneDark = Color(0xFF6FE0D9);

  // ---- Semantic (shared) ----
  static const Color success = Color(0xFF2D9E6F);
  static const Color error = Color(0xFFE23E57);
  static const Color warning = Color(0xFFC8862E);
}
