import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import 'pos_entity.dart';

/// Manajemen keranjang belanja, checkout, dan hold transaction (POS).
class PosRepository {
  PosRepository(this._db, this._dao);

  final AppDatabase _db;
  final SyncableDao _dao;
  final List<CartItem> _cart = [];

  List<CartItem> get cart => List.unmodifiable(_cart);

  double get subtotal => _cart.fold(0, (sum, i) => sum + i.lineTotal);

  void addItem(CartItem item) {
    final existing = _cart.indexWhere((c) => c.productId == item.productId);
    if (existing >= 0) {
      _cart[existing] = _cart[existing].copyWith(
        quantity: _cart[existing].quantity + item.quantity,
      );
    } else {
      _cart.add(item);
    }
  }

  void removeItem(String productId) {
    _cart.removeWhere((c) => c.productId == productId);
  }

  void updateQuantity(String productId, double quantity) {
    final idx = _cart.indexWhere((c) => c.productId == productId);
    if (idx >= 0) {
      _cart[idx] = _cart[idx].copyWith(quantity: quantity);
      if (quantity <= 0) _cart.removeAt(idx);
    }
  }

  void clear() {
    _cart.clear();
  }

  /// Validasi stok mencukupi untuk semua item di keranjang.
  /// Mengembalikan daftar produk yang stoknya tidak mencukupi.
  Future<List<String>> validateStock() async {
    final insufficient = <String>[];
    for (final item in _cart) {
      final product = await (_db.select(_db.products)
            ..where((t) => t.id.equals(item.productId)))
        .getSingleOrNull();
      if (product == null) {
        insufficient.add('${item.productName} (produk tidak ditemukan)');
        continue;
      }
      if (product.stock < item.quantity) {
        insufficient.add(
            '${item.productName} (tersisa ${product.stock.toInt()}, dibutuhkan ${item.quantity.toInt()})');
      }
    }
    return insufficient;
  }

  /// Checkout atomik: simpan Sale + SaleItems + StockMovements dalam satu
  /// transaksi Drift, lalu enqueue ke outbox. Stok dikurangi segera secara lokal.
  Future<String> checkout({
    required double discount,
    required double tax,
    required String paymentMethod,
    required bool isCredit,
    required String cashierId,
    required Map<String, double> paymentBreakdown,
    String? customerNameSnapshot,
  }) async {
    if (_cart.isEmpty) {
      throw StateError('Keranjang kosong, tidak bisa checkout');
    }

    // Validasi stok sebelum transaksi
    final insufficient = await validateStock();
    if (insufficient.isNotEmpty) {
      throw StateError('Stok tidak mencukupi: ${insufficient.join(', ')}');
    }

    final saleId = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final invoiceNumber =
        'INV-${now.millisecondsSinceEpoch}-${saleId.substring(0, 8)}';
    final subtotal = this.subtotal;
    final total = subtotal - discount + tax;

    await _db.transaction(() async {
      // 1. Simpan ke tabel Sales
      await _db.into(_db.sales).insert(SalesCompanion(
        id: Value(saleId),
        invoiceNumber: Value(invoiceNumber),
        customerNameSnapshot: Value(customerNameSnapshot),
        subtotal: Value(subtotal),
        discount: Value(discount),
        tax: Value(tax),
        total: Value(total),
        paid: Value(total),
        changeDue: const Value(0),
        paymentMethod: Value(paymentMethod),
        isCredit: Value(isCredit),
        status: const Value('completed'),
        cashierId: Value(cashierId),
        createdAt: Value(now),
        updatedAt: Value(now),
        version: const Value(1),
        syncStatus: const Value('pending'),
      ));

      // 2. Simpan SaleItems + buat StockMovements (kurangi stok)
      for (final item in _cart) {
        final itemId = const Uuid().v4();
        await _db.into(_db.saleItems).insert(SaleItemsCompanion(
          id: Value(itemId),
          saleId: Value(saleId),
          productId: Value(item.productId),
          productName: Value(item.productName),
          sku: Value(item.sku),
          unitPrice: Value(item.unitPrice),
          costPrice: Value(item.costPrice),
          quantity: Value(item.quantity),
          discount: const Value(0),
          lineTotal: Value(item.lineTotal),
          createdAt: Value(now),
          version: const Value(1),
          syncStatus: const Value('pending'),
        ));

        // Ambil stok terkini dan kurangi
        final product = await (_db.select(_db.products)
              ..where((t) => t.id.equals(item.productId)))
            .getSingleOrNull();
        if (product == null) {
          throw StateError('Produk ${item.productName} tidak ditemukan');
        }
        final newStock = product.stock - item.quantity;

        await (_db.update(_db.products)..where((t) => t.id.equals(item.productId)))
            .write(ProductsCompanion(
          stock: Value(newStock),
          updatedAt: Value(now),
          version: Value(product.version + 1),
          syncStatus: const Value('pending'),
        ));

        // 3. Catat StockMovements (sale = keluar, quantity negatif)
        await _db.into(_db.stockMovements).insert(StockMovementsCompanion(
          id: Value(const Uuid().v4()),
          productId: Value(item.productId),
        type: const Value('sale'),
        quantity: Value(-item.quantity),
        balanceAfter: Value(newStock),
        referenceType: const Value('sale'),
          referenceId: Value(saleId),
          note: Value('Penjualan $invoiceNumber'),
          createdBy: Value(cashierId),
          createdAt: Value(now),
          version: const Value(1),
          syncStatus: const Value('pending'),
        ));
      }

      // 4. Enqueue seluruh operasi ke outbox (sale, sale_items, stock_movements, products)
      await _dao.enqueue(
        entityType: 'sale',
        entityId: saleId,
        operation: SyncOperations.upsert,
        payload: {
          'id': saleId,
          'invoice_number': invoiceNumber,
          'subtotal': subtotal,
          'discount': discount,
          'tax': tax,
          'total': total,
          'payment_method': paymentMethod,
          'is_credit': isCredit,
          'cashier_id': cashierId,
          'customer_name_snapshot': customerNameSnapshot,
          'created_at': now.millisecondsSinceEpoch,
          'updated_at': now.millisecondsSinceEpoch,
        },
      );

      for (final item in _cart) {
        await _dao.enqueue(
          entityType: 'sale_item',
          entityId: item.productId,
          operation: SyncOperations.upsert,
          payload: {
            'id': const Uuid().v4(),
            'sale_id': saleId,
            'product_id': item.productId,
            'product_name': item.productName,
            'sku': item.sku,
            'unit_price': item.unitPrice,
            'cost_price': item.costPrice,
            'quantity': item.quantity,
            'line_total': item.lineTotal,
            'created_at': now.millisecondsSinceEpoch,
          },
        );
      }

      // Enqueue stock update per produk
      for (final item in _cart) {
        final product = await (_db.select(_db.products)
              ..where((t) => t.id.equals(item.productId)))
            .getSingleOrNull();
        if (product != null) {
          await _dao.enqueue(
            entityType: 'product',
            entityId: item.productId,
            operation: SyncOperations.upsert,
            payload: {
              'id': item.productId,
              'stock': product.stock,
              'updated_at': now.millisecondsSinceEpoch,
              'version': product.version,
            },
          );
        }
      }
    });

    clear();
    return saleId;
  }

