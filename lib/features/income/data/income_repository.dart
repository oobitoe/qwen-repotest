import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import 'income_entity.dart';

/// Repository pemasukan dengan sinkronisasi outbox (local-first).
class IncomeRepository {
  const IncomeRepository(this._db, this._dao);

  final AppDatabase _db;
  final SyncableDao _dao;

  /// Stream semua kategori pemasukan aktif, difilter per businessId dan storeId.
  Stream<List<IncomeCategoryEntity>> watchIncomeCategories({
    bool onlyActive = true,
    required String businessId,
    required String storeId,
  }) {
    final q = _db.select(_db.incomeCategories)
      ..where((t) => t.businessId.equals(businessId) & t.storeId.equals(storeId));
    if (onlyActive) {
      q.where((t) => t.isActive.equals(true) & t.deletedAt.isNull());
    }
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          IncomeCategoryEntity(
            id: r.id,
            businessId: r.businessId,
            storeId: r.storeId,
            name: r.name,
            isActive: r.isActive,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
            deletedAt: r.deletedAt,
          ),
      ];
    });
  }

  /// Stream semua pemasukan aktif, difilter per businessId dan storeId.
  Stream<List<IncomeEntity>> watchIncomes({
    bool onlyActive = true,
    required String businessId,
    required String storeId,
  }) {
    final q = _db.select(_db.incomeEntries)
      ..where((t) => t.businessId.equals(businessId) & t.storeId.equals(storeId));
    if (onlyActive) {
      q.where((t) => t.deletedAt.isNull());
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          IncomeEntity(
            id: r.id,
            businessId: r.businessId,
            storeId: r.storeId,
            categoryId: r.categoryId,
            description: r.description,
            amount: r.amount,
            paymentMethod: r.paymentMethod,
            createdBy: r.createdBy,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
            deletedAt: r.deletedAt,
          ),
      ];
    });
  }

  /// Cari pemasukan berdasarkan kata kunci.
  Future<List<IncomeEntity>> searchIncomes({
    required String businessId,
    required String storeId,
    required String query,
  }) async {
    final q = query.toLowerCase();
    final rows = await (_db.select(_db.incomeEntries)
          ..where((t) => t.businessId.equals(businessId) & t.storeId.equals(storeId) & t.deletedAt.isNull()))
        .get();
    return rows
        .where((r) =>
            r.description.toLowerCase().contains(q) ||
            (r.categoryId ?? '').toLowerCase().contains(q))
        .map((r) => IncomeEntity(
              id: r.id,
              businessId: r.businessId,
              storeId: r.storeId,
              categoryId: r.categoryId,
              description: r.description,
              amount: r.amount,
              paymentMethod: r.paymentMethod,
              createdBy: r.createdBy,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
              deletedAt: r.deletedAt,
            ))
        .toList();
  }

  /// Simpan kategori pemasukan (create atau update) dan enqueue ke outbox.
  Future<void> saveIncomeCategory({
    required String id,
    required String businessId,
    required String storeId,
    required String name,
    required bool isActive,
  }) async {
    await _dao.upsertAndEnqueue(
      'income_category',
      {
        'name': name,
        'is_active': isActive,
        'business_id': businessId,
        'store_id': storeId,
      },
      id: id,
    );
  }

  /// Hapus kategori pemasukan (soft delete) dan enqueue ke outbox.
  Future<void> deleteIncomeCategory(String id) async {
    await _dao.softDeleteAndEnqueue('income_category', id);
  }

  /// Simpan pemasukan (create atau update) dan enqueue ke outbox.
  Future<void> saveIncome({
    required String id,
    required String businessId,
    required String storeId,
    required String? categoryId,
    required String description,
    required double amount,
    required String paymentMethod,
    required String? createdBy,
  }) async {
    await _dao.upsertAndEnqueue(
      'income',
      {
        'category_id': categoryId,
        'description': description,
        'amount': amount,
        'payment_method': paymentMethod,
        'created_by': createdBy,
        'business_id': businessId,
        'store_id': storeId,
      },
      id: id,
    );
  }

  /// Hapus pemasukan (soft delete) dan enqueue ke outbox.
  Future<void> deleteIncome(String id) async {
    await _dao.softDeleteAndEnqueue('income', id);
  }

  /// Total pemasukan hari ini.
  Future<double> todayIncomeTotal({required String businessId, required String storeId}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final rows = await (_db.select(_db.incomeEntries)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.storeId.equals(storeId) &
              t.deletedAt.isNull() &
              t.createdAt.isBiggerOrEqualValue(startOfDay) &
              t.createdAt.isSmallerThanValue(endOfDay)))
        .get();
    return rows.fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  /// Total pemasukan bulan ini.
  Future<double> monthlyIncomeTotal({required String businessId, required String storeId}) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final rows = await (_db.select(_db.incomeEntries)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.storeId.equals(storeId) &
              t.deletedAt.isNull() &
              t.createdAt.isBiggerOrEqualValue(startOfMonth) &
              t.createdAt.isSmallerThanValue(endOfMonth)))
        .get();
    return rows.fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  /// Total pemasukan per kategori.
  Future<Map<String, double>> incomeByCategory({required String businessId, required String storeId}) async {
    final rows = await (_db.select(_db.incomeEntries)
          ..where((t) => t.businessId.equals(businessId) & t.storeId.equals(storeId) & t.deletedAt.isNull()))
        .get();

    final Map<String, double> result = {};
    for (final r in rows) {
      final catId = r.categoryId ?? 'Tanpa Kategori';
      result[catId] = (result[catId] ?? 0) + r.amount;
    }
    return result;
  }
}

/// Provider repository pemasukan.
final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(syncDaoProvider);
  return IncomeRepository(db, dao);
});

/// Stream kategori pemasukan aktif untuk UI.
final incomeCategoriesProvider =
    StreamProvider.family<List<IncomeCategoryEntity>, ({String businessId, String storeId})>((ref, params) {
  final repo = ref.watch(incomeRepositoryProvider);
  return repo.watchIncomeCategories(businessId: params.businessId, storeId: params.storeId);
});

/// Stream pemasukan aktif untuk UI.
final incomesProvider = StreamProvider.family<List<IncomeEntity>, ({String businessId, String storeId})>((ref, params) {
  final repo = ref.watch(incomeRepositoryProvider);
  return repo.watchIncomes(businessId: params.businessId, storeId: params.storeId);
});
