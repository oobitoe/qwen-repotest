import 'package:drift/drift.dart';

import 'app_database.dart';
import 'sync_dao.dart';

/// Membangun metadata generik dari instance tabel drift.
///
/// [jsonMap] memetakan snapshot JSON (snake_case, format Supabase) ke
/// companion typed milik tabel yang sama.
TableMeta _meta<T extends Table>(
  String entityType,
  TableInfo<T, dynamic> table,
  Insertable<dynamic> Function(Map<String, dynamic> json) jsonMap,
) {
  return TableMeta(
    entityType: entityType,
    tableName: table.actualTableName,
    columns: [for (final c in table.$columns) (c.name, c.type)],
    toCompanion: jsonMap,
  );
}

bool _registered = false;
AppDatabase? _storedDb;

/// Parse tanggal aman dari berbagai sumber (ISO8601, integer ms, integer detik).
///
/// Konsisten dengan format Supabase (ISO8601 UTC) dan SQLite Drift
/// (integer millisecondsSinceEpoch UTC). Jika integer < 1e12 dianggap detik
/// Unix epoch dan dikalikan 1000 → milidetik.
DateTime? _safeParseDateTime(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v.toUtc();
  final s = v.toString();
  final asNum = int.tryParse(s);
  if (asNum != null) {
    final ms = asNum < 1000000000000 ? asNum * 1000 : asNum;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }
  return DateTime.tryParse(s)?.toUtc();
}

