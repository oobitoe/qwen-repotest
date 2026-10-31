import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import 'app_database.dart';

/// Item antrian outbox siap kirim (bacaan mentah dari `sync_queue`).
class OutboxItemData {
  const OutboxItemData({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.retryCount,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String operation;
  final Map<String, dynamic> payload;
  final int retryCount;
}

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

  // ---------------------------------------------------------------------
  // Antrian outbox
  // ---------------------------------------------------------------------

  /// Jumlah operasi outbox yang masih menunggu (waiting/retrying/failed).
  Future<int> countPendingQueue() async {
    final count = await (_db.selectOnly(_db.syncQueue)
          ..addColumns([_db.syncQueue.id.count()])
          ..where(_db.syncQueue.status.isNotIn([SyncQueueStatuses.done])))
        .getSingle();
    return count.read(_db.syncQueue.id.count()) ?? 0;
  }

  /// Jumlah operasi yang gagal permanen (melebihi batas retry).
  Future<int> countFailedQueue() async {
    final count = await (_db.selectOnly(_db.syncQueue)
          ..addColumns([_db.syncQueue.id.count()])
          ..where(_db.syncQueue.status.equals(SyncQueueStatuses.failed)))
        .getSingle();
    return count.read(_db.syncQueue.id.count()) ?? 0;
  }

  /// Versi baris saat ini (0 bila belum ada).
  Future<int> currentVersion(String entityType, String id) async {
    final meta = _require(entityType);
    final rows = await _db
        .customSelect(
          'SELECT "version" AS v FROM "${meta.tableName}" WHERE "id" = ?',
          variables: [Variable.withString(id)],
        )
        .get();
    if (rows.isEmpty) return 0;
    return (rows.first.data['v'] as num?)?.toInt() ?? 0;
  }

  /// Terapkan perubahan data lokal (map snake_case -> nilai primitif) ke
  /// baris [id] sekaligus enqueue operasi upsert ke outbox dalam satu
  /// transaksi. Payload disimpan dalam format siap kirim (ISO-8601 UTC).
  ///
  /// [values] harus memuat seluruh kolom data yang ingin diubah; kolom
  /// metadata (updated_at/version/sync_status) dikelola otomatis.
  Future<void> upsertAndEnqueue(
    String entityType,
    Map<String, dynamic> values, {
    required String id,
    bool markSynced = false,
  }) async {
    final meta = _require(entityType);
    final now = DateTime.now().toUtc();
    final nowMs = now.millisecondsSinceEpoch;
    final version = await currentVersion(entityType, id) + 1;
    final row = <String, dynamic>{
      ...values,
      'id': id,
      'updated_at': nowMs,
      if (meta.hasColumn('created_at') && !values.containsKey('created_at'))
        'created_at': nowMs,
      // deleted_at nullable HARUS null (bukan 0/epoch) agar baris baru
      // tetap lolos filter deletedAt.isNull() di watchSuppliers dst.
      if (meta.hasColumn('deleted_at') && !values.containsKey('deleted_at'))
        'deleted_at': null,
      'version': version,
      'sync_status':
          markSynced ? SyncStatuses.synced : SyncStatuses.pending,
    };
    await meta.applyUpsert(_db, row);
    await enqueue(
      entityType: entityType,
      entityId: id,
      operation: SyncOperations.upsert,
      payload: row,
    );
  }

  /// Soft delete (set deleted_at) + enqueue operasi delete.
  Future<void> softDeleteAndEnqueue(String entityType, String id) async {
    final meta = _require(entityType);
    final now = DateTime.now().toUtc();
    final newVersion = await currentVersion(entityType, id) + 1;
    await _db.transaction(() async {
      await _db.customUpdate(
        'UPDATE "${meta.tableName}" SET "deleted_at" = ?, "updated_at" = ?, '
        '"version" = ?, "sync_status" = ? WHERE "id" = ?',
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
          'deleted_at': now.millisecondsSinceEpoch,
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
          status: const Value(SyncQueueStatuses.waiting),
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

  /// Tandai item outbox berhasil terkirim.
  Future<void> markQueueItemDone(String queueId) =>
      (_db.update(_db.syncQueue)..where((q) => q.id.equals(queueId)))
          .write(const SyncQueueCompanion(
        status: Value(SyncQueueStatuses.done),
      ));

  /// Tandai item gagal: naikkan retry_count, jadwalkan backoff eksponensial,
  /// atau tandai `failed` permanen bila melewati batas retry.
  Future<void> markQueueItemFailed(
    String queueId,
    String error,
    DateTime nextRetryAt,
    int attempt,
  ) async {
    final permanent = attempt >= AppConstants.maxSyncRetries;
    await (_db.update(_db.syncQueue)..where((q) => q.id.equals(queueId))).write(
      SyncQueueCompanion(
        retryCount: Value(attempt),
        lastError: Value(error.length > 200 ? error.substring(0, 200) : error),
        status:
            Value(permanent ? SyncQueueStatuses.failed : SyncQueueStatuses.waiting),
        nextRetryAt: Value(nextRetryAt),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Penerapan data remote (pull) dengan resolusi konflik Last-Write-Wins
  // ---------------------------------------------------------------------

  /// Terapkan baris remote ke tabel lokal. Konflik diselesaikan LWW:
  /// remote hanya diterapkan bila `updated_at` remote lebih baru ATAU sama
  /// tetapi versi remote > versi lokal, DAN status lokal bukan pending
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

    final local = await _readLocalSnapshot(meta, id);
    final remoteUpdatedAt =
        DateTime.tryParse(remoteRow['updated_at']?.toString() ?? '')?.toUtc();
    final remoteVersion = (remoteRow['version'] as num?)?.toInt() ?? 1;

    var wins = false;
    if (local == null) {
      wins = true; // baris baru dari remote
    } else {
      final localStatus = local['sync_status']?.toString();
      final localUpdatedAt = _parseLocalDate(local['updated_at']);
      final localVersion = (local['version'] as num?)?.toInt() ?? 0;
      if (localStatus == SyncStatuses.pending) {
        wins = false; // perubahan lokal tertunda selalu menang (outbox push)
      } else if (remoteUpdatedAt != null && localUpdatedAt != null) {
        if (localUpdatedAt.isBefore(remoteUpdatedAt)) {
          wins = true;
        } else if (localUpdatedAt.isAtSameMomentAs(remoteUpdatedAt)) {
          wins = remoteVersion > localVersion;
        }
      } else {
        wins = true; // metadata lokal tidak lengkap — terima remote
      }
    }
    if (!wins) return false;

    await meta.applyUpsert(_db, {
      ...remoteRow,
      'sync_status': SyncStatuses.synced,
    });
    return true;
  }

  /// Simpan remoteId (ID di PocketBase) ke baris lokal untuk mapping
  /// lokal <-> PocketBase. Dipakai setelah create() berhasil di server.
  Future<void> updateRemoteId(
    String entityType,
    String localId,
    String remoteId,
  ) async {
    final meta = _require(entityType);
    await _db.customUpdate(
      'UPDATE "${meta.tableName}" SET "remote_id" = ?, "sync_status" = ? WHERE "id" = ?',
      variables: [
        Variable.withString(remoteId),
        Variable.withString(SyncStatuses.synced),
        Variable.withString(localId),
      ],
    );
  }

  /// Drift menyimpan DateTime sebagai integer ms-since-epoch (UTC) pada
  /// SQLite; bacaan mentah customSelect mengembalikan bentuk tersebut.
  /// Aman terhadap integer detik (Unix epoch) dan ISO8601 string.
  DateTime? _parseLocalDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    final s = raw.toString();
    final asNum = int.tryParse(s);
    if (asNum != null) {
      // Jika < 1e12 berarti dalam detik, kalikan 1000 → milidetik
      final ms = asNum < 1000000000000 ? asNum * 1000 : asNum;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    return DateTime.tryParse(s)?.toUtc();
  }

  /// Baca snapshot metadata baris lokal sebagai map snake_case
  /// (null bila baris tidak ada).
  Future<Map<String, Object?>?> _readLocalSnapshot(
      TableMeta meta, String id) async {
    final rows = await _db
        .customSelect(
          'SELECT "id", "updated_at", "version", "sync_status" '
          'FROM "${meta.tableName}" WHERE "id" = ?',
          variables: [Variable.withString(id)],
        )
        .get();
    if (rows.isEmpty) return null;
    return rows.first.data;
  }
}
