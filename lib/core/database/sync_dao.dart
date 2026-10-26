import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import 'sync_meta.dart';

export 'sync_meta.dart' show ConflictDecision, TableMeta, TransactionExecutor;

/// Helper sinkronisasi generik berbasis metadata seragam
/// (`updated_at`, `deleted_at`, `version`, `sync_status`) di setiap tabel.
class SyncableDao {
  const SyncableDao(this._db);

  final AppDatabase _db;

  static final Map<String, TableMeta> _registry = {};

  /// Mendaftarkan metadata tabel (dipanggil sekali via registerAllSyncMetas).
  static void register(TableMeta meta) => _registry[meta.entityType] = meta;

  static TableMeta? metaFor(String entityType) => _registry[entityType];

  /// Snapshot seluruh metadata tabel yang sudah terdaftar.
  static List<TableMeta> get knownMetas => List.unmodifiable(_registry.values);

  Iterable<TableMeta> get registeredMetas => _registry.values;

  /// Jumlah operasi outbox yang masih menunggu (waiting/failed).
  Future<int> countPendingQueue() async {
    final count = await (_db.selectOnly(_db.syncQueue)
          ..addColumns([_db.syncQueue.id.count()])
          ..where(_db.syncQueue.status.isNotIn(
              [SyncQueueStatuses.done])))
        .getSingle();
    return count.read(_db.syncQueue.id.count()) ?? 0;
  }

  /// Jumlah operasi yang gagal permanen (melebihi batas retry).
  Future<int> countFailedQueue() =>
      (_db.selectOnly(_db.syncQueue)
            ..addColumns([_db.syncQueue.id.count()])
            ..where(_db.syncQueue.status.equals(SyncQueueStatuses.failed)))
          .getSingle()
          .then((row) => row.read(_db.syncQueue.id.count()) ?? 0);

  /// Versi baris saat ini (0 bila belum ada).
  Future<int> currentVersion(String entityType, String id) async {
    final meta = _require(entityType);
    final rows = await _db
        .customSelect(
          'SELECT "version" FROM "${meta.tableName}" WHERE "id" = ?',
          variables: [Variable.withString(id)],
        )
        .get();
    if (rows.isEmpty) return 0;
    return rows.first.read<int>('version');
  }

  /// Simpan baris lokal + increment version + enqueue payload ke outbox.
  ///
  /// [buildCompanion] mengisi seluruh kolom data termasuk metadata
  /// (version/updated_at/sync_status) yang disediakan lewat argumen closure.
  Future<int> upsertAndEnqueue(
    String entityType, {
    required String id,
    required Insertable<dynamic> Function(int version, DateTime now)
        buildCompanion,
    required Map<String, dynamic> Function(int version, DateTime now) payload,
  }) async {
    final meta = _require(entityType);
    final now = DateTime.now().toUtc();
    final newVersion = await currentVersion(entityType, id) + 1;
    await _typedUpsert(meta, buildCompanion(newVersion, now));
    await enqueue(
      entityType: entityType,
      entityId: id,
      operation: SyncOperations.upsert,
      payload: payload(newVersion, now),
      nextRetryAt: now,
    );
    return newVersion;
  }

  /// INSERT ... ON CONFLICT(id) DO UPDATE memakai SQL bawaan drift.
  /// Semua kolom ikut di-update, metadata sync di-set `synced` bila [markSynced].
  Future<void> _typedUpsert(TableMeta meta, Insertable<dynamic> row,
      {bool markSynced = false}) async {
    final table = _tableByName(meta.tableName);
    final ctx = table.createContext(
      row,
      InsertMode.insert,
      onConflict: DoUpdate(
        (_) => row,
        target: [table.columnByName('id')!],
      ),
    );
    var sql = ctx.sql;
    if (markSynced) {
      sql += ', "sync_status" = ?';
    }
    final vars = <Variable>[...ctx.boundVariables];
    if (markSynced) {
      vars.add(Variable.withString(SyncStatuses.synced));
    }
    await _db.customUpdate(sql, variables: vars, updateKind: UpdateKind.insert);
  }

  TableInfo<Table, dynamic> _tableByName(String tableName) {
    for (final t in _db.allTables) {
      if (t.actualTableName == tableName) return t;
    }
    throw ArgumentError.value(tableName, 'tableName', 'tabel tidak dikenal');
  }

  /// Soft delete (set deleted_at) + enqueue operasi delete.
  Future<void> softDeleteAndEnqueue(String entityType, String id) async {
    final meta = _require(entityType);
    final now = DateTime.now().toUtc();
    final newVersion = await currentVersion(entityType, id) + 1;
    await _db.customUpdate(
      'UPDATE "${meta.tableName}" SET "deleted_at" = ?1, "updated_at" = ?2, '
      '"version" = ?3, "sync_status" = ?4 WHERE "id" = ?5',
      variables: [
        Variable.withDateTime(now),
        Variable.withDateTime(now),
        Variable.withInt(newVersion),
        Variable.withString(SyncStatuses.pending),
        Variable.withString(id),
      ],
    );
    await enqueue(
      entityType: entityType,
      entityId: id,
      operation: SyncOperations.delete,
      payload: {
        'id': id,
        'deleted_at': now.toIso8601String(),
        'version': newVersion,
      },
      nextRetryAt: now,
    );
  }

