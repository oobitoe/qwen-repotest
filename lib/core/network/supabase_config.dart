import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi Supabase.
///
/// Kosong sengaja — bos akan mengisi konfigurasi koneksi sendiri dari awal.
/// Tidak ada pemuatan .env otomatis di sini.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  bool get isValid =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      Uri.tryParse(url)?.hasAbsolutePath == true;

  static bool _initialized = false;

  static Future<bool> initialize(String url, String anonKey) async {
    await Supabase.initialize(url: url, publishableKey: anonKey);
    _initialized = true;
    return true;
  }

  static SupabaseClient? get client {
    if (!_initialized) return null;
    return Supabase.instance.client;
  }
}
