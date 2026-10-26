import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_config.dart';

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
  const AuthSignedIn(this.user, this.role);
  final User user;
  final UserRole role;
}

/// Pengguna lokal untuk mode offline-only (Supabase belum dikonfigurasi).
final localDeviceUser = User(
  id: 'local-device-owner',
  appMetadata: const {},
  userMetadata: const {'role': 'owner'},
  aud: 'authenticated',
  createdAt: DateTime.utc(2024).toIso8601String(),
  email: null,
);

/// Mode offline-only: aplikasi tetap dapat dipakai penuh sebagai owner lokal.
final localOfflineUser = AuthSignedIn(localDeviceUser, UserRole.owner);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final client = SupabaseConfig.client;
    if (client == null) {
      return localOfflineUser;
    }
    _listen(client);
    return _fromSession(client.auth.currentSession);
  }

  StreamSubscription<AuthState>? _sub;

  void _listen(SupabaseClient client) {
    final stream = client.auth.onAuthStateChange;
    _sub?.cancel();
    _sub = stream.listen((data) {
      state = _fromSession(data.session);
    });
  }

  AuthState _fromSession(Session? session) {
    if (session == null) return const AuthSignedOut();
    final role = roleFromName(
      session.user.userMetadata?['role'] as String?,
    );
    return AuthSignedIn(session.user, role);
  }

  Future<void> signIn(String email, String password) async {
    final client = SupabaseConfig.client;
    if (client == null) return; // mode lokal, tidak perlu login
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String fullName) async {
    final client = SupabaseConfig.client;
    if (client == null) return;
    await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': 'kasir'},
    );
  }

  Future<void> signOut() async {
    final client = SupabaseConfig.client;
    if (client == null) return;
    await client.auth.signOut();
  }

  void dispose() {
    _sub?.cancel();
  }
}

final authProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Provider peran aktif (untuk guard navigasi adaptif).
final currentRoleProvider = Provider<UserRole?>((ref) {
  final s = ref.watch(authProvider);
  return s is AuthSignedIn ? s.role : null;
});
