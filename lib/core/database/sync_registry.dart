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

/// Daftarkan seluruh tabel yang ikut program sinkronisasi.
/// Idempoten — aman dipanggil berkali-kali.
void registerAllSyncMetas() {
  if (_registered) return;
  _registered = true;

  DateTime? dt(Object? v) =>
      v == null ? null : DateTime.parse(v.toString()).toUtc();
  int i(Object? v, [int fallback = 1]) => (v as num?)?.toInt() ?? fallback;
  double d(Object? v, [double fallback = 0]) =>
      (v as num?)?.toDouble() ?? fallback;
  String s(Object? v) => v.toString();
  bool b(Object? v) => v == true || v == 'true' || v == 1;
  double? dn(Object? v) => v == null ? null : (v as num).toDouble();
  String? sn(Object? v) => v?.toString();

  final db = AppDatabase(_headlessExecutor);

  SyncableDao.register(_meta('business', db.businesses, (j) => BusinessesCompanion(
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

  SyncableDao.register(_meta('store', db.stores, (j) => StoresCompanion(
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

  SyncableDao.register(_meta('profile', db.profiles, (j) => ProfilesCompanion(
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

  SyncableDao.register(_meta('category', db.categories, (j) => CategoriesCompanion(
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

  SyncableDao.register(_meta('unit', db.units, (j) => UnitsCompanion(
        id: Value(s(j['id'])),
        name: Value(s(j['name'])),
        abbreviation: Value(s(j['abbreviation'])),
        createdAt: Value(dt(j['created_at']) ?? DateTime.now().toUtc()),
        updatedAt: Value(dt(j['updated_at']) ?? DateTime.now().toUtc()),
        deletedAt: Value(dt(j['deleted_at'])),
        version: Value(i(j['version'])),
        syncStatus: const Value(SyncStatuses.synced),
      )));

  SyncableDao.register(_meta('product', db.products, (j) => ProductsCompanion(
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
      )));

  SyncableDao.register(
      _meta('stock_movement', db.stockMovements, (j) => StockMovementsCompanion(
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

  SyncableDao.register(_meta('supplier', db.suppliers, (j) => SuppliersCompanion(
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

  SyncableDao.register(_meta('customer', db.customers, (j) => CustomersCompanion(
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

  SyncableDao.register(_meta('sale', db.sales, (j) => SalesCompanion(
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

  SyncableDao.register(_meta('sale_item', db.saleItems, (j) => SaleItemsCompanion(
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
      _meta('expense_category', db.expenseCategories,
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

  SyncableDao.register(_meta('expense', db.expenses, (j) => ExpensesCompanion(
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
      _meta('income_category', db.incomeCategories,
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

  SyncableDao.register(_meta('income', db.incomeEntries, (j) => IncomeEntriesCompanion(
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

  SyncableDao.register(_meta('cash_register', db.cashRegisters,
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

  SyncableDao.register(_meta('cash_session', db.cashSessions,
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

  SyncableDao.register(_meta('cash_movement', db.cashMovements,
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

  SyncableDao.register(_meta('account', db.accounts,
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

  SyncableDao.register(_meta('account_transaction', db.accountTransactions,
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
}

/// Executor sementara hanya untuk membaca metadata kolom saat registrasi
/// (tidak pernah membuka koneksi sungguhan).
final QueryExecutor _headlessExecutor = _NoopExecutor();

class _NoopExecutor extends QueryExecutor {
  @override
  Future<bool> ensureOpen(_) async => false;
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'Executor registrasi tidak boleh dipakai untuk query nyata');
}
