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

  Stream<List<CustomerEntity>> watchCustomers() {
    final q = _db.select(_db.customers)
      ..where((t) => t.isActive.equals(true) & t.deletedAt.isNull());
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          CustomerEntity(
            id: r.id,
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

  Future<List<CustomerEntity>> searchCustomers(String query) async {
    final q = query.toLowerCase();
    final rows = await (_db.select(_db.customers)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return rows
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            (r.phone ?? '').toLowerCase().contains(q) ||
            (r.code ?? '').toLowerCase().contains(q))
        .map((r) => CustomerEntity(
              id: r.id,
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

  Future<void> saveCustomer(CustomerEntity customer) async {
    await _dao.upsertAndEnqueue(
      'customer',
      {
        'code': customer.code,
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email,
        'address': customer.address,
        'notes': customer.notes,
        'tier': customer.tier,
        'reward_points': customer.rewardPoints,
        'is_active': customer.isActive,
      },
      id: customer.id,
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

final customersProvider = StreamProvider<List<CustomerEntity>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.watchCustomers();
});
