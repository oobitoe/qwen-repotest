import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'tables.dart';
import 'seeds/seed_data.dart';
import '../security/encrypted_database_manager.dart';

export 'sync_meta.dart' show ConflictDecision, TableMeta, TransactionExecutor;
export 'tables.dart'
    show SyncStatuses, SyncOperations, SyncQueueStatuses;

part 'app_database.g.dart';

/// Database lokal SQLite (Drift). Sumber kebenaran utama untuk operasi harian.
///
/// Enkripsi file database:
/// - File disimpan di disk dalam bentuk terenkripsi (`.enc`)
/// - Saat aplikasi mulai, didekripsi ke lokasi kerja untuk Drift
/// - Saat aplikasi ditutup, dienkripsi kembali dan file kerja dihapus
/// - Database browser tidak bisa membaca file `.enc` tanpa kunci
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

  /// Check if database encryption is enabled
  static bool get isEncryptionEnabled => _encryptionKey != null;

  /// Inisialisasi database dengan enkripsi.
  ///
  /// Harus dipanggil sebelum AppDatabase pertama kali dibuat.
  /// Jika ada file terenkripsi di disk, akan didekripsi ke lokasi kerja.
  static Future<void> initializeEncryptedDatabase() async {
    if (_encryptionKey == null) return;

    final encryptedPath = encryptedDatabasePath();
    final workingPath = databasePath();

    await EncryptedDatabaseManager.prepareDatabaseForUse(
      encryptedDbPath: encryptedPath,
      workingDbPath: workingPath,
      encryptionKey: _encryptionKey!,
    );
  }

  /// Amankan database saat istirahat (at rest).
  ///
  /// Harus dipanggil saat aplikasi ditutup (misal dalam main.dart before runApp
  /// atau dispose). File kerja akan dienkripsi ke `.enc` dan dihapus.
  static Future<void> secureDatabaseAtRest() async {
    if (_encryptionKey == null) return;

    final encryptedPath = encryptedDatabasePath();
    final workingPath = databasePath();

    await EncryptedDatabaseManager.secureDatabaseAtRest(
      workingDbPath: workingPath,
      encryptedDbPath: encryptedPath,
      encryptionKey: _encryptionKey!,
    );
  }

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
    return NativeDatabase(File(databasePath()));
  }

  /// Path file database kerja (plaintext, digunakan Drift saat aplikasi berjalan)
  static String databasePath() {
    final homeDir = Platform.environment['HOME'] ?? '/tmp';
    final dbDir = Directory(p.join(homeDir, '.pos_database_working'));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }
    return p.join(dbDir.path, 'pos_database.sqlite');
  }

  /// Path file database terenkripsi (disimpan di disk saat aplikasi tidak berjalan)
  static String encryptedDatabasePath() {
    final homeDir = Platform.environment['HOME'] ?? '/tmp';
    final dbDir = Directory(p.join(homeDir, '.pos_database_encrypted'));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }
    return p.join(dbDir.path, 'pos_database.db.enc');
  }

  /// Cek apakah ada file database terenkripsi di disk
  static bool hasEncryptedDatabase() {
    return File(encryptedDatabasePath()).existsSync();
  }

  /// Cek apakah ada file database kerja di disk
  static bool hasWorkingDatabase() {
    return File(databasePath()).existsSync();
  }

  /// Hapus semua file database (encrypted + working)
  static Future<void> purgeDatabaseFiles() async {
    await EncryptedDatabaseManager.purgeDatabaseFiles(
      encryptedDbPath: encryptedDatabasePath(),
      workingDbPath: databasePath(),
    );
  }
}
