import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  const AuthSignedIn(this.userId, this.role);
  final String userId;
  final UserRole role;
}

/// Pengguna lokal untuk mode offline-only (tanpa backend autentikasi).
final localDeviceUserId = 'local-device-owner';

/// Mode offline-only: aplikasi tetap dapat dipakai penuh sebagai owner lokal.
final localOfflineUser = AuthSignedIn(localDeviceUserId, UserRole.owner);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Tanpa backend auth (Supabase/PocketBase belum diintegrasi),
    // aplikasi berjalan sebagai owner lokal.
    return localOfflineUser;
  }

  Future<void> signIn(String email, String password) async {
    // Tidak ada backend auth saat ini; mode lokal selalu sukses sebagai owner.
    return;
  }

  Future<void> signUp(String email, String password, String fullName) async {
    // Tidak ada backend auth saat ini.
    return;
  }

  Future<void> signOut() async {
    // Tidak ada backend auth untuk di-sign-out.
    return;
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
