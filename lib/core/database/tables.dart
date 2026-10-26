import 'package:drift/drift.dart';

/// Status entitas dalam siklus sinkronisasi.
class SyncStatuses {
  const SyncStatuses._();
  static const String pending = 'pending';
  static const String synced = 'synced';
  static const String conflict = 'conflict';
  static const String error = 'error';
}

/// Operasi pada antrean sinkronisasi.
class SyncOperations {
  const SyncOperations._();
  static const String upsert = 'upsert';
  static const String delete = 'delete';
}

class SyncQueueStatuses {
  const SyncQueueStatuses._();
  static const String waiting = 'waiting';
  static const String inProgress = 'in_progress';
  static const String done = 'done';
  static const String failed = 'failed';
}

// ---------- Tabel organisasi & pengguna ----------

class Businesses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  TextColumn get timezone => text().withDefault(const Constant('Asia/Jakarta'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Stores extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Profil pengguna lokal (autentikasi utama lewat Supabase Auth).
class Profiles extends Table {
  TextColumn get id => text()(); // uid Supabase Auth
  TextColumn get email => text()();
  TextColumn get fullName => text()();
  TextColumn get role => text()(); // owner|admin|manager|kasir|staff_gudang
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------- Produk ----------

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().withDefault(const Constant('local'))();
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Units extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get abbreviation => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().withDefault(const Constant('local'))();
  TextColumn get sku => text().unique()();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get unitId => text().nullable().references(Units, #id)();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get sellPrice => real()();
  RealColumn get wholesalePrice => real().nullable()();
  RealColumn get minStock => real().withDefault(const Constant(0))();
  RealColumn get stock => real().withDefault(const Constant(0))(); // cache; sumber: stock_movements
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ledger pergerakan stok — satu-satunya sumber kebenaran perubahan stok.
class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  /// initial | purchase | sale | sale_return | purchase_return | adjustment | transfer_in | transfer_out | correction
  TextColumn get type => text()();
  RealColumn get quantity => real()(); // positif = masuk, negatif = keluar
  RealColumn get balanceAfter => real()();
  TextColumn get referenceType => text().nullable()(); // sale | purchase | adjustment | ...
  TextColumn get referenceId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------- Pelanggan & Supplier ----------

class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().nullable()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get tier => text().withDefault(const Constant('Regular'))();
  IntColumn get rewardPoints => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------- Inventaris: penyesuaian dan opname ----------

class StockAdjustments extends Table {
  TextColumn get id => text()();
  TextColumn get referenceNumber => text()();
  TextColumn get note => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class StockAdjustmentItems extends Table {
  TextColumn get id => text()();
  TextColumn get adjustmentId => text().references(StockAdjustments, #id)();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get quantityBefore => real()();
  RealColumn get quantityAfter => real()();
  TextColumn get reason => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class StockOpnames extends Table {
  TextColumn get id => text()();
  TextColumn get referenceNumber => text()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get approvedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class StockOpnameItems extends Table {
  TextColumn get id => text()();
  TextColumn get opnameId => text().references(StockOpnames, #id)();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get systemStock => real()();
  RealColumn get countedStock => real()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------- Penjualan (POS) ----------

class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceNumber => text().unique()();
  TextColumn get customerNameSnapshot => text().nullable()();
  RealColumn get subtotal => real()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
  RealColumn get paid => real().withDefault(const Constant(0))();
  RealColumn get changeDue => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  BoolColumn get isCredit => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('completed'))(); // completed|voided
  TextColumn get cashierId => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class SaleItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get productId => text().references(Products, #id)();
  // Snapshot agar histori tidak berubah saat produk diedit:
  TextColumn get productName => text()();
  TextColumn get sku => text().nullable()();
  RealColumn get unitPrice => real()();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get quantity => real()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get lineTotal => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------- Pengeluaran & Pemasukan ----------

class ExpenseCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().nullable().references(ExpenseCategories, #id)();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class IncomeCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class IncomeEntries extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().nullable().references(IncomeCategories, #id)();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------- Antrean Sinkronisasi (outbox) ----------

class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()(); // product | sale | category | ...
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // upsert | delete
  TextColumn get payload => text()(); // JSON snapshot data
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('waiting'))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Meta lokal: id perangkat, last download timestamp, dsb.
class SyncMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