/// Daftarkan seluruh tabel yang ikut program sinkronisasi.
/// Idempoten — aman dipanggil berkali-kali.
/// [db] - Database instance yang sudah diinisialisasi (singleton). Jika tidak
/// diberikan, akan menggunakan instance yang tersimpan dari pemanggilan pertama.
void registerAllSyncMetas([AppDatabase? db]) {
  // Store the database instance for later calls without arguments
  if (db != null) {
    _storedDb = db;
  }

  final effectiveDb = db ?? _storedDb;
  if (effectiveDb == null) {
    throw StateError(
        'registerAllSyncMetas called without database instance. Call with AppDatabase first.');
  }

  if (_registered) return;
  _registered = true;

  // --- Local helpers ---
  DateTime? dt(Object? v) => _safeParseDateTime(v);
  int i(Object? v, [int fallback = 1]) => (v as num?)?.toInt() ?? fallback;
  double d(Object? v, [double fallback = 0]) =>
      (v as num?)?.toDouble() ?? fallback;
  String s(Object? v) => v.toString();
  bool b(Object? v) => v == true || v == 'true' || v == 1;
  double? dn(Object? v) => v == null ? null : (v as num).toDouble();
  String? sn(Object? v) => v?.toString();

  // Use effectiveDb since we've verified it's not null above
  final db_ = effectiveDb;
  SyncableDao.register(_meta('business', db_.businesses, (j) => BusinessesCompanion(
        id: Value(s(j['id'])),
        name: Value(s(j['name'])),
        currency: Value(sn(j['currency']) ?? 'IDR'),
        timezone: Value(sn(j['timezone']) ?? 'Asia/Jakarta'),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('store', db_.stores, (j) => StoresCompanion(
        id: Value(s(j['id'])),
        businessId: Value(s(j['business_id'])),
        name: Value(s(j['name'])),
        address: Value(sn(j['address'])),
        phone: Value(sn(j['phone'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('profile', db_.profiles, (j) => ProfilesCompanion(
        id: Value(s(j['id'])),
        email: Value(s(j['email'])),
        fullName: Value(s(j['full_name'])),
        role: Value(sn(j['role']) ?? 'kasir'),
        isActive: Value(b(j['is_active'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('category', db_.categories, (j) => CategoriesCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id']) ?? 'local'),
        name: Value(s(j['name'])),
        isActive: Value(b(j['is_active'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('unit', db_.units, (j) => UnitsCompanion(
        id: Value(s(j['id'])),
        name: Value(s(j['name'])),
        abbreviation: Value(s(j['abbreviation'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('product', db_.products, (j) => ProductsCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id']) ?? 'local'),
        sku: Value(s(j['sku'])),
        barcode: Value(sn(j['barcode'])),
        name: Value(s(j['name'])),
        description: Value(sn(j['description'])),
        categoryId: Value(sn(j['category_id'])),
        unitId: Value(sn(j['unit_id'])),
        costPrice: Value(d(j['cost_price'])),
        sellPrice: Value(d(j['sell_price'])),
        wholesalePrice: Value(dn(j['wholesale_price'])),
        minStock: Value(d(j['min_stock'])),
        stock: Value(d(j['stock'])),
        isActive: Value(b(j['is_active'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
        imageUrl: Value(sn(j['image_url'])),
      )));

  SyncableDao.register(
      _meta('stock_movement', db_.stockMovements, (j) => StockMovementsCompanion(
            id: Value(s(j['id'])),
            productId: Value(s(j['product_id'])),
            type: Value(s(j['type'])),
            quantity: Value(d(j['quantity'])),
            balanceAfter: Value(d(j['balance_after'])),
            referenceType: Value(sn(j['reference_type'])),
            referenceId: Value(sn(j['reference_id'])),
            note: Value(sn(j['note'])),
            createdBy: Value(sn(j['created_by'])),
            createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
            version: Value(i(j['version'])),
            syncStatus: const Value(SyncStatuses.synced),
          )));

  SyncableDao.register(_meta('supplier', db_.suppliers, (j) => SuppliersCompanion(
        id: Value(s(j['id'])),
        name: Value(s(j['name'])),
        phone: Value(sn(j['phone'])),
        email: Value(sn(j['email'])),
        address: Value(sn(j['address'])),
        notes: Value(sn(j['notes'])),
        isActive: Value(b(j['is_active'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('customer', db_.customers, (j) => CustomersCompanion(
        id: Value(s(j['id'])),
        code: Value(sn(j['code'])),
        name: Value(s(j['name'])),
        phone: Value(sn(j['phone'])),
        email: Value(sn(j['email'])),
        address: Value(sn(j['address'])),
        notes: Value(sn(j['notes'])),
        isActive: Value(b(j['is_active'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('sale', db_.sales, (j) => SalesCompanion(
        id: Value(s(j['id'])),
        invoiceNumber: Value(s(j['invoice_number'])),
        customerNameSnapshot: Value(sn(j['customer_name_snapshot'])),
        subtotal: Value(d(j['subtotal'])),
        discount: Value(d(j['discount'])),
        tax: Value(d(j['tax'])),
        total: Value(d(j['total'])),
        paid: Value(d(j['paid'])),
        changeDue: Value(d(j['change_due'])),
        paymentMethod: Value(sn(j['payment_method']) ?? 'cash'),
        isCredit: Value(b(j['is_credit'])),
        status: Value(sn(j['status']) ?? 'completed'),
        cashierId: Value(sn(j['cashier_id'])),
        note: Value(sn(j['note'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('sale_item', db_.saleItems, (j) => SaleItemsCompanion(
        id: Value(s(j['id'])),
        saleId: Value(s(j['sale_id'])),
        productId: Value(s(j['product_id'])),
        productName: Value(s(j['product_name'])),
        sku: Value(sn(j['sku'])),
        unitPrice: Value(d(j['unit_price'])),
        costPrice: Value(d(j['cost_price'])),
        quantity: Value(d(j['quantity'])),
        discount: Value(d(j['discount'])),
        lineTotal: Value(d(j['line_total'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(
      _meta('expense_category', db_.expenseCategories,
          (j) => ExpenseCategoriesCompanion(
        id: Value(s(j['id'])),
        name: Value(s(j['name'])),
        isActive: Value(b(j['is_active'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('expense', db_.expenses, (j) => ExpensesCompanion(
        id: Value(s(j['id'])),
        categoryId: Value(sn(j['category_id'])),
        description: Value(s(j['description'])),
        amount: Value(d(j['amount'])),
        paymentMethod: Value(sn(j['payment_method']) ?? 'cash'),
        createdBy: Value(sn(j['created_by'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(
      _meta('income_category', db_.incomeCategories,
          (j) => IncomeCategoriesCompanion(
        id: Value(s(j['id'])),
        name: Value(s(j['name'])),
        isActive: Value(b(j['is_active'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('income', db_.incomeEntries, (j) => IncomeEntriesCompanion(
        id: Value(s(j['id'])),
        categoryId: Value(sn(j['category_id'])),
        description: Value(s(j['description'])),
        amount: Value(d(j['amount'])),
        paymentMethod: Value(sn(j['payment_method']) ?? 'cash'),
        createdBy: Value(sn(j['created_by'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('cash_register', db_.cashRegisters,
      (j) => CashRegistersCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id']) ?? 'local'),
        name: Value(s(j['name'])),
        openingBalance: Value(d(j['opening_balance'])),
        isActive: Value(b(j['is_active'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('cash_session', db_.cashSessions,
      (j) => CashSessionsCompanion(
        id: Value(s(j['id'])),
        registerId: Value(s(j['register_id'])),
        openedBy: Value(sn(j['opened_by'])),
        openedAt: Value(dt(j['opened_at']) ?? DateTime.now().toUtc()),
        closedAt: Value(dt(j['closed_at'])),
        openingBalance: Value(d(j['opening_balance'])),
        expectedBalance: Value(dn(j['expected_balance'])),
        actualBalance: Value(dn(j['actual_balance'])),
        difference: Value(dn(j['difference'])),
        status: Value(sn(j['status']) ?? 'open'),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('cash_movement', db_.cashMovements,
      (j) => CashMovementsCompanion(
        id: Value(s(j['id'])),
        sessionId: Value(sn(j['session_id'])),
        type: Value(s(j['type'])),
        amount: Value(d(j['amount'])),
        referenceType: Value(sn(j['reference_type'])),
        referenceId: Value(sn(j['reference_id'])),
        note: Value(sn(j['note'])),
        createdBy: Value(sn(j['created_by'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('account', db_.accounts,
      (j) => AccountsCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id']) ?? 'local'),
        name: Value(s(j['name'])),
        type: Value(s(j['type'])),
        balance: Value(d(j['balance'])),
        isActive: Value(b(j['is_active'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('account_transaction', db_.accountTransactions,
      (j) => AccountTransactionsCompanion(
        id: Value(s(j['id'])),
        accountId: Value(s(j['account_id'])),
        type: Value(s(j['type'])),
        amount: Value(d(j['amount'])),
        referenceType: Value(sn(j['reference_type'])),
        referenceId: Value(sn(j['reference_id'])),
        createdBy: Value(sn(j['created_by'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('debt', db_.debts,
      (j) => DebtsCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id']) ?? 'local'),
        supplierId: Value(sn(j['supplier_id'])),
        customerId: Value(sn(j['customer_id'])),
        type: Value(s(j['type'])),
        amount: Value(d(j['amount'])),
        paidAmount: Value(d(j['paid_amount'])),
        status: Value(sn(j['status']) ?? 'open'),
        dueDate: Value(dt(j['due_date'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('debt_payment', db_.debtPayments,
      (j) => DebtPaymentsCompanion(
        id: Value(s(j['id'])),
        debtId: Value(s(j['debt_id'])),
        amount: Value(d(j['amount'])),
        paidAt: Value(dt(j['paid_at']) ?? DateTime.now().toUtc()),
        createdBy: Value(sn(j['created_by'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('purchase', db_.purchases, (j) => PurchasesCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id']) ?? 'local'),
        referenceNumber: Value(s(j['reference_number'])),
        supplierId: Value(sn(j['supplier_id'])),
        supplierName: Value(s(j['supplier_name'])),
        status: Value(sn(j['status']) ?? 'completed'),
        subtotal: Value(d(j['subtotal'])),
        discount: Value(d(j['discount'])),
        tax: Value(d(j['tax'])),
        total: Value(d(j['total'])),
        paymentMethod: Value(sn(j['payment_method']) ?? 'cash'),
        isCredit: Value(b(j['is_credit'])),
        createdBy: Value(sn(j['created_by'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('purchase_item', db_.purchaseItems, (j) => PurchaseItemsCompanion(
        id: Value(s(j['id'])),
        purchaseId: Value(s(j['purchase_id'])),
        productId: Value(s(j['product_id'])),
        productName: Value(s(j['product_name'])),
        sku: Value(sn(j['sku'])),
        unitPrice: Value(d(j['unit_price'])),
        costPrice: Value(d(j['cost_price'])),
        quantity: Value(d(j['quantity'])),
        receivedQuantity: Value(d(j['received_quantity'])),
        lineTotal: Value(d(j['line_total'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('purchase_payment', db_.purchasePayments, (j) => PurchasePaymentsCompanion(
        id: Value(s(j['id'])),
        purchaseId: Value(s(j['purchase_id'])),
        amount: Value(d(j['amount'])),
        paymentMethod: Value(s(j['payment_method'])),
        paidAt: Value(dt(j['paid_at']) ?? DateTime.now().toUtc()),
        createdBy: Value(sn(j['created_by'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('product_variant', db_.productVariants, (j) => ProductVariantsCompanion(
        id: Value(s(j['id'])),
        productId: Value(s(j['product_id'])),
        name: Value(s(j['name'])),
        sku: Value(sn(j['sku'])),
        priceModifier: Value(d(j['price_modifier'])),
        isActive: Value(b(j['is_active'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('product_barcode', db_.productBarcodes, (j) => ProductBarcodesCompanion(
        id: Value(s(j['id'])),
        productId: Value(s(j['product_id'])),
        barcode: Value(s(j['barcode'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('product_price', db_.productPrices, (j) => ProductPricesCompanion(
        id: Value(s(j['id'])),
        productId: Value(s(j['product_id'])),
        price: Value(d(j['price'])),
        startDate: Value(dt(j['start_date'])),
        endDate: Value(dt(j['end_date'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('product_image', db_.productImages, (j) => ProductImagesCompanion(
        id: Value(s(j['id'])),
        productId: Value(s(j['product_id'])),
        url: Value(s(j['url'])),
        storagePath: Value(sn(j['storage_path'])),
        isPrimary: Value(b(j['is_primary'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('purchase_order', db_.purchaseOrders, (j) => PurchaseOrdersCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id']) ?? 'local'),
        supplierId: Value(s(j['supplier_id'])),
        referenceNumber: Value(s(j['reference_number'])),
        status: Value(sn(j['status']) ?? 'draft'),
        subtotal: Value(d(j['subtotal'])),
        discount: Value(d(j['discount'])),
        tax: Value(d(j['tax'])),
        total: Value(d(j['total'])),
        createdBy: Value(sn(j['created_by'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('purchase_order_item', db_.purchaseOrderItems, (j) => PurchaseOrderItemsCompanion(
        id: Value(s(j['id'])),
        orderId: Value(s(j['order_id'])),
        productId: Value(s(j['product_id'])),
        productNameSnapshot: Value(s(j['product_name_snapshot'])),
        sku: Value(sn(j['sku'])),
        unitPrice: Value(d(j['unit_price'])),
        quantity: Value(d(j['quantity'])),
        receivedQuantity: Value(d(j['received_quantity'])),
        lineTotal: Value(d(j['line_total'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('purchase_return', db_.purchaseReturns, (j) => PurchaseReturnsCompanion(
        id: Value(s(j['id'])),
        purchaseId: Value(s(j['purchase_id'])),
        referenceNumber: Value(s(j['reference_number'])),
        total: Value(d(j['total'])),
        createdBy: Value(sn(j['created_by'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('purchase_return_item', db_.purchaseReturnItems, (j) => PurchaseReturnItemsCompanion(
        id: Value(s(j['id'])),
        returnId: Value(s(j['return_id'])),
        productId: Value(s(j['product_id'])),
        quantity: Value(d(j['quantity'])),
        unitPrice: Value(d(j['unit_price'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('sale_payment', db_.salePayments, (j) => SalePaymentsCompanion(
        id: Value(s(j['id'])),
        saleId: Value(s(j['sale_id'])),
        amount: Value(d(j['amount'])),
        paymentMethod: Value(s(j['payment_method'])),
        paidAt: Value(dt(j['paid_at']) ?? DateTime.now().toUtc()),
        createdBy: Value(sn(j['created_by'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('sale_return', db_.saleReturns, (j) => SaleReturnsCompanion(
        id: Value(s(j['id'])),
        saleId: Value(s(j['sale_id'])),
        referenceNumber: Value(s(j['reference_number'])),
        total: Value(d(j['total'])),
        createdBy: Value(sn(j['created_by'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('sale_return_item', db_.saleReturnItems, (j) => SaleReturnItemsCompanion(
        id: Value(s(j['id'])),
        returnId: Value(s(j['return_id'])),
        productId: Value(s(j['product_id'])),
        quantity: Value(d(j['quantity'])),
        unitPrice: Value(d(j['unit_price'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('stock_transfer', db_.stockTransfers, (j) => StockTransfersCompanion(
        id: Value(s(j['id'])),
        fromStoreId: Value(sn(j['from_store_id'])),
        toStoreId: Value(sn(j['to_store_id'])),
        referenceNumber: Value(s(j['reference_number'])),
        status: Value(sn(j['status']) ?? 'pending'),
        createdBy: Value(sn(j['created_by'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('stock_transfer_item', db_.stockTransferItems, (j) => StockTransferItemsCompanion(
        id: Value(s(j['id'])),
        transferId: Value(s(j['transfer_id'])),
        productId: Value(s(j['product_id'])),
        quantity: Value(d(j['quantity'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('customer_address', db_.customerAddresses, (j) => CustomerAddressesCompanion(
        id: Value(s(j['id'])),
        customerId: Value(s(j['customer_id'])),
        label: Value(s(j['label'])),
        address: Value(s(j['address'])),
        isDefault: Value(b(j['is_default'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('business_setting', db_.businessSettings, (j) => BusinessSettingsCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id']) ?? 'local'),
        key: Value(s(j['key'])),
        value: Value(s(j['value'])),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('store_setting', db_.storeSettings, (j) => StoreSettingsCompanion(
        id: Value(s(j['id'])),
        storeId: Value(sn(j['store_id']) ?? 'local'),
        key: Value(s(j['key'])),
        value: Value(s(j['value'])),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('tax_setting', db_.taxSettings, (j) => TaxSettingsCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id']) ?? 'local'),
        name: Value(s(j['name'])),
        rate: Value(d(j['rate'])),
        isActive: Value(b(j['is_active'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('payment_method_config', db_.paymentMethodsConfig, (j) => PaymentMethodsConfigCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id']) ?? 'local'),
        code: Value(s(j['code'])),
        name: Value(s(j['name'])),
        isActive: Value(b(j['is_active'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('device', db_.devices, (j) => DevicesCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id'])),
        deviceId: Value(s(j['device_id'])),
        name: Value(sn(j['name'])),
        lastSeenAt: Value(dt(j['last_seen_at'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('financial_adjustment', db_.financialAdjustments, (j) => FinancialAdjustmentsCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id']) ?? 'local'),
        description: Value(s(j['description'])),
        amount: Value(d(j['amount'])),
        type: Value(s(j['type'])),
        createdBy: Value(sn(j['created_by'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('role', db_.roles, (j) => RolesCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id']) ?? 'local'),
        name: Value(s(j['name'])),
        description: Value(sn(j['description'])),
        isSystem: Value(b(j['is_system'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('permission', db_.permissions, (j) => PermissionsCompanion(
        id: Value(s(j['id'])),
        code: Value(s(j['code'])),
        description: Value(sn(j['description'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('role_permission', db_.rolePermissions, (j) => RolePermissionsCompanion(
        id: Value(s(j['id'])),
        roleId: Value(s(j['role_id'])),
        permissionId: Value(s(j['permission_id'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('business_member', db_.businessMembers, (j) => BusinessMembersCompanion(
        id: Value(s(j['id'])),
        businessId: Value(s(j['business_id'])),
        userId: Value(s(j['user_id'])),
        role: Value(s(j['role'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('user_store_access', db_.userStoreAccess, (j) => UserStoreAccessCompanion(
        id: Value(s(j['id'])),
        userId: Value(s(j['user_id'])),
        storeId: Value(s(j['store_id'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('sale_sequence', db_.saleSequences, (j) => SaleSequencesCompanion(
        id: Value(s(j['id'])),
        businessId: Value(sn(j['business_id']) ?? 'local'),
        storeId: Value(sn(j['store_id'])),
        prefix: Value(s(j['prefix'])),
        lastNumber: Value(i(j['lastNumber'])),
        date: Value(dt(j['date']) ?? DateTime.now().toUtc()),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('audit_log', db_.auditLogs,
      (j) => AuditLogsCompanion.insert(
        id: s(j['id']),
        userId: s(j['user_id']),
        userName: s(j['user_name']),
        action: s(j['action']),
        entityType: s(j['entity_type']),
        entityId: s(j['entity_id']),
        description: s(j['description']),
        oldValue: Value(sn(j['old_value'])),
        newValue: Value(sn(j['new_value'])),
        ipAddress: Value(sn(j['ip_address'])),
        deviceInfo: Value(sn(j['device_info'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
      )));
}
