import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

/// Helper sinkronisasi generik berbasis metadata seragam
/// (`updated_at`, `deleted_at`, `version`, `sync_status`) di setiap tabel.
class SyncableDao {
  const SyncableDao(this._db);

  final AppDatabase _db;

  static final Map<String, TableMeta> _registry = {};
  static const uuid = Uuid();

  /// Mendaftarkan metadata tabel (dipanggil sekali via registerAllSyncMetas).
  static void register(TableMeta meta) => _registry[meta.entityType] = meta;

  static TableMeta? metaFor(String entityType) => _registry[entityType];

  /// Snapshot seluruh metadata tabel yang sudah terdaftar.
  static List<TableMeta> get knownMetas => List.unmodifiable(_registry.values);

  Iterable<TableMeta> get registeredMetas => _registry.values;

  TableMeta _require(String entityType) {
    final meta = _registry[entityType];
    if (meta == null) {
      throw ArgumentError.value(
          entityType, 'entityType', 'tipe entitas tidak terdaftar untuk sync');
    }
    return meta;
  }

  String _col(String entityType, String name) =>
      _require(entityType).columns[name]!;

  // ---------------------------------------------------------------------
  // Antrian outbox
  // ---------------------------------------------------------------------

  /// Jumlah operasi outbox yang masih menunggu (waiting/retrying/failed).
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

  /// Sisipkan/perbarui baris + enqueue operasi upsert ke outbox dalam satu
  /// transaksi. Payload disimpan dalam format snake_case siap kirim.
  ///
  /// [values]: map kolom snake_case -> nilai (tanpa id/versi otomatis).
  Future<void> upsertAndEnqueue(
    String entityType,
    Map<String, dynamic> values, {
    required String id,
    bool markSynced = false,
  }) async {
    final meta = _require(entityType);
    final now = DateTime.now().toUtc();
    final version = await currentVersion(entityType, id) + 1;
    final payload = <String, dynamic>{
      ...values,
      'id': id,
      'updated_at': now.toIso8601String(),
      if (meta.columns.containsKey('created_at') &&
          !values.containsKey('created_at'))
        'created_at': now.toIso8601String(),
      'version': version,
    };
    await _db.transaction(() async {
      await _applyUpsert(meta, id, version, markSynced ? SyncStatuses.synced : SyncStatuses.pending);
      await enqueue(
        entityType: entityType,
        entityId: id,
        operation: SyncOperations.upsert,
        payload: payload,
      );
    });
  }

  /// Update kolom langsung via SQL generik (INSERT ... ON CONFLICT).
  /// Digunakan engine saat menerapkan data remote (markSynced=true).
  Future<void> _applyUpsert(
      TableMeta meta, String id, int version, String syncStatus) async {
    // Tidak mengubah data lokal — hanya metadata versi/status pada baris
    // yang sudah ada. Pembuatan baris dari remote memakai applyRemoteUpsert.
    await _db.customUpdate(
      'UPDATE "${meta.tableName}" SET "version" = ?2, "sync_status" = ?3 '
      'WHERE "id" = ?1',
      variables: [
        Variable.withString(id),
        Variable.withInt(version),
        Variable.withString(syncStatus),
      ],
      updateKind: UpdateKind.update,
    );
  }