  /// Simpan transaksi ke hold (ditanam di SQLite, belum checkout).
  /// Mengembalikan ID hold transaction.
  Future<String> holdTransaction({
    required double discount,
    required double tax,
    required String paymentMethod,
    required bool isCredit,
    required String cashierId,
    String? customerNameSnapshot,
  }) async {
    if (_cart.isEmpty) {
      throw StateError('Keranjang kosong, tidak bisa ditahan');
    }

    final holdId = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final invoiceNumber = 'HOLD-${now.millisecondsSinceEpoch}-${holdId.substring(0, 8)}';
    final subtotal = this.subtotal;
    final total = subtotal - discount + tax;

    final itemsSnapshot = List<CartItem>.from(_cart);

    await _db.into(_db.sales).insert(SalesCompanion(
      id: Value(holdId),
      invoiceNumber: Value(invoiceNumber),
      customerNameSnapshot: Value(customerNameSnapshot),
      subtotal: Value(subtotal),
      discount: Value(discount),
      tax: Value(tax),
       total: Value(total),
       paid: const Value(0),
       changeDue: const Value(0),
       paymentMethod: Value(paymentMethod),
       isCredit: Value(isCredit),
       status: const Value('held'),
       cashierId: Value(cashierId),
       createdAt: Value(now),
       updatedAt: Value(now),
       version: const Value(1),
       syncStatus: const Value('pending'),
     ));

     for (final item in itemsSnapshot) {
       await _db.into(_db.saleItems).insert(SaleItemsCompanion(
         id: Value(const Uuid().v4()),
         saleId: Value(holdId),
         productId: Value(item.productId),
         productName: Value(item.productName),
         sku: Value(item.sku),
         unitPrice: Value(item.unitPrice),
         costPrice: Value(item.costPrice),
         quantity: Value(item.quantity),
         discount: const Value(0),
         lineTotal: Value(item.lineTotal),
         createdAt: Value(now),
         version: const Value(1),
         syncStatus: const Value('pending'),
       ));
     }

    return holdId;
  }

