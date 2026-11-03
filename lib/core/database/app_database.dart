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
/// Enkripsi file database (file-level encryption):
/// - File database disimpan di disk dalam bentuk terenkripsi (`.enc`)
/// - Saat aplikasi mulai / resume, file didekripsi ke lokasi kerja untuk Drift
/// - Saat aplikasi pindah background / close, file kerja dienkripsi kembali ke `.enc` dan dihapus
/// - Tidak ada file plaintext yang tersisa di disk setelah aplikasi ditutup
/// - Database browser tidak bisa membaca file `.enc` tanpa kunci
/// - Saat crash: versi terakhir yang dienkripsi tetap aman di disk;
///   file plaintext hanya ada saat aplikasi aktif berjalan
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

  /// Global encryption key for the database (AES-256 derived from password)
  static String? _encryptionKey;

  /// Set encryption key untuk database.
  ///
  /// Harus dipanggil sebelum AppDatabase pertama kali dibuat.
  static Future<void> setEncryptionKey(String? key) async {
    _encryptionKey = key;
  }

  /// Get current encryption key
  static String? get encryptionKey => _encryptionKey;

  /// Check if database encryption is enabled
  static bool get isEncryptionEnabled => _encryptionKey != null;

  /// Inisialisasi database dengan enkripsi file.
  ///
  /// Harus dipanggil sebelum AppDatabase pertama kali dibuat.
  /// Jika ada file terenkripsi (`.enc`) dari session sebelumnya, akan didekripsi
  /// ke lokasi kerja. File plaintext dari crash sebelumnya akan dihapus terlebih dahulu.
  static Future<void> initializeEncryptedDatabase() async {
    if (_encryptionKey == null) return;

    final encryptedPath = encryptedDatabasePath();
    final workingPath = databasePath();

    // Hapus file plaintext dari crash sebelumnya (jika ada)
    // Ini memastikan tidak ada plaintext yang tersisa dari session yang crash
    final workingFile = File(workingPath);
    if (workingFile.existsSync()) {
      await workingFile.delete();
    }

    // Dekripsi file `.enc` ke lokasi kerja untuk digunakan Drift
    await EncryptedDatabaseManager.prepareDatabaseForUse(
      encryptedDbPath: encryptedPath,
      workingDbPath: workingPath,
      encryptionKey: _encryptionKey!,
    );
  }

  /// Amankan database saat aplikasi pindah background / close.
  ///
  /// Enkripsi file kerja kembali ke `.enc` dan hapus file plaintext.
  /// Dipanggil pada AppLifecycleState.paused / inactive.
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

  /// Cek apakah ada file database kerja di disk (plaintext)
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
