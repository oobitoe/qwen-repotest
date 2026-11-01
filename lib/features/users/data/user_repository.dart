import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../core/network/pocketbase_client.dart';

/// Repository untuk manajemen pengguna (Owner hanya dapat mengelola user milik bisnisnya).
class UserRepository {
  UserRepository(this.db, this.dao);

  final AppDatabase db;
  final SyncableDao dao;

  /// Ambil semua user aktif dari tabel Profils lokal, difilter per businessId.
  Future<List<Profile>> getUsersByBusiness(String businessId) async {
    return (db.select(db.profiles)
          ..where((t) => t.businessId.equals(businessId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.fullName)]))
        .get();
  }

  /// Ambil satu user berdasarkan id.
  Future<Profile?> getUserById(String id) async {
    return (db.select(db.profiles)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Buat user baru (lokal Drift + enqueue ke PocketBase).
  /// Role Owner tidak diperbolehkan dibuat melalui layar ini — Owner hanya satu (first owner).
  Future<void> createUser({
    required String id,
    required String businessId,
    required String email,
    required String fullName,
    required String role,
    String? password,
  }) async {
    if (role == 'owner') {
      throw Exception('Peran Owner tidak dapat dibuat melalui layar ini. Owner pertama sudah ditetapkan saat setup.');
    }

    final now = DateTime.now().toUtc();

    await db.transaction(() async {
      await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          id: id,
          businessId: Value(businessId),
          email: email,
          fullName: fullName,
          role: role,
          isActive: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
          version: const Value(1),
          syncStatus: const Value('pending'),
        ),
      );

      await dao.enqueue(
        entityType: 'user',
        entityId: id,
        operation: 'upsert',
        payload: {
          'id': id,
          'business_id': businessId,
          'email': email,
          'full_name': fullName,
          'role': role,
          'is_active': true,
          'created_at': now.millisecondsSinceEpoch,
          'updated_at': now.millisecondsSinceEpoch,
          'version': 1,
          'sync_status': 'pending',
          if (password != null) 'password': password,
        },
        nextRetryAt: DateTime.now().toUtc(),
      );
    });

    // Sinkronisasi langsung ke PocketBase jika online.
    await _pushToPocketBase(
      id: id,
      businessId: businessId,
      email: email,
      fullName: fullName,
      role: role,
      password: password,
    );
  }

  /// Perbarui user yang sudah ada.
  Future<void> updateUser({
    required String id,
    required String businessId,
    required String email,
    required String fullName,
    required String role,
  }) async {
    final existing = await getUserById(id);
    if (existing == null) {
      throw Exception('User tidak ditemukan.');
    }

    if (existing.role == 'owner' && role != 'owner') {
      throw Exception('Role Owner tidak dapat diubah.');
    }

    final now = DateTime.now().toUtc();

    await db.transaction(() async {
      await db.update(db.profiles).replace(
        ProfilesCompanion(
          id: Value(id),
          businessId: Value(businessId),
          email: Value(email),
          fullName: Value(fullName),
          role: Value(role),
          isActive: const Value(true),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(now),
          version: Value(existing.version + 1),
          remoteId: Value(existing.remoteId),
          syncStatus: const Value('pending'),
        ),
      );

      await dao.enqueue(
        entityType: 'user',
        entityId: id,
        operation: 'upsert',
        payload: {
          'id': id,
          'business_id': businessId,
          'email': email,
          'full_name': fullName,
          'role': role,
          'is_active': true,
          'created_at': existing.createdAt.millisecondsSinceEpoch,
          'updated_at': now.millisecondsSinceEpoch,
          'version': existing.version + 1,
          'sync_status': 'pending',
        },
        nextRetryAt: DateTime.now().toUtc(),
      );
    });

    await _pushToPocketBase(
      id: id,
      businessId: businessId,
      email: email,
      fullName: fullName,
      role: role,
    );
  }

  /// Nonaktifkan user (soft delete).
  Future<void> deactivateUser(String id) async {
    final existing = await getUserById(id);
    if (existing == null) {
      throw Exception('User tidak ditemukan.');
    }

    if (existing.role == 'owner') {
      throw Exception('Owner tidak dapat dinonaktifkan.');
    }

    final now = DateTime.now().toUtc();

    await db.transaction(() async {
      await db.update(db.profiles).replace(
        ProfilesCompanion(
          id: Value(id),
          businessId: Value(existing.businessId),
          email: Value(existing.email),
          fullName: Value(existing.fullName),
          role: Value(existing.role),
          isActive: const Value(false),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(now),
          version: Value(existing.version + 1),
          remoteId: Value(existing.remoteId),
          syncStatus: const Value('pending'),
        ),
      );

      await dao.enqueue(
        entityType: 'user',
        entityId: id,
        operation: 'upsert',
        payload: {
          'id': id,
          'business_id': existing.businessId,
          'email': existing.email,
          'full_name': existing.fullName,
          'role': existing.role,
          'is_active': false,
          'created_at': existing.createdAt.millisecondsSinceEpoch,
          'updated_at': now.millisecondsSinceEpoch,
          'version': existing.version + 1,
          'sync_status': 'pending',
        },
        nextRetryAt: DateTime.now().toUtc(),
      );
    });

    await _pushToPocketBase(
      id: id,
      businessId: existing.businessId,
      email: existing.email,
      fullName: existing.fullName,
      role: existing.role,
    );
  }

  /// Push satu user ke PocketBase collection `users` jika online.
  Future<void> _pushToPocketBase({
    required String id,
    required String businessId,
    required String email,
    required String fullName,
    required String role,
    String? password,
  }) async {
    final pb = PocketBaseClient.instance;
    final reachable = await PocketBaseClient.client.healthCheck();
    if (!reachable) return;

    try {
      // Cek apakah user sudah ada di PB berdasarkan email
      final existingList = await pb
          .collection('users')
          .getList(page: 1, perPage: 1, filter: 'email = $email');

      if (existingList.items.isNotEmpty) {
        // Update existing
        final existingRecord = existingList.items.first;
        await pb.collection('users').update(
          existingRecord.id,
          body: {
            'email': email,
            'name': fullName,
            if (password != null) 'password': password,
            if (password != null) 'passwordConfirm': password,
            'businessId': businessId,
          },
        );
      } else {
        // Create new
        await pb.collection('users').create(body: {
          'email': email,
          'name': fullName,
          if (password != null) 'password': password,
          if (password != null) 'passwordConfirm': password,
          'businessId': businessId,
          'emailVisibility': true,
        });
      }
    } catch (_) {
      // Gagal push ke PB tidak fatal — data sudah tersimpan lokal dan di-enqueue
    }
  }
}
