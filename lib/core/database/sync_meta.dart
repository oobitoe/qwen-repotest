import 'package:drift/drift.dart';

/// Hasil pemilihan strategi resolusi konflik last-write-wins.
enum ConflictDecision { applyRemote, keepLocal, duplicate }

/// Eksekusi di dalam transaksi database (dipanggil dengan instance AppDatabase).
typedef TransactionExecutor = Future<void> Function(dynamic db);

/// Penanda baris remote yang tidak ada di tabel lokal (akan disisipkan).
const Object kAbsent = _Absent();

class _Absent {
  const _Absent();
}

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

  /// Daftar (nama kolom snake_case, BaseSqlType drift) milik tabel ini.
  final List<(String, Object)> columns;

  /// Membangun companion typed dari snapshot JSON remote.
  final Insertable<dynamic> Function(Map<String, dynamic> json) toCompanion;

  /// Peta cepat nama kolom -> BaseSqlType drift.
  Map<String, Object> get columnTypes => {for (final c in columns) c.$1: c.$2};

  bool hasColumn(String name) => columnTypes.containsKey(name);

  DriftSqlType<Object>? _driftType(Object? sqlType) {
    if (sqlType is GeneratedColumn) return sqlType.type as DriftSqlType<Object>;
    if (sqlType is DriftSqlType<Object>) return sqlType;
    return null;
  }

  /// Bangun INSERT ... ON CONFLICT(id) DO UPDATE secara generik dari baris
  /// JSON remote. Kolom yang tidak dikenal dibuang; nilai dikonversi sesuai
  /// tipe kolom drift (date/int/real/text/bool/blob).
  ///
  /// INSERT harus mencakup semua kolom NOT NULL (tanpa default) supaya tidak
  /// melanggar constraint — kolom yang tidak ada di [row] diisi dengan nilai
  /// default berdasarkan tipe. UPDATE hanya menimpa kolom yang ada di [row].
  ///
  /// Menggunakan INSERT OR IGNORE + UPDATE terpisah untuk menghindari deadlock
  /// pada NativeDatabase (Drift 2.21: runCustom di dalam transaction tidak
  /// support re-entrant lock).
  Future<void> applyUpsert(DatabaseConnectionUser db, Map<String, dynamic> row) async {
    final types = columnTypes;
    final insertCols = <String>[];
    final insertValues = <Object?>[];
    final updateCols = <String>[];
    final updateValues = <Object?>[];

    for (final (colName, _) in columns) {
      final type = types[colName];
      if (type == null) continue;
      final driftType = _driftType(type);
      if (row.containsKey(colName)) {
        final coerced = _coerce(driftType, row[colName]);
        insertCols.add(colName);
        insertValues.add(coerced);
        if (colName != 'id') {
          updateCols.add(colName);
          updateValues.add(coerced);
        }
      } else {
        insertCols.add(colName);
        insertValues.add(_defaultForType(driftType));
      }
    }
    if (insertCols.isEmpty) return;

    final placeholders = List.generate(insertCols.length, (_) => '?').join(', ');
    final quotedInsert = [for (final c in insertCols) '"$c"'].join(', ');

    await db.executor.runCustom(
      'INSERT OR IGNORE INTO "$tableName" ($quotedInsert) VALUES ($placeholders)',
      insertValues,
    );

    if (updateCols.isNotEmpty) {
      final updates = [for (final c in updateCols) '"$c" = ?'].join(', ');
      await db.executor.runCustom(
        'UPDATE "$tableName" SET $updates WHERE "id" = ?',
        [...updateValues, row['id']],
      );
    }
  }

  /// Nilai default berdasarkan tipe drift untuk kolom yang tidak ada di row.
  Object? _defaultForType(DriftSqlType<Object>? type) {
    if (type == DriftSqlType.dateTime) return 0;
    if (type == DriftSqlType.int) return 0;
    if (type == DriftSqlType.double) return 0.0;
    if (type == DriftSqlType.bool) return 0;
    if (type == DriftSqlType.string) return '';
    if (type == DriftSqlType.blob) return <int>[];
    return null;
  }

  /// Konversi nilai JSON menjadi companion update parsial (hanya kolom yang
  /// hadir di payload). Nilai datetime dinormalisasi ke UTC agar konsisten
  /// dengan penyimpanan drift (integer millisecondsSinceEpoch UTC).
  Map<String, Object?> toPartialValues(Map<String, dynamic> json) {
    final values = <String, Object?>{};
    for (final entry in json.entries) {
      if (!columnTypes.containsKey(entry.key)) continue;
      values[entry.key] = _coerce(_driftType(columnTypes[entry.key]), entry.value);
    }
    return values;
  }

  Object? _coerce(DriftSqlType<Object>? type, Object? raw) {
    if (raw == null) return null;
    if (type == DriftSqlType.dateTime) {
      if (raw is DateTime) return raw.toUtc().millisecondsSinceEpoch;
      // Handle: ISO8601 string, integer milliseconds, integer seconds (Unix epoch)
      final s = raw.toString();
      final asNum = int.tryParse(s);
      if (asNum != null) {
        // Jika < 1e12 berarti dalam detik (Unix epoch), kalikan 1000 → milidetik
        final ms = asNum < 1000000000000 ? asNum * 1000 : asNum;
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)
            .millisecondsSinceEpoch;
      }
      // Fallback ISO8601 parse dengan tryParse, tidak boleh throw
      return DateTime.tryParse(s)?.toUtc().millisecondsSinceEpoch ??
          DateTime.now().toUtc().millisecondsSinceEpoch;
    }
    if (type == DriftSqlType.int) {
      return raw is num ? raw.toInt() : int.tryParse(raw.toString()) ?? 0;
    }
    if (type == DriftSqlType.double) {
      return raw is num ? raw.toDouble() : double.tryParse(raw.toString());
    }
    if (type == DriftSqlType.bool) {
      return raw == true || raw == 'true' || raw == 1;
    }
    if (type == DriftSqlType.blob) return raw;
    return raw.toString();
  }
}
