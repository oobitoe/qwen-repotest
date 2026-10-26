import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import 'product_entity.dart';

/// Repository produk dengan sinkronisasi outbox (local-first).
class ProductRepository {
  const ProductRepository(this._db, this._dao);

  final AppDatabase _db;
  final SyncableDao _dao;

  /// Stream semua produk aktif.
  Stream<List<ProductEntity>> watchProducts({bool onlyActive = true}) {
    final q = _db.select(_db.products);
    if (onlyActive) {
      q.where((t) => t.isActive.equals(true) & t.deletedAt.isNull());
    }
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          ProductEntity(
            id: r.id,
            sku: r.sku,
            barcode: r.barcode,
            name: r.name,
            description: r.description,
            categoryId: r.categoryId,
            unitId: r.unitId,
            costPrice: r.costPrice,
            sellPrice: r.sellPrice,
            wholesalePrice: r.wholesalePrice,
            minStock: r.minStock,
            stock: r.stock,
            isActive: r.isActive,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
      ];
    });
  }

  /// Cari produk berdasarkan kata kunci (nama, SKU, atau barcode).
  Future<List<ProductEntity>> searchProducts(String query) async {
    final q = query.toLowerCase();
    final rows = await (_db.select(_db.products)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return rows
        .where((r) {
          final name = r.name.toLowerCase();
          final sku = r.sku.toLowerCase();
          final barcode = (r.barcode ?? '').toLowerCase();
          return name.contains(q) || sku.contains(q) || barcode.contains(q);
        })
        .map((r) => ProductEntity(
              id: r.id,
              sku: r.sku,
              barcode: r.barcode,
              name: r.name,
              description: r.description,
              categoryId: r.categoryId,
              unitId: r.unitId,
              costPrice: r.costPrice,
              sellPrice: r.sellPrice,
              wholesalePrice: r.wholesalePrice,
              minStock: r.minStock,
              stock: r.stock,
              isActive: r.isActive,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
            ))
        .toList();
  }

  /// Ambil produk menipis stok (stock <= minStock).
  Future<List<ProductEntity>> lowStockProducts() async {
    final rows = await (_db.select(_db.products)
          ..where((t) =>
              t.isActive.equals(true) &
              t.deletedAt.isNull() &
              (t.stock - t.minStock).isSmallerOrEqualValue(0)))
        .get();
    return [
      for (final r in rows)
        ProductEntity(
          id: r.id,
          sku: r.sku,
          barcode: r.barcode,
          name: r.name,
          description: r.description,
          categoryId: r.categoryId,
          unitId: r.unitId,
          costPrice: r.costPrice,
          sellPrice: r.sellPrice,
          wholesalePrice: r.wholesalePrice,
          minStock: r.minStock,
          stock: r.stock,
          isActive: r.isActive,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
        ),
    ];
  }

  /// Simpan produk (create atau update) dan enqueue ke outbox.
  Future<void> saveProduct(ProductEntity product) async {
    await _dao.upsertAndEnqueue(
      'product',
      {
        'sku': product.sku,
        'barcode': product.barcode,
        'name': product.name,
        'description': product.description,
        'category_id': product.categoryId,
        'unit_id': product.unitId,
        'cost_price': product.costPrice,
        'sell_price': product.sellPrice,
        'wholesale_price': product.wholesalePrice,
        'min_stock': product.minStock,
        'stock': product.stock,
        'is_active': product.isActive,
      },
      id: product.id,
    );
  }

  /// Hapus produk (soft delete) dan enqueue ke outbox.
  Future<void> deleteProduct(String id) async {
    await _dao.softDeleteAndEnqueue('product', id);
  }
}

/// Provider repository produk.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(syncDaoProvider);
  return ProductRepository(db, dao);
});

/// Stream produk aktif untuk UI.
final productsProvider = StreamProvider<List<ProductEntity>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchProducts();
});

/// Stream produk menipis stok.
final lowStockProductsProvider = StreamProvider<List<ProductEntity>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchProducts().asyncMap((_) => repo.lowStockProducts());
});
