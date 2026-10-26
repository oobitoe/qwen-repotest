import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_config.dart';

/// Role pengguna awal sesuai PRD.
enum UserRole { owner, admin, manager, kasir, staffGudang }

UserRole roleFromName(String? name) {
  switch (name) {
    case 'owner':
      return UserRole.owner;
    case 'admin':
      return UserRole.admin;
    case 'manager':
      return UserRole.manager;
    case 'kasir':
      return UserRole.kasir;
    case 'staff_gudang':
      return UserRole.staffGudang;
    default:
      return UserRole.kasir;
  }
}

/// Permission granular.
class Permission {
  const Permission._();

  static const viewReports = 'view_reports';
  static const editPrice = 'edit_price';
  static const manageStock = 'manage_stock';
  static const deleteData = 'delete_data';
  static const manageUsers = 'manage_users';
  static const doRefund = 'do_refund';
  static const manageFinance = 'manage_finance';
}

/// Matriks permission per role (validasi UI). Validasi sebenarnya juga
/// harus terjadi di server lewat RLS — lihat supabase/migrations.
const Map<UserRole, Set<String>> rolePermissions = {
  UserRole.owner: {
    Permission.viewReports,
    Permission.editPrice,
    Permission.manageStock,
    Permission.deleteData,
    Permission.manageUsers,
    Permission.doRefund,
    Permission.manageFinance,
  },
  UserRole.admin: {
    Permission.viewReports,
    Permission.editPrice,
    Permission.manageStock,
    Permission.deleteData,
    Permission.manageUsers,
    Permission.doRefund,
    Permission.manageFinance,
  },
  UserRole.manager: {
    Permission.viewReports,
    Permission.editPrice,
    Permission.manageStock,
    Permission.doRefund,
    Permission.manageFinance,
  },
  UserRole.kasir: {},
  UserRole.staffGudang: {Permission.manageStock},
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
class LocalDeviceUser implements User {
  const LocalDeviceUser();

  @override
  String get id => 'local-device-owner';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Mode offline-only: aplikasi tetap dapat dipakai penuh sebagai owner lokal.
const localOfflineUser = AuthSignedIn(LocalDeviceUser(), UserRole.owner);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final client = SupabaseConfig.client;
    if (client == null) {
      return localOfflineUser;
    }
    _listen(client);
    return _fromSession(client.currentSession);
  }

  StreamSubscription<AuthState>? _sub;

  void _listen(SupabaseClient client) {
    _sub?.cancel();
    _sub = client.auth.onAuthStateChange.listen((data) {
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
}

final authProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Provider peran aktif (untuk guard navigasi adaptif).
final currentRoleProvider = Provider<UserRole?>((ref) {
  final s = ref.watch(authProvider);
  return s is AuthSignedIn ? s.role : null;
});
