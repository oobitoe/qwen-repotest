import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/pocketbase_client.dart';
import '../../../shared/providers/core_providers.dart';

/// Role pengguna awal sesuai PRD.
enum UserRole { owner, admin, manager, kasir, staffGudang }

UserRole roleFromName(String? name) => switch (name) {
      'owner' => UserRole.owner,
      'admin' => UserRole.admin,
      'manager' => UserRole.manager,
      'kasir' => UserRole.kasir,
      'staff_gudang' => UserRole.staffGudang,
      _ => UserRole.kasir,
    };

String roleName(UserRole role) => switch (role) {
      UserRole.owner => 'owner',
      UserRole.admin => 'admin',
      UserRole.manager => 'manager',
      UserRole.kasir => 'kasir',
      UserRole.staffGudang => 'staff_gudang',
    };

/// Matriks hak akses per role (PRD: guard navigasi adaptif).
const Map<UserRole, Set<String>> rolePermissions = {
  UserRole.owner: {
    'dashboard.view', 'products.view', 'products.manage', 'stock.manage',
    'pos.use', 'sales.view', 'expenses.manage', 'income.manage',
    'reports.view', 'users.manage', 'settings.manage',
  },
  UserRole.admin: {
    'dashboard.view', 'products.view', 'products.manage', 'stock.manage',
    'pos.use', 'sales.view', 'expenses.manage', 'income.manage',
    'reports.view', 'users.manage',
  },
  UserRole.manager: {
    'dashboard.view', 'products.view', 'products.manage', 'stock.manage',
    'pos.use', 'sales.view', 'expenses.manage', 'reports.view',
  },
  UserRole.kasir: {'dashboard.view', 'products.view', 'pos.use', 'sales.view'},
  UserRole.staffGudang: {
    'dashboard.view', 'products.view', 'stock.manage',
  },
};

bool roleHasPermission(UserRole role, String permission) =>
    rolePermissions[role]?.contains(permission) ?? false;

/// Status sesi autentikasi.
sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.userId, this.role, this.businessId);
  final String userId;
  final UserRole role;
  final String businessId; // Bisnis yang memiliki user ini — difverifikasi di lokal + PocketBase
}

/// Pengguna lokal untuk mode offline-only (tanpa backend autentikasi).
const String localDeviceUserId = 'local-device-owner';

/// Mode offline-only: aplikasi tetap dapat dipakai penuh sebagai owner lokal.
const localOfflineUser = AuthSignedIn(localDeviceUserId, UserRole.owner, 'local');

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Awalnya tidak ada sesi (AuthUnknown).
    // Setelah login PocketBase sukses, berubah menjadi AuthSignedIn.
    return const AuthUnknown();
  }

  /// Daftarkan user baru ke PocketBase collection `users`.
  /// Setelah sukses, PocketBase otomatis menyimpan token di `authStore`.
  Future<void> signUp(
    String email,
    String password,
    String fullName, {
    UserRole role = UserRole.kasir,
    String? businessId, // Bisnis yang memiliki user ini
  }) async {
    final pb = PocketBaseClient.client;

    // Pastikan server reachable sebelum mencoba daftar.
    final reachable = await pb.healthCheck();
    if (!reachable) {
      throw Exception('Tidak dapat menghubungi server PocketBase. Periksa koneksi internet.');
    }

    // Daftarkan ke PocketBase `users` collection.
    await pb.registerUser(
      email: email,
      password: password,
      name: fullName,
      businessId: businessId,
    );

    // Login otomatis setelah daftar agar token tersimpan di authStore.
    await pb.loginUser(email: email, password: password);

    state = AuthSignedIn(pb.currentToken ?? localDeviceUserId, role, businessId ?? 'local');
  }

  /// Daftarkan **Owner pertama** saat setup pertama kali.
  /// Role dikunci menjadi `owner` dan tidak dapat diubah.
  /// Return user id dari PocketBase.
  Future<String> registerFirstOwner(
    String email,
    String password,
    String fullName, {
    String? businessId, // Bisnis yang memiliki Owner ini (WAJIB)
  }) async {
    final pb = PocketBaseClient.client;

    // Pastikan server reachable sebelum mencoba daftar.
    final reachable = await pb.healthCheck();
    if (!reachable) {
      throw Exception('Tidak dapat menghubungi server PocketBase. Periksa koneksi internet.');
    }

    // Daftarkan ke PocketBase `users` collection dengan role Owner.
    final record = await pb.registerUser(
      email: email,
      password: password,
      name: fullName,
      businessId: businessId,
    );

    // Login otomatis setelah daftar agar token tersimpan di authStore.
    await pb.loginUser(email: email, password: password);

    // Selalu Owner — tidak boleh diubah.
    final userId = record.id;
    state = AuthSignedIn(userId, UserRole.owner, businessId ?? 'local');
    return userId;
  }

  /// Login user ke PocketBase (online) atau lewat profil lokal (offline).
  /// Aplikasi offline-first: login bisa dilakukan offline selama profil
  /// pengguna sudah tersimpan di database lokal (Drift).
  /// Hanya pembuatan akun Owner pertama (registerFirstOwner) yang butuh online.
  Future<void> signIn(String email, String password) async {
    final pb = PocketBaseClient.client;

    // 1. Cek profil lokal (Drift) — wajib ada untuk login, online atau offline
    final db = ref.read(databaseProvider);
    final profile = await (db.select(db.profiles)
          ..where((t) => t.email.equals(email)))
        .getSingleOrNull();

    if (profile == null) {
      throw Exception('Profil pengguna tidak ditemukan di database lokal. Hubungi Owner.');
    }

    // 2. Jika online, verifikasi password ke PocketBase
    final reachable = await pb.healthCheck();
    if (reachable) {
      await pb.loginUser(email: email, password: password);
    }

    // Role dan businessId diambil dari profil lokal (sumber kebenaran untuk akses)
    final role = roleFromName(profile.role);
    final businessId = profile.businessId;
    // Pakai token PocketBase jika ada, kalau offline pakai id profil lokal
    final userId = pb.currentToken?.isNotEmpty == true
        ? pb.currentToken!
        : profile.id;

    state = AuthSignedIn(userId, role, businessId);
  }

  Future<void> signOut() async {
    await PocketBaseClient.client.logout();
    state = const AuthSignedOut();
  }

  void dispose() {
    // Tidak ada subscription untuk dibatalkan.
  }
}

final authProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Provider peran aktif (untuk guard navigasi adaptif).
final currentRoleProvider = Provider<UserRole?>((ref) {
  final s = ref.watch(authProvider);
  return s is AuthSignedIn ? s.role : null;
});