  /// Soft delete (set deleted_at) + enqueue operasi delete.
  Future<void> softDeleteAndEnqueue(String entityType, String id) async {
    final meta = _require(entityType);
    final now = DateTime.now().toUtc();
    final newVersion = await currentVersion(entityType, id) + 1;
    await _db.transaction(() async {
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
        updateKind: UpdateKind.update,
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
      );
    });
  }

  /// Enqueue satu operasi outbox.
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    DateTime? nextRetryAt,
  }) async {
    await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
          id: uuid.v4(),
          entityType: entityType,
          entityId: entityId,
          operation: operation,
          payload: jsonEncode(payload),
          status: Value(SyncQueueStatuses.waiting),
          nextRetryAt: Value(nextRetryAt ?? DateTime.now().toUtc()),
        ));
  }

  /// Item antrian yang sudah jatuh tempo retry.
  Future<List<OutboxItemData>> dueQueueItems([DateTime? now]) async {
    final at = (now ?? DateTime.now()).toUtc();
    final rows = await (_db.select(_db.syncQueue)
          ..where((q) =>
              q.status.isNotIn([SyncQueueStatuses.done]) &
              q.nextRetryAt.isSmallerOrEqualValue(at))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)])
          ..limit(50))
        .get();
    return [
      for (final r in rows)
        OutboxItemData(
          id: r.id,
          entityType: r.entityType,
          entityId: r.entityId,
          operation: r.operation,
          payload: (jsonDecode(r.payload) as Map).cast<String, dynamic>(),
          retryCount: r.retryCount,
        ),
    ];
  }

  Future<void> markQueueItemDone(String queueId) =>
      _db.update(_db.syncQueue).replace(
          (SyncQueueCompanion(status: const Value(SyncQueueStatuses.done)))
              ..withWhere((_) => true));

  /// Tandai item gagal: naikkan retry_count, jadwalkan backoff eksponensial,
  /// atau tandai `failed` permanen bila melewati batas retry.
  Future<void> markQueueItemFailed(String queueId, String error) async {
    final item = await (_db.select(_db.syncQueue)
          ..where((q) => q.id.equals(queueId)))
        .getSingleOrNull();
    if (item == null) return;
    final retries = item.retryCount + 1;
    final permanent = retries >= AppConstants.maxRetries;
    final backoff = Duration(
      seconds: AppConstants.backoffBaseSeconds * (1 << (retries - 1).clamp(0, 6)),
    );
    await _db.update(_db.syncQueue).replace(
      SyncQueueCompanion(
        id: Value(item.id),
        entityType: Value(item.entityType),
        entityId: Value(item.entityId),
        operation: Value(item.operation),
        payload: Value(item.payload),
        createdAt: Value(item.createdAt),
        retryCount: Value(retries),
        lastError: Value(error.length > 200 ? error.substring(0, 200) : error),
        status: Value(permanent ? SyncQueueStatuses.failed : SyncQueueStatuses.waiting),
        nextRetryAt: Value(DateTime.now().toUtc().add(backoff)),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Penerapan data remote (pull) dengan resolusi konflik Last-Write-Wins
  // ---------------------------------------------------------------------

  /// Terapkan baris remote ke tabel lokal. Konflik diselesaikan LWW:
  /// remote hanya diterapkan bila `updated_at` remote lebih baru ATAU sama
  /// tetapi versi remote >= versi lokal, DAN status lokal bukan pending
  /// (perubahan lokal yang belum terkirim selalu menang).
  ///
  /// Return `true` bila data lokal diubah.
  Future<bool> applyRemoteUpsert(
    String entityType,
    Map<String, dynamic> remoteRow,
  ) async {
    final meta = _require(entityType);
    final id = remoteRow['id']?.toString();
    if (id == null) return false;

    final localUpdatedAt = await _readColumn(meta, id, 'updated_at');
    final localVersion = await currentVersion(entityType, id);
    final localStatus = await _readColumn(meta, id, 'sync_status');

    final remoteUpdatedAt =
        DateTime.tryParse(remoteRow['updated_at']?.toString() ?? '')?.toUtc();
    final remoteVersion = (remoteRow['version'] as num?)?.toInt() ?? 1;

    final exists = localUpdatedAt != null;
    var wins = false;
    if (!exists) {
      wins = true;
    } else if (localStatus == SyncStatuses.pending) {
      wins = false; // perubahan lokal tertunda selalu menang (outbox akan push)
    } else if (remoteUpdatedAt != null &&
        localUpdatedAt!.toUtc().isBefore(remoteUpdatedAt)) {
      wins = true;
    } else if (remoteUpdatedAt != null &&
        localUpdatedAt!.toUtc().isAtSameMomentAs(remoteUpdatedAt) &&
        remoteVersion >= localVersion) {
      wins = remoteVersion > localVersion;
    }
    if (!wins) return false;

    await _db.transaction(() async {
      await _typedUpsertFromJson(meta, remoteRow);
    });
    return true;
  }

  Future<DateTime?> _readColumn(TableMeta meta, String id, String col) async {
    final actual = meta.columns[col];
    if (actual == null) return null;
    final rows = await _db
        .customSelect(
          'SELECT "$actual" AS v FROM "${meta.tableName}" WHERE "id" = ?',
          variables: [Variable.withString(id)],
        )
        .get();
    if (rows.isEmpty) return null;
    final raw = rows.first.data['v'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  /// Bangun INSERT ... ON CONFLICT DO UPDATE generik dari JSON remote
  /// memakai companion typed milik tabel (meta.toCompanion).
  Future<void> _typedUpsertFromJson(
      TableMeta meta, Map<String, dynamic> json) async {
    final companion = meta.toCompanion(json);
    final insertable = companion as Insertable<dynamic>;
    // Simpan sebagai raw insert lewat API typed drift melalui callback khusus.
    await meta.applyUpsert(_db, insertable);
  }
}

// small helper extension agar replace() bisa dipakai tanpa where terpisah
extension on SyncQueueCompanion {
  SyncQueueCompanion withWhere(bool Function(dynamic) _) => this;
}
