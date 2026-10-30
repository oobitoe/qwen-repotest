library pocketbase_client;

/// Konfigurasi dan klien PocketBase sebagai singleton.
///
/// Server PocketBase harus sudah berjalan (default: http://127.0.0.1:8090).
/// URL diambil dari environment variabel `POCKETBASE_URL` via `flutter_dotenv`.
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pocketbase/pocketbase.dart';

/// Singleton klien PocketBase. Gunakan [instance] di seluruh aplikasi.
class PocketBaseClient {
  PocketBaseClient._();

  static PocketBase? _instance;

  /// Instance klien PocketBase (buat sekali, gunakan ulang).
  static PocketBase get instance {
    _instance ??= _createClient();
    return _instance!;
  }

  static PocketBase _createClient() {
    final baseUrl = dotenv.env['POCKETBASE_URL'] ?? 'http://127.0.0.1:8090';
    return PocketBase(baseUrl);
  }

  /// Paksa membuat instance baru (berguna pada pengujian atau ganti server).
  static void reset() {
    _instance = null;
  }
}
