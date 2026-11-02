library pocketbase_client;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton klien PocketBase. Gunakan [instance] di seluruh aplikasi.
class PocketBaseClient {
  PocketBaseClient._();

  static PocketBase? _instance;
  static PocketBaseClient? _client;

  static const String _pbTokenKey = 'pb_auth_token';
  static const String _pbLoginStatusKey = 'pb_login_status';

  /// Instance klien PocketBase (buat sekali, gunakan ulang).
  static PocketBase get instance {
    _instance ??= _createClient();
    return _instance!;
  }

  /// Instance wrapper PocketBaseClient (akses method auth: healthCheck, registerUser, loginUser, logout).
  static PocketBaseClient get client {
    _client ??= PocketBaseClient._();
    return _client!;
  }

  static PocketBase _createClient() {
    final baseUrl = dotenv.isInitialized
        ? (dotenv.maybeGet('POCKETBASE_URL') ?? 'http://127.0.0.1:8090')
        : 'http://127.0.0.1:8090';
    return PocketBase(baseUrl);
  }

  /// Paksa membuat instance baru (berguna pada pengujian atau ganti server).
  static void reset() {
    _instance = null;
  }

  /// Base URL server PocketBase.
  String get baseUrl => _instance!.baseUrl;

  /// Cek apakah server PocketBase reachable (online).
  /// Coba ambil 1 record dari koleksi `users`.
  /// Bila server online return true, bila offline return false.
  Future<bool> healthCheck() async {
    try {
      await instance.collection('users').getList(page: 1, perPage: 1);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Daftarkan user baru ke PocketBase collection `users`.
  /// Return `RecordModel` yang berisi `id`, `email`, dll.
  Future<RecordModel> registerUser({
    required String email,
    required String password,
    required String name,
    String? businessId, // Bisnis yang memiliki user ini (multi-business)
    String? storeId, // Toko yang memiliki user ini (multi-store)
  }) async {
    final record = await _instance!
        .collection('users')
        .create(body: {
          'email': email,
          'password': password,
          'passwordConfirm': password,
          'name': name,
          'emailVisibility': true,
          if (businessId != null) 'businessId': businessId,
          if (storeId != null) 'storeId': storeId,
        });
    return record;
  }

  /// Login user ke PocketBase via email + password.
  /// Token otomatis tersimpan di `authStore` oleh SDK dan di-persist ke SharedPreferences.
  /// Juga menyimpan status login = 1 agar bisa diverifikasi saat login offline.
  /// Return `RecordModel` user yang login.
  Future<RecordModel> loginUser({
    required String email,
    required String password,
  }) async {
    final authData = await _instance!
        .collection('users')
        .authWithPassword(email, password);
    final record = authData.record;
    if (record == null) {
      throw Exception('Login berhasil tapi tidak menerima data user dari server.');
    }
    // Persist token dan status login agar bisa login offline
    await persistToken(_instance?.authStore.token);
    await persistLoginStatus(true);
    return record;
  }

  /// Simpan token ke SharedPreferences (untuk login offline).
  static Future<void> persistToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_pbTokenKey, token);
    } else {
      await prefs.remove(_pbTokenKey);
    }
  }

  /// Muat token dari SharedPreferences.
  static Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pbTokenKey);
  }

  /// Cek apakah ada token yang disimpan di SharedPreferences (untuk login offline).
  static Future<bool> hasStoredToken() async {
    final token = await loadToken();
    return token != null && token.isNotEmpty;
  }

  /// Simpan status login ke SharedPreferences (1 = login, 0 = logout).
  static Future<void> persistLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pbLoginStatusKey, isLoggedIn ? 1 : 0);
  }

  /// Cek status login dari SharedPreferences (1 = login, 0 = logout).
  static Future<bool> isLoggedInStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pbLoginStatusKey) == 1;
  }

  /// Ambil token autentikasi saat ini (jika ada).
  String? get currentToken => _instance?.authStore.token;

  /// Cek apakah user sudah ter-autentikasi (token masih valid).
  bool get isAuthenticated => _instance?.authStore.isValid ?? false;

  /// Keluar — set login = 0, **jangan hapus token** (biarkan expired sendiri 1 minggu).
  Future<void> logout() async {
    await _instance?.collection('users').authRefresh();
    _instance?.authStore.clear();
    await persistLoginStatus(false);
  }
}
