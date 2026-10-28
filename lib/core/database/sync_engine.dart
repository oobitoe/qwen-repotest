import 'dart:async';


import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import 'app_database.dart';
import 'sync_dao.dart';
import 'sync_registry.dart';

/// Kontrak pengiriman batch operasi ke server. Implementasi nyata memakai
/// Supabase; implementasi in-memory dipakai pada pengujian & mode offline.
abstract class SyncTransport {
  /// Kirim daftar operasi outbox. Kembalikan id operasi yang diterima server.
  Future<List<String>> push(List<OutboxItem> batch);

  /// Unduh perubahan sejak [since] per tabel. Map: tableName -> rows JSON.
  Future<Map<String, List<Map<String, dynamic>>>> pull(DateTime since);
}

/// Item outbox siap kirim ( hasil baca dari sync_queue ).
typedef OutboxItem = ({
  String id,
  String entityType,
  String entityId,
  String operation,
  Map<String, dynamic> payload,
  int retryCount,
});

/// Transport nyata berbasis Supabase (upsert per tabel via REST).
class SupabaseSyncTransport implements SyncTransport {
  SupabaseSyncTransport(this._client);

  final SupabaseClient _client;

  @override
  Future<List<String>> push(List<OutboxItem> batch) async {
    final accepted = <String>[];
    for (final item in batch) {
      final meta = SyncableDao.metaFor(item.entityType);
      if (meta == null) {
        throw StateError('Tipe entitas tidak terdaftar untuk sync: '
            '${item.entityType}');
      }
      final table = _client.from(meta.tableName);
      if (item.operation == SyncOperations.delete) {
        await table
            .update({
              'deleted_at': item.payload['deleted_at'],
              'updated_at': item.payload['updated_at'],
              'version': item.payload['version'],
            })
            .eq('id', item.entityId);
      } else {
        await table.upsert(_remoteRow(meta, item.payload));
      }
      accepted.add(item.id);
    }
    return accepted;
  }

  /// Buang kolom lokal-only (sync_status) dan konversi camelCase->snake bila
  /// diperlukan. Payload sudah dibuat dalam format snake_case oleh repository.
  Map<String, dynamic> _remoteRow(TableMeta meta, Map<String, dynamic> payload) {
    final allowed = meta.columns.map((c) => c.$1).toSet();
    return {
      for (final e in payload.entries)
        if (allowed.contains(e.key) && e.key != 'sync_status') e.key: e.value,
    };
  }

  @override
  Future<Map<String, List<Map<String, dynamic>>>> pull(DateTime since) async {
    registerAllSyncMetas();
    final result = <String, List<Map<String, dynamic>>>{};
    for (final meta in SyncableDao.knownMetas) {
      final rows = await _client
          .from(meta.tableName)
          .select()
          .gt('updated_at', since.toUtc().toIso8601String())
          .limit(500);
      result[meta.entityType] =
          rows.cast<Map<String, dynamic>>().toList(growable: false);
    }
    return result;
  }
}

/// Transport tandingan untuk pengujian: mencatat semua push, mengembalikan
/// antrian pull manual. Pada mode offline transport ini selalu "gagal" secara
/// halus (tidak melempar) sehingga aplikasi tetap berjalan penuh.
class InMemorySyncTransport implements SyncTransport {
  InMemorySyncTransport({this.online = true});

  bool online;
  final List<OutboxItem> pushed = [];
  final List<String> rejectIds = [];
  final Map<String, List<Map<String, dynamic>>> remoteData = {};

  @override
  Future<List<String>> push(List<OutboxItem> batch) async {
    if (!online) {
      throw const SyncNetworkException('offline (mode uji)');
    }
    final accepted = <String>[];
    for (final item in batch) {
      if (rejectIds.contains(item.id)) continue;
      pushed.add(item);
      accepted.add(item.id);
    }
    return accepted;
  }

  @override
  Future<Map<String, List<Map<String, dynamic>>>> pull(DateTime since) async {
    if (!online) {
      throw const SyncNetworkException('offline (mode uji)');
    }
    return remoteData;
  }
}

class SyncNetworkException implements Exception {
  const SyncNetworkException(this.message);
  final String message;
  @override
  String toString() => 'SyncNetworkException: $message';
}

