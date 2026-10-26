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
    required this.toCompanion,
    required this.buildUpsertSql,
  });

  /// Nama tipe entitas logis, mis. `product`, `sale`.
  final String entityType;

  /// Nama tabel fisik (snake_case, sama dengan `actualTableName` drift).
  final String tableName;

  /// Membangun companion insert/upsert dari snapshot JSON remote.
  final Insertable<dynamic> Function(Map<String, dynamic> json) toCompanion;

  /// Membangun SQL `INSERT ... ON CONFLICT(id) DO UPDATE` lengkap beserta
  /// variabel terikat, dari sebuah companion milik tabel yang sama.
  /// Diisi oleh registrasi per-tabel agar tetap bertipe kuat (typed).
  final UpsertStatement Function(Insertable<dynamic> row) buildUpsertSql;
}

/// Pernyataan upert siap eksekusi: SQL + variabel terikatnya.
class UpsertStatement {
  const UpsertStatement(this.sql, this.variables);
  final String sql;
  final List<Variable<Object?>?> variables;
}
