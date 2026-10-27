import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'tables.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() {
    // Gunakan database file persisten di direktori aplikasi
    return NativeDatabase(File(_databasePathSync()));
  }

  static String _databasePathSync() {
    final homeDir = Platform.environment['HOME'] ?? '/tmp';
    final dbDir = Directory(p.join(homeDir, '.pos_database'));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }
    return p.join(dbDir.path, 'pos_database.sqlite');
  }
}