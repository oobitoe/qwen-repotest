import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/core_providers.dart';

/// Tipe aktivitas yang dicatat dalam audit log.
enum AuditAction {
  create,
  update,
  delete,
  login,
  logout,
  payment,
  refund,
  stockAdjustment,
  priceChange,
  permissionChange,
  settingsChange,
  dataExport,
  dataImport,
  sync,
}

/// Entitas audit log.
class AuditLogEntity {
  const AuditLogEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.description,
    this.oldValue,
    this.newValue,
    this.ipAddress,
    this.deviceInfo,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final AuditAction action;
  final String entityType;
  final String entityId;
  final String description;
  final String? oldValue;
  final String? newValue;
  final String? ipAddress;
  final String? deviceInfo;
  final DateTime createdAt;

  /// Convert to Drift companion untuk insert.
  AuditLogsCompanion toCompanion() {
    return AuditLogsCompanion(
      id: Value(id),
      userId: Value(userId),
      userName: Value(userName),
      action: Value(action.name),
      entityType: Value(entityType),
      entityId: Value(entityId),
      description: Value(description),
      oldValue: Value(oldValue),
      newValue: Value(newValue),
      ipAddress: Value(ipAddress),
      deviceInfo: Value(deviceInfo),
      createdAt: Value(createdAt.toUtc()),
    );
  }

  /// Create from Drift row.
  static AuditLogEntity fromRow(AuditLog row) {
    return AuditLogEntity(
      id: row.id,
      userId: row.userId,
      userName: row.userName,
      action: AuditAction.values.firstWhere(
        (e) => e.name == row.action,
        orElse: () => AuditAction.update,
      ),
      entityType: row.entityType,
      entityId: row.entityId,
      description: row.description,
      oldValue: row.oldValue,
      newValue: row.newValue,
      ipAddress: row.ipAddress,
      deviceInfo: row.deviceInfo,
      createdAt: row.createdAt,
    );
  }

  AuditLogEntity copyWith({
    String? id,
    String? userId,
    String? userName,
    AuditAction? action,
    String? entityType,
    String? entityId,
    String? description,
    String? oldValue,
    String? newValue,
    String? ipAddress,
    String? deviceInfo,
    DateTime? createdAt,
  }) {
    return AuditLogEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      description: description ?? this.description,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      ipAddress: ipAddress ?? this.ipAddress,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Repository untuk audit log.
class AuditLogRepository {
  AuditLogRepository(this._db);

  final AppDatabase _db;

  /// Catat aktivitas audit.
  Future<void> log({
    required String userId,
    required String userName,
    required AuditAction action,
    required String entityType,
    required String entityId,
    required String description,
    String? oldValue,
    String? newValue,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    final entry = AuditLogEntity(
      id: const Uuid().v4(),
      userId: userId,
      userName: userName,
      action: action,
      entityType: entityType,
      entityId: entityId,
      description: description,
      oldValue: oldValue,
      newValue: newValue,
      ipAddress: ipAddress,
      deviceInfo: deviceInfo,
      createdAt: DateTime.now().toUtc(),
    );

    await _db.into(_db.auditLogs).insert(entry.toCompanion());
  }

  /// Catat aktivitas dengan deteksi perubahan otomatis.
  Future<void> logChange({
    required String userId,
    required String userName,
    required String entityType,
    required String entityId,
    required String fieldName,
    required dynamic oldValue,
    required dynamic newValue,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    if (oldValue == newValue) return;

    await log(
      userId: userId,
      userName: userName,
      action: AuditAction.update,
      entityType: entityType,
      entityId: entityId,
      description: 'Mengubah $fieldName dari "$oldValue" menjadi "$newValue"',
      oldValue: oldValue.toString(),
      newValue: newValue.toString(),
      ipAddress: ipAddress,
      deviceInfo: deviceInfo,
    );
  }

  /// Catat pembuatan entity baru.
  Future<void> logCreate({
    required String userId,
    required String userName,
    required String entityType,
    required String entityId,
    required String description,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    await log(
      userId: userId,
      userName: userName,
      action: AuditAction.create,
      entityType: entityType,
      entityId: entityId,
      description: description,
      ipAddress: ipAddress,
      deviceInfo: deviceInfo,
    );
  }

  /// Catat penghapusan entity.
  Future<void> logDelete({
    required String userId,
    required String userName,
    required String entityType,
    required String entityId,
    required String description,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    await log(
      userId: userId,
      userName: userName,
      action: AuditAction.delete,
      entityType: entityType,
      entityId: entityId,
      description: description,
      ipAddress: ipAddress,
      deviceInfo: deviceInfo,
    );
  }

  /// Ambil audit log dengan filter.
  Future<List<AuditLogEntity>> getLogs({
    String? userId,
    String? entityType,
    String? entityId,
    AuditAction? action,
    DateTime? startDate,
    DateTime? endDate,
    String? query,
    int limit = 100,
    int offset = 0,
  }) async {
    var q = _db.select(_db.auditLogs);

    if (userId != null) {
      q.where((t) => t.userId.equals(userId));
    }
    if (entityType != null) {
      q.where((t) => t.entityType.equals(entityType));
    }
    if (entityId != null) {
      q.where((t) => t.entityId.equals(entityId));
    }
    if (action != null) {
      q.where((t) => t.action.equals(action.name));
    }
    if (startDate != null) {
      q.where((t) => t.createdAt.isBiggerOrEqualValue(startDate.toUtc()));
    }
    if (endDate != null) {
      q.where((t) => t.createdAt.isSmallerOrEqualValue(endDate.toUtc()));
    }
    if (query != null && query.isNotEmpty) {
      final searchTerm = '%$query%';
      q.where((t) =>
          t.description.like(searchTerm) |
          t.entityType.like(searchTerm) |
          t.entityId.like(searchTerm) |
          t.userName.like(searchTerm));
    }

    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    q.limit(limit, offset: offset);

    final rows = await q.get();
    return rows.map(AuditLogEntity.fromRow).toList();
  }

  /// Ambil statistik audit log.
  Future<Map<String, int>> getStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _db.select(_db.auditLogs);

    if (startDate != null) {
      query.where((t) => t.createdAt.isBiggerOrEqualValue(startDate.toUtc()));
    }
    if (endDate != null) {
      query.where((t) => t.createdAt.isSmallerOrEqualValue(endDate.toUtc()));
    }

    final rows = await query.get();

    final stats = <String, int>{};
    for (final row in rows) {
      final action = row.action;
      stats[action] = (stats[action] ?? 0) + 1;
    }

    return stats;
  }
}

/// Provider untuk AuditLogRepository.
final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository(ref.watch(databaseProvider));
});