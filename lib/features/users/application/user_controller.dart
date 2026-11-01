import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/user_repository.dart';

/// Status layar manajemen pengguna.
class UserState {
  const UserState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.isBusy = false,
  });

  final List<Profile> users;
  final bool isLoading;
  final String? error;
  final bool isBusy;

  UserState copyWith({
    List<Profile>? users,
    bool? isLoading,
    String? error,
    bool? isBusy,
  }) {
    return UserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}

/// Controller untuk manajemen pengguna (CRUD user per bisnis).
class UserController extends Notifier<UserState> {
  @override
  UserState build() {
    return const UserState();
  }

  AppDatabase get db => ref.read(databaseProvider);

  /// Ambil businessId saat ini dari database (yang pertama ditemukan).
  /// Untuk multi-business nanti bisa diambil dari store yang aktif.
  Future<String> _currentBusinessId() async {
    final biz = await (db.select(db.businesses)..limit(1)).getSingleOrNull();
    return biz?.id ?? 'local';
  }

  /// Muat daftar user untuk bisnis saat ini.
  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final businessId = await _currentBusinessId();
      final repo = UserRepository(db, SyncableDao(db));
      final users = await repo.getUsersByBusiness(businessId);
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Gagal memuat daftar pengguna: $e');
    }
  }

  /// Buat user baru.
  Future<void> createUser({
    required String id,
    required String email,
    required String fullName,
    required String role,
    String? password,
  }) async {
    state = state.copyWith(isBusy: true, error: null);
    try {
      final businessId = await _currentBusinessId();
      final repo = UserRepository(db, SyncableDao(db));
      await repo.createUser(
        id: id,
        businessId: businessId,
        email: email,
        fullName: fullName,
        role: role,
        password: password,
      );
      await loadUsers();
    } catch (e) {
      state = state.copyWith(isBusy: false, error: 'Gagal membuat pengguna: $e');
      rethrow;
    } finally {
      if (!state.isBusy) state = state.copyWith(isBusy: false);
    }
  }

  /// Perbarui user yang sudah ada.
  Future<void> updateUser({
    required String id,
    required String email,
    required String fullName,
    required String role,
  }) async {
    state = state.copyWith(isBusy: true, error: null);
    try {
      final businessId = await _currentBusinessId();
      final repo = UserRepository(db, SyncableDao(db));
      await repo.updateUser(
        id: id,
        businessId: businessId,
        email: email,
        fullName: fullName,
        role: role,
      );
      await loadUsers();
    } catch (e) {
      state = state.copyWith(isBusy: false, error: 'Gagal memperbarui pengguna: $e');
      rethrow;
    } finally {
      if (!state.isBusy) state = state.copyWith(isBusy: false);
    }
  }

  /// Nonaktifkan user.
  Future<void> deactivateUser(String id) async {
    state = state.copyWith(isBusy: true, error: null);
    try {
      final repo = UserRepository(db, SyncableDao(db));
      await repo.deactivateUser(id);
      await loadUsers();
    } catch (e) {
      state = state.copyWith(isBusy: false, error: 'Gagal menonaktifkan pengguna: $e');
      rethrow;
    } finally {
      if (!state.isBusy) state = state.copyWith(isBusy: false);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final userControllerProvider =
    NotifierProvider<UserController, UserState>(UserController.new);
