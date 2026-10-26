import 'package:drift/drift.dart';
import 'package:drift/native.dart' show NativeDatabase;

import '../core/database/app_database.dart';
import '../core/database/sync_dao.dart';
import '../core/database/sync_engine.dart';
import '../core/database/sync_registry.dart';

/// Database in-memory khusus pengujian.
AppDatabase testDatabase() => AppDatabase(NativeDatabase.memory());

/// Seed data demo untuk dashboard & pengujian widget: produk, penjualan 14
/// hari terakhir, pengeluaran, dan beberapa item outbox tertunda.
Future<void> seedDemoData(AppDatabase db) async {
  registerAllSyncMetas();
  final dao = SyncableDao(db);
  final now = DateTime.now();

  // Kategori
  Future<String> addCategory(String id, String name) async {
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(id: id, name: name),
        );
    return id;
  }

  final catFood = await addCategory('cat-food', 'Makanan');
  final catDrink = await addCategory('cat-drink', 'Minuman');
  final catSnack = await addCategory('cat-snack', 'Camilan');

  // Satuan
  await db.into(db.units).insert(
        UnitsCompanion.insert(id: 'u-pcs', name: 'Pieces', abbreviation: 'pcs'),
      );

  // Produk (stok bervariasi, sebagian di bawah minimum → stok menipis)
  Future<void> addProduct({
    required String id,
    required String sku,
    required String name,
    required double price,
    required double cost,
    required double stock,
    required double minStock,
    required String categoryId,
  }) =>
      db.into(db.products).insert(ProductsCompanion.insert(
            id: id,
            sku: sku,
            name: name,
            categoryId: Value(categoryId),
            unitId: const Value('u-pcs'),
            sellPrice: price,
            costPrice: Value(cost),
            minStock: Value(minStock),
            stock: Value(stock),
            syncStatus: const Value(SyncStatuses.synced),
          ));

  await addProduct(id: 'p-1', sku: 'SKU-001', name: 'Nasi Goreng Spesial', price: 18000, cost: 11000, stock: 45, minStock: 10, categoryId: catFood);
  await addProduct(id: 'p-2', sku: 'SKU-002', name: 'Es Teh Manis', price: 6000, cost: 2500, stock: 3, minStock: 15, categoryId: catDrink);
  await addProduct(id: 'p-3', sku: 'SKU-003', name: 'Kerupuk Udang', price: 8000, cost: 5000, stock: 60, minStock: 20, categoryId: catSnack);
  await addProduct(id: 'p-4', sku: 'SKU-004', name: 'Ayam Geprek', price: 16000, cost: 9500, stock: 2, minStock: 8, categoryId: catFood);
  await addProduct(id: 'p-5', sku: 'SKU-005', name: 'Jus Alpukat', price: 12000, cost: 6000, stock: 25, minStock: 5, categoryId: catDrink);
  await addProduct(id: 'p-6', sku: 'SKU-006', name: 'Kentang Goreng', price: 14000, cost: 7500, stock: 0, minStock: 10, categoryId: catSnack);

  // Penjualan 14 hari terakhir (pola naik-turun agar grafik menarik)
  final dailyTotals = <double>[
    420000, 510000, 380000, 620000, 590000, 730000, 810000, // minggu lalu
    460000, 540000, 610000, 580000, 700000, 850000, 920000, // minggu ini
  ];
  var invoice = 1000;
  for (var d = 13; d >= 0; d--) {
    final total = dailyTotals[13 - d];
    final createdAt = now.subtract(Duration(days: d)).copyWith(hour: 12);
    final saleId = 'sale-$d';
    await db.into(db.sales).insert(SalesCompanion.insert(
          id: saleId,
          invoiceNumber: 'INV-${invoice++}',
          subtotal: total,
          total: total,
          paid: Value(total),
          createdAt: Value(createdAt),
          updatedAt: Value(createdAt),
          syncStatus: const Value(SyncStatuses.synced),
        ));
    await db.into(db.saleItems).insert(SaleItemsCompanion.insert(
          id: 'si-$d',
          saleId: saleId,
          productId: 'p-1',
          productName: 'Nasi Goreng Spesial',
          sku: const Value('SKU-001'),
          unitPrice: 18000,
          quantity: (total / 18000).ceilToDouble(),
          lineTotal: total,
          createdAt: Value(createdAt),
          syncStatus: const Value(SyncStatuses.synced),
        ));
  }

  // Beberapa transaksi masih tertunda (belum tersinkron) → indikator sync
  await db.into(db.sales).insert(SalesCompanion.insert(
        id: 'sale-pending-1',
        invoiceNumber: 'INV-P-001',
        subtotal: 150000,
        total: 150000,
        paid: const Value(150000),
        syncStatus: const Value(SyncStatuses.pending),
      ));
  await dao.enqueue(
    entityType: 'sale',
    entityId: 'sale-pending-1',
    operation: SyncOperations.upsert,
    payload: {'id': 'sale-pending-1', 'invoice_number': 'INV-P-001', 'total': 150000},
    nextRetryAt: DateTime.now().toUtc(),
  );

  // Pengeluaran
  await db.into(db.expenseCategories).insert(
        ExpenseCategoriesCompanion.insert(id: 'ec-op', name: 'Operasional'),
      );
  await db.into(db.expenses).insert(ExpensesCompanion.insert(
        id: 'e-1',
        categoryId: const Value('ec-op'),
        description: 'Beli gas LPG',
        amount: 120000,
        createdAt: Value(DateTime(now.year, now.month, now.day - 1)),
      ));

  // Aktivitas terbaru (stock movements sebagai sumber aktivitas)
  await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
        id: 'sm-1',
        productId: 'p-1',
        type: 'sale',
        quantity: -4,
        balanceAfter: 45,
        referenceType: const Value('sale'),
        referenceId: const Value('sale-0'),
        createdAt: Value(DateTime(now.year, now.month, now.day, 14, 5)),
      ));
  await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
        id: 'sm-2',
        productId: 'p-3',
        type: 'purchase',
        quantity: 20,
        balanceAfter: 60,
        referenceType: const Value('purchase'),
        createdAt: Value(DateTime(now.year, now.month, now.day, 9, 30)),
      ));
}

/// Engine dengan transport in-memory untuk pengujian/preview.
SyncEngine testSyncEngine(AppDatabase db, {bool online = true}) {
  final transport = InMemorySyncTransport(online: online);
  return SyncEngine(db: db, transport: transport);
}
