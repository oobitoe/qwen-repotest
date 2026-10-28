import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi Supabase. Nilai dibaca dari file .env via flutter_dotenv,
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

  static SupabaseConfig _fromEnv() {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    return SupabaseConfig(url: url, anonKey: anonKey);
  }

  static SupabaseConfig get instance => _fromEnv();

  static bool _initialized = false;

  /// Inisialisasi SDK. Aman dipanggil saat kredensial belum dikonfigurasi:
  /// aplikasi tetap jalan penuh dalam mode offline-only.
  static Future<bool> initialize() async {
    if (!instance.isValid) {
      debugPrint(
        'Supabase belum dikonfigurasi — menjalankan mode offline-only. '
        'Isi SUPABASE_URL & SUPABASE_ANON_KEY di file .env.',
      );
      return false;
    }
    await Supabase.initialize(
      url: instance.url,
      publishableKey: instance.anonKey,
    );
    _initialized = true;
    return true;
  }

  static SupabaseClient? get client {
    if (!instance.isValid || !_initialized) return null;
    return Supabase.instance.client;
  }
}
