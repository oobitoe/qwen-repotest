import 'package:drift/drift.dart';

/// Hasil pemilihan strategi resolusi konflik last-write-wins.
enum ConflictDecision { applyRemote, keepLocal, duplicate }

/// Eksekusi di dalam transaksi database (dipanggil dengan instance AppDatabase).
typedef TransactionExecutor = Future<void> Function(dynamic db);

/// Deskripsi akses generik ke sebuah tabel entitas untuk kebutuhan sinkronisasi.
class TableMeta {
  const TableMeta({
    required this.entityType,
    required this.tableName,
    required this.columns,
    required this.toCompanion,
  });

  /// Nama tipe entitas logis, mis. `product`, `sale`.
  final String entityType;

  /// Nama tabel fisik (snake_case, sama dengan `actualTableName` drift).
  final String tableName;

  /// Daftar (nama kolom snake_case, tipe drift) milik tabel ini.
  final List<(String, DriftSqlType)> columns;

  /// Membangun companion insert/upsert dari snapshot JSON remote.
  final Insertable<dynamic> Function(Map<String, dynamic> json) toCompanion;
}
