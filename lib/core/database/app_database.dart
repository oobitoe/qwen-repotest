import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables.dart';

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
        // Migrasi bertahap ditambahkan pada fase berikutnya bila schemaVersion naik.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() {
    // Untuk test, executor in-memory dapat disuntikkan via konstruktor.
    return NativeDatabase.memory();
  }
}
