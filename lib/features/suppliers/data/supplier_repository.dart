import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import 'supplier_entity.dart';

/// Repository supplier dengan sinkronisasi outbox (local-first).
class SupplierRepository {
  const SupplierRepository(this._db, this._dao);

  final AppDatabase _db;
  final SyncableDao _dao;

  Stream<List<SupplierEntity>> watchSuppliers({required String businessId, required String storeId}) {
    final q = _db.select(_db.suppliers)
      ..where((t) => t.businessId.equals(businessId) & t.storeId.equals(storeId) & t.isActive.equals(true) & t.deletedAt.isNull());
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          SupplierEntity(
            id: r.id,
            businessId: r.businessId,
            storeId: r.storeId,
            name: r.name,
            phone: r.phone,
            email: r.email,
            address: r.address,
            notes: r.notes,
            isActive: r.isActive,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
      ];
    });
  }

  Future<List<SupplierEntity>> searchSuppliers({required String businessId, required String storeId, required String query}) async {
    final q = query.toLowerCase();
    final rows = await (_db.select(_db.suppliers)
          ..where((t) => t.businessId.equals(businessId) & t.storeId.equals(storeId) & t.deletedAt.isNull()))
        .get();
    return rows
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            (r.phone ?? '').toLowerCase().contains(q))
        .map((r) => SupplierEntity(
              id: r.id,
              businessId: r.businessId,
              storeId: r.storeId,
              name: r.name,
              phone: r.phone,
              email: r.email,
              address: r.address,
              notes: r.notes,
              isActive: r.isActive,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
            ))
        .toList();
  }

  Future<void> saveSupplier({
    required String id,
    required String businessId,
    required String storeId,
    required String name,
    required String? phone,
    required String? email,
    required String? address,
    required String? notes,
    required bool isActive,
  }) async {
    await _dao.upsertAndEnqueue(
      'supplier',
      {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
        'is_active': isActive,
        'business_id': businessId,
        'store_id': storeId,
      },
      id: id,
    );
  }

  Future<void> deleteSupplier(String id) async {
    await _dao.softDeleteAndEnqueue('supplier', id);
  }
}

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(syncDaoProvider);
  return SupplierRepository(db, dao);
});

final suppliersProvider = StreamProvider.family<List<SupplierEntity>, ({String businessId, String storeId})>((ref, params) {
  final repo = ref.watch(supplierRepositoryProvider);
  return repo.watchSuppliers(businessId: params.businessId, storeId: params.storeId);
});
