import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import '../../products/data/product_entity.dart';

/// Repository kategori dengan sinkronisasi outbox (local-first).
class CategoryRepository {
  const CategoryRepository(this._db, this._dao);

  final AppDatabase _db;
  final SyncableDao _dao;

  /// Stream semua kategori aktif.
  Stream<List<CategoryEntity>> watchCategories() {
    final q = _db.select(_db.categories)
      ..where((t) => t.isActive.equals(true) & t.deletedAt.isNull());
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          CategoryEntity(
            id: r.id,
            name: r.name,
            isActive: r.isActive,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
      ];
    });
  }

  /// Cari kategori berdasarkan nama (filter di sisi Dart karena Drift
  /// pada versi ini tidak menyediakan `like` pada GeneratedColumn).
  Future<List<CategoryEntity>> searchCategories(String query) async {
    final q = query.toLowerCase();
    final rows = await (_db.select(_db.categories)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return rows
        .where((r) => r.name.toLowerCase().contains(q))
        .map((r) => CategoryEntity(
              id: r.id,
              name: r.name,
              isActive: r.isActive,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
            ))
        .toList();
  }

  /// Simpan kategori dan enqueue ke outbox.
  Future<void> saveCategory(CategoryEntity category) async {
    await _dao.upsertAndEnqueue(
      'category',
      {
        'name': category.name,
        'is_active': category.isActive,
      },
      id: category.id,
    );
  }

  /// Hapus kategori (soft delete) dan enqueue ke outbox.
  Future<void> deleteCategory(String id) async {
    await _dao.softDeleteAndEnqueue('category', id);
  }
}

/// Provider repository kategori.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(syncDaoProvider);
  return CategoryRepository(db, dao);
});

/// Stream kategori aktif untuk UI.
final categoriesProvider = StreamProvider<List<CategoryEntity>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategories();
});
