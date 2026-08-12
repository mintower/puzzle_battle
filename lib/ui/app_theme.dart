import 'package:flutter/material.dart';

/// The app's single source of visual truth: a light, minimal theme built
/// around the same indigo used in the picture-mode artwork (see
/// puzzle_artwork.dart), with flat buttons, soft filled inputs, and
/// borders instead of shadows for a calmer, more premium feel than the
/// stock Material 3 defaults.
class AppTheme {
  AppTheme._();

  static const seedColor = Color(0xFF4F46E5);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);
    final radius = BorderRadius.circular(14);

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8F8FC),
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF8F8FC),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
    );
  }
}
