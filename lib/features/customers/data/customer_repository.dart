import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import 'customer_entity.dart';

/// Repository pelanggan dengan sinkronisasi outbox (local-first).
class CustomerRepository {
  const CustomerRepository(this._db, this._dao);

  final AppDatabase _db;
  final SyncableDao _dao;

  Stream<List<CustomerEntity>> watchCustomers({required String businessId, required String storeId}) {
    final q = _db.select(_db.customers)
      ..where((t) => t.businessId.equals(businessId) & t.storeId.equals(storeId) & t.isActive.equals(true) & t.deletedAt.isNull());
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          CustomerEntity(
            id: r.id,
            businessId: r.businessId,
            storeId: r.storeId,
            code: r.code,
            name: r.name,
            phone: r.phone,
            email: r.email,
            address: r.address,
            notes: r.notes,
            tier: r.tier,
            rewardPoints: r.rewardPoints,
            isActive: r.isActive,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
      ];
    });
  }

  Future<List<CustomerEntity>> searchCustomers({required String businessId, required String storeId, required String query}) async {
    final q = query.toLowerCase();
    final rows = await (_db.select(_db.customers)
          ..where((t) => t.businessId.equals(businessId) & t.storeId.equals(storeId) & t.deletedAt.isNull()))
        .get();
    return rows
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            (r.phone ?? '').toLowerCase().contains(q) ||
            (r.code ?? '').toLowerCase().contains(q))
        .map((r) => CustomerEntity(
              id: r.id,
              businessId: r.businessId,
              storeId: r.storeId,
              code: r.code,
              name: r.name,
              phone: r.phone,
              email: r.email,
              address: r.address,
              notes: r.notes,
              tier: r.tier,
              rewardPoints: r.rewardPoints,
              isActive: r.isActive,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
            ))
        .toList();
  }

  Future<void> saveCustomer({
    required String id,
    required String businessId,
    required String storeId,
    required String? code,
    required String name,
    required String? phone,
    required String? email,
    required String? address,
    required String? notes,
    required String tier,
    required int rewardPoints,
    required bool isActive,
  }) async {
    await _dao.upsertAndEnqueue(
      'customer',
      {
        'code': code,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
        'tier': tier,
        'reward_points': rewardPoints,
        'is_active': isActive,
        'business_id': businessId,
        'store_id': storeId,
      },
      id: id,
    );
  }

  Future<void> deleteCustomer(String id) async {
    await _dao.softDeleteAndEnqueue('customer', id);
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(syncDaoProvider);
  return CustomerRepository(db, dao);
});

final customersProvider = StreamProvider.family<List<CustomerEntity>, ({String businessId, String storeId})>((ref, params) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.watchCustomers(businessId: params.businessId, storeId: params.storeId);
});
