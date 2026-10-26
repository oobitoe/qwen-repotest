import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi Supabase. Nilai dibaca dari environment (dart-define / .env),
/// TIDAK ADA secret di source code. Hanya anon/public key yang boleh dipakai
/// di klien; service_role key tidak pernah disertakan.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  /// True bila konfigurasi valid — aplikasi dapat berjalan offline tanpa ini.
  bool get isValid =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      Uri.tryParse(url)?.hasAbsolutePath == true;

  static const envUrl = String.fromEnvironment('SUPABASE_URL');
  static const envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const SupabaseConfig instance =
      SupabaseConfig(url: envUrl, anonKey: envAnonKey);

  /// Inisialisasi SDK. Aman dipanggil saat kredensial belum dikonfigurasi:
  /// aplikasi tetap jalan penuh dalam mode offline-only.
  static Future<bool> initialize() async {
    if (!instance.isValid) {
      debugPrint(
        'Supabase belum dikonfigurasi — menjalankan mode offline-only. '
        'Set SUPABASE_URL & SUPABASE_ANON_KEY via --dart-define.',
      );
      return false;
    }
    await Supabase.initialize(url: instance.url, anonKey: instance.anonKey);
    return true;
  }

  static SupabaseClient? get client {
    if (!instance.isValid || !Supabase.instance.isInitialized) return null;
    return Supabase.instance.client;
  }
}
