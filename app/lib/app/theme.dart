import 'package:flutter/material.dart';

/// Design tokens from "Friendly everyday" (Design B).
abstract final class AppColors {
  static const canvas = Color(0xFFFFF8F0);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF26211F);
  static const secondaryInk = Color(0xFF514742);
  static const primary = Color(0xFFAD3E13);
  static const onPrimary = Color(0xFFFFFFFF);
  static const peach = Color(0xFFFFD9C2);
  static const lavender = Color(0xFFEAD9F3);
  static const sage = Color(0xFFC8D39B);
  static const outline = Color(0xFFD4C0B3);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppRadius {
  static const card = 16.0;
  static const sheet = 24.0;
  static const pill = 999.0;
}

/// Minimum tap target from the design tokens.
const double minimumTouchTarget = 48;

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.peach,
    onPrimaryContainer: AppColors.ink,
    secondaryContainer: AppColors.peach,
    onSecondaryContainer: AppColors.ink,
    tertiaryContainer: AppColors.lavender,
    onTertiaryContainer: AppColors.ink,
    surface: AppColors.canvas,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.secondaryInk,
    surfaceContainerLowest: AppColors.surface,
    outline: AppColors.outline,
    outlineVariant: AppColors.outline,
  );

  // No fontFamily: use the platform's system font, which covers Japanese
  // without bundling a font.
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.outline),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.canvas,
      indicatorColor: AppColors.peach,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
    ),
  );
}
