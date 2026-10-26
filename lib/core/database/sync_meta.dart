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

  /// Daftar (nama kolom snake_case, tipe drift) milik tabel ini.
  final List<(String, DriftSqlType<Object>)> columns;

  /// Membangun companion typed dari snapshot JSON remote.
  final Insertable<dynamic> Function(Map<String, dynamic> json) toCompanion;

  /// Peta cepat nama kolom -> tipe drift.
  Map<String, DriftSqlType<Object>> get columnTypes =>
      {for (final c in columns) c.$1: c.$2};

  bool hasColumn(String name) => columnTypes.containsKey(name);

  /// Bangun INSERT ... ON CONFLICT(id) DO UPDATE secara generik dari baris
  /// JSON remote. Kolom yang tidak dikenal dibuang; nilai dikonversi sesuai
  /// tipe kolom drift (date/int/real/text/bool/blob).
  Future<void> applyUpsert(QueryExecutor executor, Map<String, dynamic> row) async {
    final types = columnTypes;
    final cols = <String>[];
    final values = <Object?>[];
    for (final entry in row.entries) {
      final type = types[entry.key];
      if (type == null) continue; // kolom lokal-only / tak dikenal
      cols.add(entry.key);
      values.add(_coerce(type, entry.value));
    }
    if (cols.isEmpty) return;
    final placeholders = List.generate(cols.length, (_) => '?').join(', ');
    final quoted = [for (final c in cols) '"$c"'].join(', ');
    final updates = [
      for (final c in cols)
        if (c != 'id') '"$c" = excluded."$c"'
    ].join(', ');
    await executor.runCustom(
      'INSERT INTO "$tableName" ($quoted) VALUES ($placeholders) '
      'ON CONFLICT("id") DO UPDATE SET $updates',
      values,
    );
  }

  /// Konversi nilai JSON menjadi companion update parsial (hanya kolom yang
  /// hadir di payload). Nilai datetime dinormalisasi ke UTC agar konsisten
  /// dengan penyimpanan drift (integer millisecondsSinceEpoch UTC).
  UpdateCompanion<dynamic> toPartialCompanion(Map<String, dynamic> json) {
    final values = <String, Object?>{};
    for (final entry in json.entries) {
      if (!columnTypes.containsKey(entry.key)) continue;
      values[entry.key] = _coerce(columnTypes[entry.key]!, entry.value);
    }
    return _PartialCompanion(values);
  }

  Object? _coerce(DriftSqlType<Object> type, Object? raw) {
    if (raw == null) return null;
    if (type == DriftSqlType.dateTime) {
      if (raw is DateTime) return raw.toUtc();
      return DateTime.parse(raw.toString()).toUtc();
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

/// Companion parsial berbasis map — dipakai SyncableDao untuk update kolom
/// tertentu (mis. version/sync_status/deleted_at) tanpa mengenal tabel tujuan.
class _PartialCompanion extends UpdateCompanion<dynamic> {
  _PartialCompanion(this.values);

  final Map<String, Object?> values;

  @override
  Map<String, Value> toColumns(bool nullToAbsent) {
    final out = <String, Value>{};
    for (final e in values.entries) {
      final v = e.value;
      if (v == null) {
        out[e.key] = const Value(null);
      } else if (v is DateTime) {
        out[e.key] = Value(v);
      } else if (v is int) {
        out[e.key] = Value<int>(v);
      } else if (v is double) {
        out[e.key] = Value<double>(v);
      } else if (v is bool) {
        out[e.key] = Value<bool>(v);
      } else {
        out[e.key] = Value<String>(v.toString());
      }
    }
    return out;
  }
}
