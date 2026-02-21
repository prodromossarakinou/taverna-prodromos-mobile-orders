import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryContainer = Color(0xFF1D4ED8);

  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color onSurfaceLight = Color(0xFF111827);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color outlineLight = Color(0xFFE2E8F0);
  static const Color errorLight = Color(0xFFDC2626);
  static const Color successLight = Color(0xFF16A34A);

  static const Color primaryDark = Color(0xFF3B82F6);
  static const Color primaryContainerDark = Color(0xFF1E40AF);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color surfaceVariantDark = Color(0xFF111827);
  static const Color outlineDark = Color(0xFF374151);
  static const Color errorDark = Color(0xFFEF4444);
  static const Color successDark = Color(0xFF10B981);

  static const Color muted = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray700 = Color(0xFF374151);

  static const Color cold = Color(0xFF10B981);
  static const Color hot = Color(0xFFF97316);
  static const Color grill = Color(0xFFEF4444);
  static const Color cooked = Color(0xFFA855F7);
  static const Color drinks = Color(0xFF3B82F6);
}

List<Color> appHeaderGradient({required bool isDark}) {
  return isDark
      ? const [Color(0xFF1E3A8A), Color(0xFF172554)]
      : const [Color(0xFF1D4ED8), Color(0xFF1E3A8A)];
}

class AppPalette {
  const AppPalette({
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceContainer,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.outline,
    required this.success,
    required this.error,
  });

  final Color surface;
  final Color surfaceVariant;
  final Color surfaceContainer;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color outline;
  final Color success;
  final Color error;

  static AppPalette of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppPalette(
      surface: scheme.surface,
      surfaceVariant: scheme.surfaceContainerHighest,
      surfaceContainer: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
      onSurface: scheme.onSurface,
      onSurfaceMuted: scheme.onSurface.withValues(alpha: 0.70),
      outline: scheme.outline,
      success: isDark ? AppColors.successDark : AppColors.successLight,
      error: isDark ? AppColors.errorDark : AppColors.errorLight,
    );
  }
}

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.onSurfaceLight,
      surfaceContainerHighest: AppColors.surfaceVariantLight,
      outline: AppColors.outlineLight,
      error: AppColors.errorLight,
    ),
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainerDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      surfaceContainerHighest: AppColors.surfaceVariantDark,
      outline: AppColors.outlineDark,
      error: AppColors.errorDark,
    ),
  );
}
