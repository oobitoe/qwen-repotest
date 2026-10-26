import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Design system POS: Material 3, palet indigo/teal, light & dark mode.
class AppTheme {
  const AppTheme._();

  // Warna semantik status (satu sumber kebenaran).
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5), // indigo modern
      brightness: brightness,
      secondary: const Color(0xFF0D9488), // teal
      error: error,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh.withOpacity(0.4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withOpacity(0.5),
        space: AppSpacing.lg,
      ),
      textTheme: base.textTheme.apply(fontFamilyFallback: const ['Inter']),
    );
  }
}

/// Ekstensi warna semantik agar widget tidak hardcode warna.
extension SemanticColors on ColorScheme {
  Color get semanticSuccess => AppTheme.success;
  Color get semanticWarning => AppTheme.warning;
  Color get semanticError => AppTheme.error;
  Color get semanticInfo => AppTheme.info;
}
