import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'design_tokens.dart';
import 'theme_presets.dart';

/// Design system POS: Material 3, palet dinamis dari preset, light & dark mode.
class AppTheme {
  const AppTheme._();

  // Warna semantik status (satu sumber kebenaran).
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  /// Membangun ThemeData untuk preset tertentu.
  static ThemeData build({
    required ThemePreset preset,
    required Brightness brightness,
  }) {
    final scheme = _colorScheme(preset, brightness);

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
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh.withValues(alpha: 0.4),
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
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: AppSpacing.lg,
      ),
      textTheme: base.textTheme.apply(fontFamilyFallback: const ['Inter']),
    );
  }

  /// Membangun ColorScheme dari preset tema.
  static ColorScheme _colorScheme(ThemePreset preset, Brightness brightness) {
    // Untuk preset yang default-nya dark (seperti midnight), kita tetap generate
    // light/dark scheme berdasarkan brightness yang diminta.
    return ColorScheme.fromSeed(
      seedColor: preset.seedColor,
      brightness: brightness,
      secondary: preset.secondary,
      tertiary: preset.tertiary,
      // Error color konsisten di semua preset
      error: error,
      // Surface tint dari preset
      surfaceTint: brightness == Brightness.light
          ? preset.surfaceTint
          : preset.surfaceTint.withValues(alpha: 0.12),
    );
  }

  /// Legacy: build light theme dengan preset default (forest).
  static ThemeData light() => build(preset: AppThemePresets.defaultPreset, brightness: Brightness.light);

  /// Legacy: build dark theme dengan preset default (forest).
  static ThemeData dark() => build(preset: AppThemePresets.defaultPreset, brightness: Brightness.dark);
}

/// Provider untuk preset tema aktif (Riverpod).
final themePresetProvider = StateProvider<ThemePreset>((ref) {
  return AppThemePresets.defaultPreset;
});

/// Provider untuk ThemeData light berdasarkan preset aktif.
final lightThemeProvider = Provider<ThemeData>((ref) {
  final preset = ref.watch(themePresetProvider);
  return AppTheme.build(preset: preset, brightness: Brightness.light);
});

/// Provider untuk ThemeData dark berdasarkan preset aktif.
final darkThemeProvider = Provider<ThemeData>((ref) {
  final preset = ref.watch(themePresetProvider);
  return AppTheme.build(preset: preset, brightness: Brightness.dark);
});

/// Provider untuk ThemeMode (system/light/dark).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Ekstensi warna semantik agar widget tidak hardcode warna.
extension SemanticColors on ColorScheme {
  Color get semanticSuccess => AppTheme.success;
  Color get semanticWarning => AppTheme.warning;
  Color get semanticError => AppTheme.error;
  Color get semanticInfo => AppTheme.info;
}