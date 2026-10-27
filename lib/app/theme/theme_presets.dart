import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Theme presets menggunakan OKLCH color space untuk palet yang konsisten dan modern.
/// Setiap preset mendefinisikan seedColor (primary), secondary, tertiary, dan surface tint.
class AppThemePresets {
  const AppThemePresets._();

  /// Daftar semua preset tema yang tersedia.
  static const List<ThemePreset> presets = [
    _ocean,
    _forest,
    _sunset,
    _sakura,
    _cottonCandy,
    _midnight,
    _inferno,
  ];

  /// Preset default (digunakan saat pertama kali aplikasi dijalankan).
  static const ThemePreset defaultPreset = _forest;

  /// Mendapatkan preset berdasarkan ID.
  static ThemePreset? getById(String id) {
    try {
      return presets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Ocean — Biru laut dalam, profesional & tenang.
  static const ThemePreset _ocean = ThemePreset(
    id: 'ocean',
    name: 'Ocean',
    description: 'Biru laut dalam — profesional & tenang',
    seedColor: Color(0xFF0369A1), // OKLCH: 0.55 0.15 240
    secondary: Color(0xFF0891B2), // Cyan
    tertiary: Color(0xFF0E7490), // Teal-blue
    surfaceTint: Color(0xFFE0F2FE), // Light blue tint
  );

  /// Forest — Hijau hutan, seimbang & natural (DEFAULT).
  static const ThemePreset _forest = ThemePreset(
    id: 'forest',
    name: 'Forest',
    description: 'Hijau hutan — seimbang & natural',
    seedColor: Color(0xFF166534), // OKLCH: 0.45 0.12 145
    secondary: Color(0xFF15803D), // Green-700
    tertiary: Color(0xFF0F766E), // Teal-700
    surfaceTint: Color(0xFFDCFCE7), // Light green tint
  );

  /// Sunset — Oranye-merah hangat, energik.
  static const ThemePreset _sunset = ThemePreset(
    id: 'sunset',
    name: 'Sunset',
    description: 'Oranye-merah hangat — energik & semangat',
    seedColor: Color(0xFFEA580C), // OKLCH: 0.65 0.18 40
    secondary: Color(0xFFF97316), // Orange-500
    tertiary: Color(0xFFDC2626), // Red-600
    surfaceTint: Color(0xFFFFEDD5), // Light orange tint
  );

  /// Sakura — Pink lembut, elegan & modern.
  static const ThemePreset _sakura = ThemePreset(
    id: 'sakura',
    name: 'Sakura',
    description: 'Pink lembut — elegan & modern',
    seedColor: Color(0xFFDB2777), // OKLCH: 0.60 0.18 340
    secondary: Color(0xFFEC4899), // Pink-500
    tertiary: Color(0xFFC026D3), // Fuchsia-600
    surfaceTint: Color(0xFFFCE7F3), // Light pink tint
  );

  /// Cotton Candy — Pastel ungu-pink, manis & lembut.
  static const ThemePreset _cottonCandy = ThemePreset(
    id: 'cottonCandy',
    name: 'Cotton Candy',
    description: 'Pastel ungu-pink — manis & lembut',
    seedColor: Color(0xFFA855F7), // OKLCH: 0.55 0.18 280
    secondary: Color(0xFFD946EF), // Fuchsia-400
    tertiary: Color(0xFFEC4899), // Pink-500
    surfaceTint: Color(0xFFFAF5FF), // Light purple tint
  );

  /// Midnight — Gelap premium, minimalis & mewah.
  static const ThemePreset _midnight = ThemePreset(
    id: 'midnight',
    name: 'Midnight',
    description: 'Gelap premium — minimalis & mewah',
    seedColor: Color(0xFF312E81), // OKLCH: 0.35 0.12 270
    secondary: Color(0xFF4338CA), // Indigo-700
    tertiary: Color(0xFF1E1E2E), // Near black
    surfaceTint: Color(0xFF1E1E2E), // Dark surface
    isDarkDefault: true,
  );

  /// Inferno — Merah gelap intens, berani & kuat.
  static const ThemePreset _inferno = ThemePreset(
    id: 'inferno',
    name: 'Inferno',
    description: 'Merah gelap intens — berani & kuat',
    seedColor: Color(0xFF991B1B), // OKLCH: 0.45 0.15 25
    secondary: Color(0xFFB91C1C), // Red-700
    tertiary: Color(0xFF7F1D1D), // Red-900
    surfaceTint: Color(0xFFFEF2F2), // Light red tint
  );
}

/// Definisi satu preset tema.
class ThemePreset {
  const ThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.seedColor,
    required this.secondary,
    required this.tertiary,
    required this.surfaceTint,
    this.isDarkDefault = false,
  });

  final String id;
  final String name;
  final String description;
  final Color seedColor;
  final Color secondary;
  final Color tertiary;
  final Color surfaceTint;
  final bool isDarkDefault;

  /// Membangun ThemeData untuk light mode.
  ThemeData lightTheme() {
    return AppTheme.build(preset: this, brightness: Brightness.light);
  }

  /// Membangun ThemeData untuk dark mode.
  ThemeData darkTheme() {
    return AppTheme.build(preset: this, brightness: Brightness.dark);
  }
}

/// Extension untuk memudahkan akses preset dari context.
extension ThemePresetExtension on BuildContext {
  /// Mendapatkan preset aktif dari provider (perlu ThemePresetProvider).
  ThemePreset get activeThemePreset => _defaultPreset;

  static const ThemePreset _defaultPreset = AppThemePresets.defaultPreset;
}

/// Provider state untuk preset tema aktif.
class ThemePresetNotifier extends ValueNotifier<ThemePreset> {
  ThemePresetNotifier() : super(AppThemePresets.defaultPreset);

  void setPreset(String presetId) {
    final preset = AppThemePresets.getById(presetId);
    if (preset != null) {
      value = preset;
    }
  }

  void setPresetByValue(ThemePreset preset) {
    value = preset;
  }
}

/// Semantic color extensions untuk theme presets.
extension ThemePresetColors on ThemePreset {
  Color get success => const Color(0xFF16A34A);
  Color get warning => const Color(0xFFF59E0B);
  Color get error => const Color(0xFFDC2626);
  Color get info => const Color(0xFF0EA5E9);
}