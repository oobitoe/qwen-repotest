import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi Supabase.
///
/// Membaca `SUPABASE_URL` dan `SUPABASE_ANON_KEY` dari berkas `.env`
/// (tidak di-commit, ada di `.gitignore`).
///
/// Tidak ada secret yang disimpan di source code. Hanya anon/public key
/// yang boleh dipakai di klien; service_role key tidak pernah disertakan.
class SupabaseConfig {
  const SupabaseConfig._();

  static bool _initialized = false;

  /// Baca kunci dari berkas .env secara manual (tanpa mengandalkan
  /// internal state flutter_dotenv).
  static (String, String)? _readEnv() {
    final candidates = <String>[
      '.env',
      '${Directory.current.path}/.env',
      '${Directory(Directory.current.path).parent.path}/.env',
    ];

    for (final candidate in candidates) {
      try {
        final f = File(candidate);
        if (!f.existsSync()) continue;

        String? url;
        String? anonKey;
        for (final line in f.readAsLinesSync()) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          final eq = trimmed.indexOf('=');
          if (eq <= 0) continue;
          final key = trimmed.substring(0, eq).trim();
          final value = trimmed.substring(eq + 1).trim();
          if (key == 'SUPABASE_URL') url = value;
          if (key == 'SUPABASE_ANON_KEY') anonKey = value;
        }

        if (url != null && anonKey != null && url.isNotEmpty && anonKey.isNotEmpty) {
          return (url, anonKey);
        }
      } catch (_) {
        // Coba kandidat berikutnya
      }
    }

    return null;
  }

  /// Inisialisasi SDK Supabase dari berkas .env.
  ///
  /// Aman dipanggil saat kredensial belum dikonfigurasi:
  /// aplikasi tetap jalan penuh dalam mode offline-only.
  static Future<bool> initialize() async {
    final env = _readEnv();
    if (env == null) {
      debugPrint(
        'Supabase belum dikonfigurasi — menjalankan mode offline-only. '
        'Isi SUPABASE_URL & SUPABASE_ANON_KEY di file .env.',
      );
      _initialized = false;
      return false;
    }

    await Supabase.initialize(url: env.$1, publishableKey: env.$2);
    _initialized = true;
    debugPrint('🏴‍☠️ Supabase TERHUBUNG ke awan — mode online aktif.');
    return true;
  }

  /// True bila SDK sudah diinisialisasi dan kredensial valid.
  static bool get isValid => _initialized;

  /// Client Supabase siap pakai (null bila belum diinisialisasi).
  static SupabaseClient? get client {
    if (!_initialized) return null;
    return Supabase.instance.client;
  }
}
