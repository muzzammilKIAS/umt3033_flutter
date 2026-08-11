import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Semantic surface/text/border tokens that differ between light and dark,
/// exposed via [Theme.of(context).extension] so widgets never hard-code a
/// brightness-specific literal.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final Color mist;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color champagne;
  final Color heroGradientStart;
  final Color heroGradientEnd;

  const AppTokens({
    required this.mist,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.champagne,
    required this.heroGradientStart,
    required this.heroGradientEnd,
  });

  static const light = AppTokens(
    mist: AppColors.mistBackground,
    card: AppColors.surfaceLight,
    border: AppColors.borderLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    champagne: AppColors.mutedChampagne,
    heroGradientStart: AppColors.primaryDeepTeal,
    heroGradientEnd: AppColors.primaryDark,
  );

  static const dark = AppTokens(
    mist: AppColors.backgroundDark,
    card: AppColors.surfaceDark,
    border: AppColors.borderDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    champagne: AppColors.mutedChampagneDark,
    heroGradientStart: AppColors.elevatedSurfaceDark,
    heroGradientEnd: AppColors.backgroundDark,
  );

  @override
  AppTokens copyWith({
    Color? mist,
    Color? card,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? champagne,
    Color? heroGradientStart,
    Color? heroGradientEnd,
  }) {
    return AppTokens(
      mist: mist ?? this.mist,
      card: card ?? this.card,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      champagne: champagne ?? this.champagne,
      heroGradientStart: heroGradientStart ?? this.heroGradientStart,
      heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      mist: Color.lerp(mist, other.mist, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      champagne: Color.lerp(champagne, other.champagne, t)!,
      heroGradientStart: Color.lerp(
        heroGradientStart,
        other.heroGradientStart,
        t,
      )!,
      heroGradientEnd: Color.lerp(heroGradientEnd, other.heroGradientEnd, t)!,
    );
  }
}

extension AppTokensX on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDeepTeal,
      brightness: Brightness.light,
      primary: AppColors.primaryDeepTeal,
      secondary: AppColors.secondarySage,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
    );
    return _base(scheme, AppTokens.light, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryTealDark,
      brightness: Brightness.dark,
      primary: AppColors.primaryTealDark,
      secondary: AppColors.softTealDark,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
    );
    return _base(scheme, AppTokens.dark, Brightness.dark);
  }

  static ThemeData _base(
    ColorScheme scheme,
    AppTokens tokens,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.mist,
      fontFamily: 'Inter',
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.mist,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: tokens.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tokens.border, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.border, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          side: BorderSide(color: tokens.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.mist,
        selectedColor: scheme.primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(color: tokens.textPrimary, fontSize: 12),
        side: BorderSide(color: tokens.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.card,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : tokens.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : tokens.textSecondary,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: tokens.textSecondary,
        indicatorColor: scheme.primary,
        dividerColor: tokens.border,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.textPrimary,
        contentTextStyle: TextStyle(color: tokens.mist),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
        side: BorderSide(color: tokens.border, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : tokens.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary.withValues(alpha: 0.4)
              : tokens.border,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.12),
      ),
    );
  }
}