/// Status engine sinkronisasi untuk ditampilkan di UI.
enum SyncPhase { idle, syncing, offline, error }

class SyncStatus {
  const SyncStatus({
    required this.phase,
    required this.pendingCount,
    this.lastSyncAt,
    this.inFlight = 0,
    this.failedCount = 0,
    this.message,
  });

  final SyncPhase phase;
  final int pendingCount;
  final DateTime? lastSyncAt;
  final int inFlight;
  final int failedCount;
  final String? message;

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pendingCount,
    DateTime? lastSyncAt,
    int? inFlight,
    int? failedCount,
    String? message,
  }) =>
      SyncStatus(
        phase: phase ?? this.phase,
        pendingCount: pendingCount ?? this.pendingCount,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        inFlight: inFlight ?? this.inFlight,
        failedCount: failedCount ?? this.failedCount,
        message: message,
      );

  bool get isUpToDate =>
      pendingCount == 0 && phase != SyncPhase.error && phase != SyncPhase.offline;
}

/// Engine sinkronisasi dua-arah: push outbox + pull perubahan, dengan
/// exponential backoff dan resolusi konflik LWW.
class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required SyncTransport transport,
    bool Function()? onlineChecker,
  })  : _db = db,
        _dao = SyncableDao(db),
        _transport = transport,
        _onlineChecker = onlineChecker ?? _alwaysOnline;

  static bool _alwaysOnline() => true;

  final AppDatabase _db;
  final SyncableDao _dao;
  final SyncTransport _transport;
  final bool Function() _onlineChecker;

  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _last = const SyncStatus(phase: SyncPhase.idle, pendingCount: 0);
  Timer? _periodic;
  bool _running = false;
  Completer<void>? _currentRun;

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus get current => _last;

  static const _metaLastPull = 'last_pull_at';
  static const _metaDeviceId = 'device_id';

  /// Mulai sinkronisasi berkala. Aman dipanggil berulang kali.
  void startPeriodic({Duration interval = AppConstants.periodicSyncInterval}) {
    _periodic?.cancel();
    _periodic = Timer.periodic(interval, (_) => syncNow());
    syncNow();
  }

  void stopPeriodic() {
    _periodic?.cancel();
    _periodic = null;
  }

  /// Jalankan satu siklus push+pull. Bila sedang berjalan, tunggu siklus itu.
  Future<void> syncNow() async {
    if (_running) return _currentRun?.future ?? Future.value();
    _running = true;
    _currentRun = Completer<void>();
    try {
      await _runCycle();
    } finally {
      _running = false;
      _currentRun!.complete();
      _currentRun = null;
    }
  }

  Future<void> _runCycle() async {
    registerAllSyncMetas();
    final pending = await _countPending();
    if (!_onlineChecker()) {
      _emit(const SyncStatus(phase: SyncPhase.offline, pendingCount: 0));
      await _refreshCounts(SyncPhase.offline);
      return;
    }
    _emit(_last.copyWith(phase: SyncPhase.syncing, pendingCount: pending));

    var phase = SyncPhase.idle;
    String? message;
    try {
      await _pushOutbox();
      await _pullRemote();
    } on SyncNetworkException catch (e) {
      phase = SyncPhase.offline;
      message = e.message;
    } catch (e) {
      phase = SyncPhase.error;
      message = '$e';
      debugPrint('SyncEngine gagal: $e');
    }

    final now = DateTime.now().toUtc();
    if (phase == SyncPhase.idle) {
      await _setMeta(_metaLastPull, now.toIso8601String());
    }
    await _refreshCounts(phase, lastSyncAt: now, message: message);
  }

  /// Push seluruh item yang jatuh tempo dengan backoff per item.
  Future<void> _pushOutbox() async {
    var guard = 0;
    while (guard++ < 20) {
      final items = await _dueItems();
      if (items.isEmpty) return;
      for (final item in items) {
        try {
          final accepted = await _transport.push([_toRecord(item)]);
          if (accepted.contains(item.id)) {
            await _dao.markQueueItemDone(item.id);
            await _markEntitySynced(item.entityType, item.entityId);
          } else {
            await _scheduleRetry(item, 'ditolak server');
          }
        } catch (e) {
          await _scheduleRetry(item, '$e');
          rethrow;
        }
      }
    }
  }

  OutboxItem _toRecord(OutboxItemData d) => (
        id: d.id,
        entityType: d.entityType,
        entityId: d.entityId,
        operation: d.operation,
        payload: d.payload,
        retryCount: d.retryCount,
      );

  Future<void> _scheduleRetry(OutboxItemData item, String error) async {
    final attempt = item.retryCount + 1;
    if (attempt > AppConstants.maxSyncRetries) {
      await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id)))
          .write(const SyncQueueCompanion(
        status: Value(SyncQueueStatuses.failed),
      ));
      return;
    }
    final backoff = AppConstants.syncBackoff[
        (attempt - 1).clamp(0, AppConstants.syncBackoff.length - 1)];
    await _dao.markQueueItemFailed(
      item.id,
      error.length > 300 ? error.substring(0, 300) : error,
      DateTime.now().toUtc().add(backoff),
      attempt,
    );
  }

  Future<void> _markEntitySynced(String entityType, String entityId) async {
    final meta = SyncableDao.metaFor(entityType);
    if (meta == null) return;
    await _db.customUpdate(
      'UPDATE "${meta.tableName}" SET "sync_status" = ?1 WHERE "id" = ?2',
      variables: [
        Variable.withString(SyncStatuses.synced),
        Variable.withString(entityId),
      ],
    );
  }

  /// Pull perubahan remote dan terapkan dengan resolusi LWW.
  Future<void> _pullRemote() async {
    final since = await _getMeta(_metaLastPull);
    final sinceTime = since == null
        ? DateTime.utc(2000)
        : _safeParseDateTime(since)!.subtract(const Duration(seconds: 2));
    final changes = await _transport.pull(sinceTime);
    for (final entry in changes.entries) {
      for (final row in entry.value) {
        final deletedAt = row['deleted_at'];
        if (deletedAt != null) {
          // Terapkan soft-delete remote sebagai baris tersinkron.
          await _dao.applyRemoteUpsert(entry.key, {
            ...row,
            'deleted_at': deletedAt.toString(),
          });
        } else {
          await _dao.applyRemoteUpsert(entry.key, row);
        }
      }
    }
  }

  Future<List<OutboxItemData>> _dueItems() => _dao.dueQueueItems();

  Future<int> _countPending() => _dao.countPendingQueue();

  Future<void> _refreshCounts(
    SyncPhase phase, {
    DateTime? lastSyncAt,
    String? message,
  }) async {
    final pending = await _countPending();
    final failed = await _dao.countFailedQueue();
    _emit(SyncStatus(
      phase: phase,
      pendingCount: pending,
      failedCount: failed,
      lastSyncAt: lastSyncAt ?? _last.lastSyncAt,
      message: message,
    ));
  }

  Future<String?> _getMeta(String key) async {
    final row = await (_db.select(_db.syncMetadata)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> _setMeta(String key, String value) =>
      _db.into(_db.syncMetadata).insertOnConflictUpdate(
            SyncMetadataCompanion.insert(key: key, value: value),
          );

  /// Pastikan device id unik tersimpan (untuk audit multi-perangkat).
  Future<String> ensureDeviceId(String deviceId) async {
    final existing = await _getMeta(_metaDeviceId);
    if (existing != null) return existing;
    await _setMeta(_metaDeviceId, deviceId);
    return deviceId;
  }

  void _emit(SyncStatus s) {
    _last = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }

  Future<void> dispose() async {
    stopPeriodic();
    await _statusController.close();
  }
}

/// Parse tanggal aman dari berbagai sumber (ISO8601, integer ms, integer detik).
///
/// Konsisten dengan format Supabase (ISO8601 UTC) dan SQLite Drift
/// (integer millisecondsSinceEpoch UTC). Jika integer < 1e12 dianggap detik
/// Unix epoch dan dikalikan 1000 → milidetik.
DateTime? _safeParseDateTime(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v.toUtc();
  final s = v.toString();
  final asNum = int.tryParse(s);
  if (asNum != null) {
    final ms = asNum < 1000000000000 ? asNum * 1000 : asNum;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }
  return DateTime.tryParse(s)?.toUtc();
}