  /// Tambahkan operasi ke outbox. Idempoten per entitas: operasi `waiting`
  /// lama untuk entitas identik dibatalkan agar tidak dobel kirim.
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    required DateTime nextRetryAt,
  }) async {
    await (_db.delete(_db.syncQueue)
          ..where((t) =>
              t.entityType.equals(entityType) &
              t.entityId.equals(entityId) &
              t.status.equals(SyncQueueStatuses.waiting)))
        .go();
    await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
          id: const Uuid().v4(),
          entityType: entityType,
          entityId: entityId,
          operation: operation,
          payload: jsonEncode(payload),
          nextRetryAt: Value(nextRetryAt),
        ));
  }

  /// Operasi yang siap dikirim (status waiting & next_retry_at telah tiba).
  Future<List<SyncQueueData>> dueQueueItems([DateTime? now]) =>
      (_db.select(_db.syncQueue)
            ..where((t) =>
                t.status.equals(SyncQueueStatuses.waiting) &
                t.nextRetryAt
                    .isSmallerOrEqualValue(now ?? DateTime.now().toUtc()))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<void> markQueueItemDone(String queueId) =>
      (_db.delete(_db.syncQueue)..where((t) => t.id.equals(queueId))).go();

  Future<void> markQueueItemFailed(
      String queueId, String error, DateTime nextRetryAt, int retryCount) async {
    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(queueId)))
        .write(SyncQueueCompanion(
      status: const Value(SyncQueueStatuses.waiting),
      lastError: Value(error),
      nextRetryAt: Value(nextRetryAt),
      retryCount: Value(retryCount),
    ));
  }

  /// Penentu resolusi konflik Last-Write-Wins + idempotensi.
  ///
  /// - Tidak ada lokal → terima remote.
  /// - Versi sama & waktu seri (±1 detik) → duplikat, abaikan.
  /// - Remote lebih baru (atau seri dengan versi lebih tinggi) DAN lokal sudah
  ///   `synced` → terima remote.
  /// - Remote lebih baru tetapi lokal belum tersinkron → pertahankan lokal;
  ///   push akan menyelesaikan konflik (LWW saat upload).
  static ConflictDecision resolveIncoming({
    required bool existsLocally,
    required DateTime? localUpdatedAt,
    required int localVersion,
    required bool localSynced,
    required DateTime remoteUpdatedAt,
    required int remoteVersion,
  }) {
    if (!existsLocally) return ConflictDecision.applyRemote;
    final local = localUpdatedAt ?? DateTime(0);
    final timeDiff = remoteUpdatedAt.difference(local).abs();
    if (localVersion == remoteVersion && timeDiff <= const Duration(seconds: 1)) {
      return ConflictDecision.duplicate;
    }
    final remoteNewer =
        remoteUpdatedAt.isAfter(local) && timeDiff > const Duration(seconds: 1);
    final tieHigherVersion = !remoteNewer && remoteVersion > localVersion;
    if ((remoteNewer || tieHigherVersion) && localSynced) {
      return ConflictDecision.applyRemote;
    }
    if (remoteNewer && !localSynced) return ConflictDecision.keepLocal;
    return ConflictDecision.duplicate;
  }

  /// Terapkan perubahan hasil unduhan remote dengan resolusi LWW.
  /// Mengembalikan true bila data remote diterima & disimpan.
  Future<bool> applyRemoteUpsert(
      String entityType, Map<String, dynamic> json) async {
    final meta = _require(entityType);
    final id = json['id'] as String;
    final remoteUpdatedAt = DateTime.parse(json['updated_at'] as String).toUtc();
    final remoteVersion = (json['version'] as num?)?.toInt() ?? 1;

    final rows = await _db
        .customSelect(
          'SELECT "updated_at", "version", "sync_status" FROM "${meta.tableName}" '
          'WHERE "id" = ?',
          variables: [Variable.withString(id)],
        )
        .get();
    final row = rows.isEmpty ? null : rows.first;

    final decision = resolveIncoming(
      existsLocally: row != null,
      localUpdatedAt: row?.read<DateTime?>('updated_at')?.toUtc(),
      localVersion: row?.read<int>('version') ?? 0,
      localSynced: row?.read<String>('sync_status') == SyncStatuses.synced,
      remoteUpdatedAt: remoteUpdatedAt,
      remoteVersion: remoteVersion,
    );

    if (decision != ConflictDecision.applyRemote) return false;

    await _typedUpsert(meta, meta.toCompanion(json), markSynced: true);
    return true;
  }

  TableMeta _require(String entityType) {
    final meta = _registry[entityType];
    if (meta == null) {
      throw ArgumentError.value(entityType, 'entityType', 'tabel tidak terdaftar');
    }
    return meta;
  }
}
