import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import 'expense_entity.dart';

/// Repository pengeluaran dengan sinkronisasi outbox (local-first).
class ExpenseRepository {
  const ExpenseRepository(this._db, this._dao);

  final AppDatabase _db;
  final SyncableDao _dao;

  /// Stream semua kategori pengeluaran aktif, difilter per businessId dan storeId.
  Stream<List<ExpenseCategoryEntity>> watchExpenseCategories({
    bool onlyActive = true,
    required String businessId,
    required String storeId,
  }) {
    final q = _db.select(_db.expenseCategories)
      ..where((t) => t.businessId.equals(businessId) & t.storeId.equals(storeId));
    if (onlyActive) {
      q.where((t) => t.isActive.equals(true) & t.deletedAt.isNull());
    }
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          ExpenseCategoryEntity(
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

  /// Stream semua pengeluaran aktif, difilter per businessId dan storeId.
  Stream<List<ExpenseEntity>> watchExpenses({
    bool onlyActive = true,
    required String businessId,
    required String storeId,
  }) {
    final q = _db.select(_db.expenses)
      ..where((t) => t.businessId.equals(businessId) & t.storeId.equals(storeId));
    if (onlyActive) {
      q.where((t) => t.deletedAt.isNull());
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          ExpenseEntity(
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

  /// Cari pengeluaran berdasarkan kata kunci.
  Future<List<ExpenseEntity>> searchExpenses({
    required String businessId,
    required String storeId,
    required String query,
  }) async {
    final q = query.toLowerCase();
    final rows = await (_db.select(_db.expenses)
          ..where((t) => t.businessId.equals(businessId) & t.storeId.equals(storeId) & t.deletedAt.isNull()))
        .get();
    return rows
        .where((r) =>
            r.description.toLowerCase().contains(q) ||
            (r.categoryId ?? '').toLowerCase().contains(q))
        .map((r) => ExpenseEntity(
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

  /// Simpan kategori pengeluaran (create atau update) dan enqueue ke outbox.
  Future<void> saveExpenseCategory({
    required String id,
    required String businessId,
    required String storeId,
    required String name,
    required bool isActive,
  }) async {
    await _dao.upsertAndEnqueue(
      'expense_category',
      {
        'name': name,
        'is_active': isActive,
        'business_id': businessId,
        'store_id': storeId,
      },
      id: id,
    );
  }

  /// Hapus kategori pengeluaran (soft delete) dan enqueue ke outbox.
  Future<void> deleteExpenseCategory(String id) async {
    await _dao.softDeleteAndEnqueue('expense_category', id);
  }

  /// Simpan pengeluaran (create atau update) dan enqueue ke outbox.
  Future<void> saveExpense({
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
      'expense',
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

  /// Hapus pengeluaran (soft delete) dan enqueue ke outbox.
  Future<void> deleteExpense(String id) async {
    await _dao.softDeleteAndEnqueue('expense', id);
  }

  /// Total pengeluaran hari ini.
  Future<double> todayExpensesTotal({required String businessId, required String storeId}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final rows = await (_db.select(_db.expenses)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.storeId.equals(storeId) &
              t.deletedAt.isNull() &
              t.createdAt.isBiggerOrEqualValue(startOfDay) &
              t.createdAt.isSmallerThanValue(endOfDay)))
        .get();
    return rows.fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  /// Total pengeluaran bulan ini.
  Future<double> monthlyExpensesTotal({required String businessId, required String storeId}) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final rows = await (_db.select(_db.expenses)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.storeId.equals(storeId) &
              t.deletedAt.isNull() &
              t.createdAt.isBiggerOrEqualValue(startOfMonth) &
              t.createdAt.isSmallerThanValue(endOfMonth)))
        .get();
    return rows.fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  /// Total pengeluaran per kategori.
  Future<Map<String, double>> expensesByCategory({required String businessId, required String storeId}) async {
    final rows = await (_db.select(_db.expenses)
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

/// Provider repository pengeluaran.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(syncDaoProvider);
  return ExpenseRepository(db, dao);
});

/// Stream kategori pengeluaran aktif untuk UI.
final expenseCategoriesProvider =
    StreamProvider.family<List<ExpenseCategoryEntity>, ({String businessId, String storeId})>((ref, params) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.watchExpenseCategories(businessId: params.businessId, storeId: params.storeId);
});

/// Stream pengeluaran aktif untuk UI.
final expensesProvider = StreamProvider.family<List<ExpenseEntity>, ({String businessId, String storeId})>((ref, params) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.watchExpenses(businessId: params.businessId, storeId: params.storeId);
});
