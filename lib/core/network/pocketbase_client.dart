library pocketbase_client;

import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pocketbase/pocketbase.dart';

/// Singleton klien PocketBase. Gunakan [instance] di seluruh aplikasi.
class PocketBaseClient {
  PocketBaseClient._();

  static PocketBase? _instance;
  static PocketBaseClient? _client;

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
  /// Coba ambil 1 record dari koleksi `users` — bila server mati (SocketException)
  /// return false. Bila server nyala (meski 401 karena belum auth) return true.
  Future<bool> healthCheck() async {
    try {
      await _instance!.collection('users').getList(page: 1, perPage: 1);
      return true;
    } on SocketException {
      return false;
    } catch (_) {
      // ClientException (401, 403, dst) berarti server reachable tapi butuh auth.
      return true;
    }
  }

  /// Daftarkan user baru ke PocketBase collection `users`.
  /// Return `RecordModel` yang berisi `id`, `email`, dll.
  Future<RecordModel> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    final record = await _instance!
        .collection('users')
        .create(body: {
          'email': email,
          'password': password,
          'passwordConfirm': password,
          'name': name,
          'emailVisibility': true,
        });
    return record;
  }

  /// Login user ke PocketBase via email + password.
  /// Token otomatis tersimpan di `authStore` oleh SDK.
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
    return record;
  }

  /// Ambil token autentikasi saat ini (jika ada).
  String? get currentToken => _instance?.authStore.token;

  /// Cek apakah user sudah ter-autentikasi (token masih valid).
  bool get isAuthenticated => _instance?.authStore.isValid ?? false;

  /// Keluar dan hapus token autentikasi.
  Future<void> logout() async {
    await _instance?.collection('users').authRefresh();
    _instance?.authStore.clear();
  }
}
