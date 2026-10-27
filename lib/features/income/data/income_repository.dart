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

  /// Stream semua kategori pemasukan aktif.
  Stream<List<IncomeCategoryEntity>> watchIncomeCategories({
    bool onlyActive = true,
  }) {
    final q = _db.select(_db.incomeCategories);
    if (onlyActive) {
      q.where((t) => t.isActive.equals(true) & t.deletedAt.isNull());
    }
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          IncomeCategoryEntity(
            id: r.id,
            name: r.name,
            isActive: r.isActive,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
            deletedAt: r.deletedAt,
          ),
      ];
    });
  }

  /// Stream semua pemasukan aktif.
  Stream<List<IncomeEntity>> watchIncomes({bool onlyActive = true}) {
    final q = _db.select(_db.incomeEntries);
    if (onlyActive) {
      q.where((t) => t.deletedAt.isNull());
    }
    q.orderBy([(_) => OrderingTerm.desc(_.createdAt)]);
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          IncomeEntity(
            id: r.id,
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
  Future<List<IncomeEntity>> searchIncomes(String query) async {
    final q = query.toLowerCase();
    final rows = await (_db.select(_db.incomeEntries)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return rows
        .where((r) =>
            r.description.toLowerCase().contains(q) ||
            (r.categoryId ?? '').toLowerCase().contains(q))
        .map((r) => IncomeEntity(
              id: r.id,
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
  Future<void> saveIncomeCategory(IncomeCategoryEntity category) async {
    await _dao.upsertAndEnqueue(
      'income_category',
      {
        'name': category.name,
        'is_active': category.isActive,
      },
      id: category.id,
    );
  }

  /// Hapus kategori pemasukan (soft delete) dan enqueue ke outbox.
  Future<void> deleteIncomeCategory(String id) async {
    await _dao.softDeleteAndEnqueue('income_category', id);
  }

  /// Simpan pemasukan (create atau update) dan enqueue ke outbox.
  Future<void> saveIncome(IncomeEntity income) async {
    await _dao.upsertAndEnqueue(
      'income',
      {
        'category_id': income.categoryId,
        'description': income.description,
        'amount': income.amount,
        'payment_method': income.paymentMethod,
        'created_by': income.createdBy,
      },
      id: income.id,
    );
  }

  /// Hapus pemasukan (soft delete) dan enqueue ke outbox.
  Future<void> deleteIncome(String id) async {
    await _dao.softDeleteAndEnqueue('income', id);
  }

  /// Total pemasukan hari ini.
  Future<double> todayIncomeTotal() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final rows = await (_db.select(_db.incomeEntries)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.createdAt.isBiggerOrEqualValue(startOfDay) &
              t.createdAt.isSmallerThanValue(endOfDay)))
        .get();
    return rows.fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  /// Total pemasukan bulan ini.
  Future<double> monthlyIncomeTotal() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final rows = await (_db.select(_db.incomeEntries)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.createdAt.isBiggerOrEqualValue(startOfMonth) &
              t.createdAt.isSmallerThanValue(endOfMonth)))
        .get();
    return rows.fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  /// Total pemasukan per kategori.
  Future<Map<String, double>> incomeByCategory() async {
    final rows = await (_db.select(_db.incomeEntries)
          ..where((t) => t.deletedAt.isNull()))
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
    StreamProvider<List<IncomeCategoryEntity>>((ref) {
  final repo = ref.watch(incomeRepositoryProvider);
  return repo.watchIncomeCategories();
});

/// Stream pemasukan aktif untuk UI.
final incomesProvider = StreamProvider<List<IncomeEntity>>((ref) {
  final repo = ref.watch(incomeRepositoryProvider);
  return repo.watchIncomes();
});