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

  /// Stream semua hutang/piutang aktif.
  Stream<List<DebtEntity>> watchDebts({bool onlyActive = true}) {
    final q = _db.select(_db.debts);
    if (onlyActive) {
      q.where((t) => t.status.equals('open') | t.status.equals('partially_paid'));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          DebtEntity(
            id: r.id,
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

  /// Stream hutang/piutang by tipe (payable/receivable).
  Stream<List<DebtEntity>> watchDebtsByType(String type) {
    return (_db.select(_db.debts)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) {
      return [
        for (final r in rows)
          DebtEntity(
            id: r.id,
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
  Stream<List<DebtPaymentEntity>> watchDebtPayments(String debtId) {
    return (_db.select(_db.debtPayments)
          ..where((t) => t.debtId.equals(debtId))
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
  Future<void> saveDebt(DebtEntity debt) async {
    await _dao.upsertAndEnqueue(
      'debt',
      {
        'supplier_id': debt.supplierId,
        'customer_id': debt.customerId,
        'type': debt.type,
        'amount': debt.amount,
        'paid_amount': debt.paidAmount,
        'status': debt.status,
        'due_date': debt.dueDate?.toIso8601String().split('T').first,
      },
      id: debt.id,
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
        'paid_at': DateTime.now().toUtc().toIso8601String(),
        'created_by': createdBy,
      },
      id: paymentId,
    );

    await _dao.upsertAndEnqueue(
      'debt',
      {
        'paid_amount': newPaidAmount,
        'status': newStatus,
      },
      id: debtId,
    );
  }

  /// Total hutang (payable) yang belum lunas.
  Future<double> totalPayable() async {
    final rows = await (_db.select(_db.debts)
          ..where((t) =>
              t.type.equals('payable') &
              (t.status.equals('open') | t.status.equals('partially_paid'))))
        .get();
    return rows.fold<double>(0.0, (sum, r) => sum + (r.amount - r.paidAmount));
  }

  /// Total piutang (receivable) yang belum lunas.
  Future<double> totalReceivable() async {
    final rows = await (_db.select(_db.debts)
          ..where((t) =>
              t.type.equals('receivable') &
              (t.status.equals('open') | t.status.equals('partially_paid'))))
        .get();
    return rows.fold<double>(0.0, (sum, r) => sum + (r.amount - r.paidAmount));
  }

  /// Hutang/piutang yang jatuh tempo (due date <= today dan belum lunas).
  Future<List<DebtEntity>> overdueDebts() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final rows = await (_db.select(_db.debts)
          ..where((t) =>
              t.dueDate.isSmallerOrEqualValue(startOfDay) &
              (t.status.equals('open') | t.status.equals('partially_paid'))))
        .get();
    return [
      for (final r in rows)
        DebtEntity(
          id: r.id,
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
final debtsProvider = StreamProvider<List<DebtEntity>>((ref) {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.watchDebts();
});

/// Stream hutang (payable) untuk UI.
final payablesProvider = StreamProvider<List<DebtEntity>>((ref) {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.watchDebtsByType('payable');
});

/// Stream piutang (receivable) untuk UI.
final receivablesProvider = StreamProvider<List<DebtEntity>>((ref) {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.watchDebtsByType('receivable');
});