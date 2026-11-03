import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'tables.dart';
import 'seeds/seed_data.dart';

export 'sync_meta.dart' show ConflictDecision, TableMeta, TransactionExecutor;
export 'tables.dart'
    show SyncStatuses, SyncOperations, SyncQueueStatuses;

part 'app_database.g.dart';

/// Database lokal SQLite (Drift). Sumber kebenaran utama untuk operasi harian.
@DriftDatabase(
  tables: [
    Businesses,
    Stores,
    Profiles,
    Categories,
    Units,
    Products,
    StockMovements,
    Suppliers,
    Customers,
    Sales,
    SaleItems,
    ExpenseCategories,
    Expenses,
    IncomeCategories,
    IncomeEntries,
    StockAdjustments,
    StockAdjustmentItems,
    StockOpnames,
    StockOpnameItems,
    CashRegisters,
    CashSessions,
    CashMovements,
    Accounts,
    AccountTransactions,
    Debts,
    DebtPayments,
    AuditLogs,
    SyncQueue,
    SyncMetadata,
    Purchases,
    PurchaseItems,
    PurchasePayments,
    ProductVariants,
    PurchaseOrders,
    PurchaseOrderItems,
    PurchaseReturns,
    PurchaseReturnItems,
    SalePayments,
    SaleReturns,
    SaleReturnItems,
    StockTransfers,
    StockTransferItems,
    CustomerAddresses,
    BusinessSettings,
    StoreSettings,
    TaxSettings,
    PaymentMethodsConfig,
    Devices,
    FinancialAdjustments,
    Roles,
    Permissions,
    RolePermissions,
    BusinessMembers,
    UserStoreAccess,
    SaleSequences,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _createDatabaseExecutor());

  /// Global encryption key for the database
  static String? _encryptionKey;

  /// Set encryption key for the database
  static Future<void> setEncryptionKey(String? key) async {
    _encryptionKey = key;
  }

  /// Get current encryption key
  static String? get encryptionKey => _encryptionKey;

  /// Check if database is encrypted
  static bool get isEncrypted => _encryptionKey != null;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
          // Seed data baru dengan businessId + storeId
          await seedDatabase(this);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _createDatabaseExecutor() {
    return NativeDatabase(File(_databasePath()));
  }

  /// Get database path with encryption support
  static String _databasePath() {
    final homeDir = Platform.environment['HOME'] ?? '/tmp';
    final dirName = _encryptionKey != null ? '.pos_database_encrypted' : '.pos_database';
    final fileName = _encryptionKey != null ? 'pos_database.db' : 'pos_database.sqlite';
    final dbDir = Directory(p.join(homeDir, dirName));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }
    return p.join(dbDir.path, fileName);
  }

  /// Get encrypted database path (for migration)
  static String get encryptedDatabasePath {
    final homeDir = Platform.environment['HOME'] ?? '/tmp';
    final dbDir = Directory(p.join(homeDir, '.pos_database_encrypted'));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }
    return p.join(dbDir.path, 'pos_database.db');
  }

  /// Get plaintext database path (for migration)
  static String get plaintextDatabasePath {
    final homeDir = Platform.environment['HOME'] ?? '/tmp';
    final dbDir = Directory(p.join(homeDir, '.pos_database'));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }
    return p.join(dbDir.path, 'pos_database.sqlite');
  }
}
