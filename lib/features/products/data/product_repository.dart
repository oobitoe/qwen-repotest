import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import 'product_entity.dart';

/// Hasil pagination generik.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  int get totalPages => (totalCount / pageSize).ceil();
  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}

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

  /// Ambil produk dengan pagination.
  Future<PaginatedResult<ProductEntity>> getProductsPaginated({
    int page = 1,
    int pageSize = 20,
    String? query,
    String? categoryId,
    bool onlyActive = true,
  }) async {
    var q = _db.select(_db.products);
    
    if (onlyActive) {
      q.where((t) => t.isActive.equals(true) & t.deletedAt.isNull());
    }
    if (categoryId != null) {
      q.where((t) => t.categoryId.equals(categoryId));
    }
    if (query != null && query.isNotEmpty) {
      final searchTerm = '%$query%';
      q.where((t) =>
          t.name.like(searchTerm) |
          t.sku.like(searchTerm) |
          t.barcode.like(searchTerm));
    }
    
    // Get total count
    final countQuery = _db.selectOnly(_db.products)..addColumns([_db.products.id.count()]);
    if (onlyActive) {
      countQuery.where(_db.products.isActive.equals(true) & _db.products.deletedAt.isNull());
    }
    if (categoryId != null) {
      countQuery.where(_db.products.categoryId.equals(categoryId));
    }
    if (query != null && query.isNotEmpty) {
      final searchTerm = '%$query%';
      countQuery.where(
          _db.products.name.like(searchTerm) |
          _db.products.sku.like(searchTerm) |
          _db.products.barcode.like(searchTerm));
    }
    final totalCountResult = await countQuery.getSingleOrNull();
    final totalCount = totalCountResult?.read(_db.products.id.count()) ?? 0;
    
    // Apply pagination
    // Apply pagination
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    q.limit(pageSize, offset: (page - 1) * pageSize);
    
    final rows = await q.get();
    final items = [
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
    
    return PaginatedResult(
      items: items,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
    );
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

/// Provider untuk produk dengan pagination.
final paginatedProductsProvider = FutureProvider.family<
    PaginatedResult<ProductEntity>,
    ({int page, int pageSize, String? query, String? categoryId})>(
  (ref, params) async {
    final repo = ref.watch(productRepositoryProvider);
    return repo.getProductsPaginated(
      page: params.page,
      pageSize: params.pageSize,
      query: params.query,
      categoryId: params.categoryId,
    );
  },
);

/// Stream produk aktif untuk UI (kompatibilitas mundur).
final productsProvider = StreamProvider<List<ProductEntity>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchProducts();
});

/// Stream produk menipis stok.
final lowStockProductsProvider = StreamProvider<List<ProductEntity>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchProducts().asyncMap((_) => repo.lowStockProducts());
});
