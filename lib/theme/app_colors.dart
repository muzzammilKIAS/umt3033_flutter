import 'package:flutter/material.dart';

/// Design tokens for the "premium digital university Arabic textbook" look:
/// deep teal + sage + mist/ivory, with a restrained champagne accent.
/// No orange/brown/cocoa anywhere in the app -- see docs/OVERNIGHT_WORKLOG.md.
class AppColors {
  AppColors._();

  // ---- Light palette ----
  static const Color primaryDeepTeal = Color(0xFF164E4A);
  static const Color primaryDark = Color(0xFF103B38);
  static const Color secondarySage = Color(0xFF789C94);
  static const Color softSage = Color(0xFFAFC5BF);
  static const Color veryLightSage = Color(0xFFE5EFEC);
  static const Color mistBackground = Color(0xFFF3F7F6);
  static const Color warmIvory = Color(0xFFFAFBF8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF203331);
  static const Color textSecondaryLight = Color(0xFF5D706D);
  static const Color borderLight = Color(0xFFD5E1DE);
  static const Color mutedChampagne = Color(0xFFB7A46A);
  static const Color veryLightChampagne = Color(0xFFF2EEDC);

  // ---- Dark palette ----
  static const Color backgroundDark = Color(0xFF0D1C1B);
  static const Color surfaceDark = Color(0xFF132624);
  static const Color elevatedSurfaceDark = Color(0xFF19302D);
  static const Color primaryTealDark = Color(0xFF74A79E);
  static const Color softTealDark = Color(0xFF96BBB4);
  static const Color textPrimaryDark = Color(0xFFECF4F2);
  static const Color textSecondaryDark = Color(0xFFA9BFBA);
  static const Color borderDark = Color(0xFF294440);
  static const Color mutedChampagneDark = Color(0xFFB8A873);

  // ---- Semantic (shared) ----
  static const Color success = Color(0xFF2D6A4F);
  static const Color error = Color(0xFFB3261E);
  static const Color warning = Color(0xFF8A6D1E);
}
