import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import 'debt_entity.dart';

/// Repository hutang & piutang dengan sinkronisasi outbox (local-first).
class DebtRepository {
  DebtRepository(this._db, this._dao);

  final AppDatabase _db;
  final SyncableDao _dao;
  // ignore: prefer_const_constructors
  final Uuid _uuid = Uuid();

  /// Stream semua hutang/piutang aktif, difilter per businessId dan storeId.
  Stream<List<DebtEntity>> watchDebts({
    bool onlyActive = true,
    required String businessId,
    required String storeId,
  }) {
    final q = _db.select(_db.debts)
      ..where((t) => t.businessId.equals(businessId) & t.storeId.equals(storeId));
    if (onlyActive) {
      q.where((t) => t.status.equals('open') | t.status.equals('partially_paid'));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          DebtEntity(
            id: r.id,
            businessId: r.businessId,
            storeId: r.storeId,
            supplierId: r.supplierId,
            customerId: r.customerId,
            type: r.type,
            amount: r.amount,
            paidAmount: r.paidAmount,
            status: r.status,
            dueDate: r.dueDate,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
      ];
    });
  }

  /// Stream hutang/piutang by tipe (payable/receivable), difilter per businessId dan storeId.
  Stream<List<DebtEntity>> watchDebtsByType({
    required String type,
    required String businessId,
    required String storeId,
  }) {
    return (_db.select(_db.debts)
          ..where((t) => t.businessId.equals(businessId) & t.storeId.equals(storeId) & t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) {
      return [
        for (final r in rows)
          DebtEntity(
            id: r.id,
            businessId: r.businessId,
            storeId: r.storeId,
            supplierId: r.supplierId,
            customerId: r.customerId,
            type: r.type,
            amount: r.amount,
            paidAmount: r.paidAmount,
            status: r.status,
            dueDate: r.dueDate,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
      ];
    });
  }

  /// Stream pembayaran untuk hutang tertentu.
  Stream<List<DebtPaymentEntity>> watchDebtPayments({
    required String debtId,
    required String businessId,
    required String storeId,
  }) {
    return (_db.select(_db.debtPayments)
          ..where((t) => t.debtId.equals(debtId) & t.businessId.equals(businessId) & t.storeId.equals(storeId))
          ..orderBy([(t) => OrderingTerm.desc(t.paidAt)]))
        .watch()
        .map((rows) {
      return [
        for (final r in rows)
          DebtPaymentEntity(
            id: r.id,
            debtId: r.debtId,
            amount: r.amount,
            paidAt: r.paidAt,
            createdBy: r.createdBy,
          ),
      ];
    });
  }

  /// Simpan hutang/piutang (create atau update) dan enqueue ke outbox.
  Future<void> saveDebt({
    required String id,
    required String businessId,
    required String storeId,
    required String? supplierId,
    required String? customerId,
    required String type,
    required double amount,
    required double paidAmount,
    required String status,
    required DateTime? dueDate,
  }) async {
    await _dao.upsertAndEnqueue(
      'debt',
      {
        'supplier_id': supplierId,
        'customer_id': customerId,
        'type': type,
        'amount': amount,
        'paid_amount': paidAmount,
        'status': status,
        'due_date': dueDate?.millisecondsSinceEpoch,
        'business_id': businessId,
        'store_id': storeId,
      },
      id: id,
    );
  }

  /// Hapus hutang/piutang (soft delete) dan enqueue ke outbox.
  Future<void> deleteDebt(String id) async {
    await _dao.softDeleteAndEnqueue('debt', id);
  }

  /// Tambah pembayaran hutang/piutang.
  Future<void> addPayment({
    required String debtId,
    required double amount,
    String? createdBy,
    required String businessId,
    required String storeId,
  }) async {
    final paymentId = _uuid.v4();

    // Get current debt
    final debt = await (_db.select(_db.debts)
          ..where((t) => t.id.equals(debtId)))
        .getSingleOrNull();

    if (debt == null) {
      throw Exception('Hutang/Piutang tidak ditemukan');
    }

    final newPaidAmount = debt.paidAmount + amount;
    String newStatus;
    if (newPaidAmount >= debt.amount) {
      newStatus = 'paid';
    } else if (newPaidAmount > 0) {
      newStatus = 'partially_paid';
    } else {
      newStatus = 'open';
    }

    await _db.transaction(() async {
      // Insert payment
      await _db.into(_db.debtPayments).insert(
            DebtPaymentsCompanion.insert(
              id: paymentId,
              debtId: debtId,
              businessId: Value(businessId),
              storeId: Value(storeId),
              amount: amount,
              paidAt: Value(DateTime.now().toUtc()),
              createdBy: Value(createdBy),
            ),
          );

      // Update debt
      await (_db.update(_db.debts)..where((t) => t.id.equals(debtId)))
          .write(DebtsCompanion(
            paidAmount: Value(newPaidAmount),
            status: Value(newStatus),
            updatedAt: Value(DateTime.now().toUtc()),
          ));
    });

    // Enqueue ke outbox
    await _dao.upsertAndEnqueue(
      'debt_payment',
      {
        'id': paymentId,
        'debt_id': debtId,
        'amount': amount,
        'paid_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        'created_by': createdBy,
        'business_id': businessId,
        'store_id': storeId,
      },
      id: paymentId,
    );

    await _dao.upsertAndEnqueue(
      'debt',
      {
        'paid_amount': newPaidAmount,
        'status': newStatus,
        'business_id': businessId,
        'store_id': storeId,
      },
      id: debtId,
    );
  }

  /// Total hutang (payable) yang belum lunas.
  Future<double> totalPayable({required String businessId, required String storeId}) async {
    final rows = await (_db.select(_db.debts)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.storeId.equals(storeId) &
              t.type.equals('payable') &
              (t.status.equals('open') | t.status.equals('partially_paid'))))
        .get();
    return rows.fold<double>(0.0, (sum, r) => sum + (r.amount - r.paidAmount));
  }

  /// Total piutang (receivable) yang belum lunas.
  Future<double> totalReceivable({required String businessId, required String storeId}) async {
    final rows = await (_db.select(_db.debts)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.storeId.equals(storeId) &
              t.type.equals('receivable') &
              (t.status.equals('open') | t.status.equals('partially_paid'))))
        .get();
    return rows.fold<double>(0.0, (sum, r) => sum + (r.amount - r.paidAmount));
  }

  /// Hutang/piutang yang jatuh tempo (due date <= today dan belum lunas).
  Future<List<DebtEntity>> overdueDebts({required String businessId, required String storeId}) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final rows = await (_db.select(_db.debts)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.storeId.equals(storeId) &
              t.dueDate.isSmallerOrEqualValue(startOfDay) &
              (t.status.equals('open') | t.status.equals('partially_paid'))))
        .get();
    return [
      for (final r in rows)
        DebtEntity(
          id: r.id,
          businessId: r.businessId,
          storeId: r.storeId,
          supplierId: r.supplierId,
          customerId: r.customerId,
          type: r.type,
          amount: r.amount,
          paidAmount: r.paidAmount,
          status: r.status,
          dueDate: r.dueDate,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
        ),
    ];
  }
}

/// Provider repository hutang/piutang.
final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(syncDaoProvider);
  return DebtRepository(db, dao);
});

/// Stream hutang/piutang aktif untuk UI.
final debtsProvider = StreamProvider.family<List<DebtEntity>, ({String businessId, String storeId})>((ref, params) {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.watchDebts(businessId: params.businessId, storeId: params.storeId);
});

/// Stream hutang (payable) untuk UI.
final payablesProvider = StreamProvider.family<List<DebtEntity>, ({String businessId, String storeId})>((ref, params) {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.watchDebtsByType(type: 'payable', businessId: params.businessId, storeId: params.storeId);
});

/// Stream piutang (receivable) untuk UI.
final receivablesProvider = StreamProvider.family<List<DebtEntity>, ({String businessId, String storeId})>((ref, params) {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.watchDebtsByType(type: 'receivable', businessId: params.businessId, storeId: params.storeId);
});