  /// Ambil semua transaksi hold yang belum checkout.
  Future<List<HoldTransactionEntity>> getHoldTransactions() async {
    final rows = await (_db.select(_db.sales)
          ..where((t) => t.status.equals('held')))
        .get();
    final result = <HoldTransactionEntity>[];
    for (final row in rows) {
      final itemRows = await (_db.select(_db.saleItems)
            ..where((t) => t.saleId.equals(row.id)))
          .get();
      result.add(HoldTransactionEntity(
        id: row.id,
        invoiceNumber: row.invoiceNumber,
        items: [
          for (final ir in itemRows)
            CartItem(
              productId: ir.productId,
              productName: ir.productName,
              sku: ir.sku ?? '',
              unitPrice: ir.unitPrice,
              costPrice: ir.costPrice,
              quantity: ir.quantity,
            ),
        ],
        subtotal: row.subtotal,
        discount: row.discount,
        tax: row.tax,
        total: row.total,
        paymentMethod: row.paymentMethod,
        isCredit: row.isCredit,
        cashierId: row.cashierId ?? '',
        createdAt: row.createdAt,
        customerNameSnapshot: row.customerNameSnapshot,
      ));
    }
    return result;
  }

  /// Resume hold transaction: memuat item-item ke keranjang saat ini.
  Future<void> resumeHoldTransaction(String holdId) async {
    final row = await (_db.select(_db.sales)
          ..where((t) => t.id.equals(holdId)))
        .getSingleOrNull();
    if (row == null || row.status != 'held') {
      throw StateError('Transaksi hold tidak ditemukan');
    }

    _cart.clear();
    final itemRows = await (_db.select(_db.saleItems)
          ..where((t) => t.saleId.equals(holdId)))
        .get();
    for (final ir in itemRows) {
      _cart.add(CartItem(
        productId: ir.productId,
        productName: ir.productName,
        sku: ir.sku ?? '',
        unitPrice: ir.unitPrice,
        costPrice: ir.costPrice,
        quantity: ir.quantity,
      ));
    }
  }

  /// Hapus transaksi hold.
  Future<void> deleteHoldTransaction(String holdId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.saleItems)..where((t) => t.saleId.equals(holdId))).go();
      await (_db.delete(_db.sales)..where((t) => t.id.equals(holdId))).go();
    });
  }

  /// Checkout ulang transaksi hold (convert held → completed).
  Future<String> checkoutHold({
    required String holdId,
    required double discount,
    required double tax,
    required String paymentMethod,
    required bool isCredit,
    required String cashierId,
    required Map<String, double> paymentBreakdown,
  }) async {
    final row = await (_db.select(_db.sales)
          ..where((t) => t.id.equals(holdId)))
        .getSingleOrNull();
    if (row == null || row.status != 'held') {
      throw StateError('Transaksi hold tidak ditemukan');
    }

    // Muat item dari hold ke keranjang
    _cart.clear();
    final itemRows = await (_db.select(_db.saleItems)
          ..where((t) => t.saleId.equals(holdId)))
        .get();
    for (final ir in itemRows) {
      _cart.add(CartItem(
        productId: ir.productId,
        productName: ir.productName,
        sku: ir.sku ?? '',
        unitPrice: ir.unitPrice,
        costPrice: ir.costPrice,
        quantity: ir.quantity,
      ));
    }

    // Gunakan checkout biasa (transaksional, validasi stok, dll)
    final saleId = await checkout(
      discount: discount,
      tax: tax,
      paymentMethod: paymentMethod,
      isCredit: isCredit,
      cashierId: cashierId,
      paymentBreakdown: paymentBreakdown,
      customerNameSnapshot: row.customerNameSnapshot,
    );

    // Tandai hold sebagai voided
    await (_db.update(_db.sales)..where((t) => t.id.equals(holdId)))
        .write(SalesCompanion(
        status: const Value('voided'),
      updatedAt: Value(DateTime.now().toUtc()),
      version: Value(row.version + 1),
    ));

    return saleId;
  }
}

final posRepositoryProvider = Provider<PosRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(syncDaoProvider);
  return PosRepository(db, dao);
});

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref.read(posRepositoryProvider));
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier(this._repo) : super([]);

  final PosRepository _repo;

  List<CartItem> get cart => _repo.cart;

  double get subtotal => _repo.subtotal;

  void addItem(CartItem item) {
    _repo.addItem(item);
    state = [..._repo.cart];
  }

  void removeItem(String productId) {
    _repo.removeItem(productId);
    state = [..._repo.cart];
  }

  void updateQuantity(String productId, double quantity) {
    _repo.updateQuantity(productId, quantity);
    state = [..._repo.cart];
  }

  void clear() {
    _repo.clear();
    state = [];
  }
}