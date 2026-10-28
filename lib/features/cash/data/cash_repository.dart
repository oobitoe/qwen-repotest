import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import 'cash_entity.dart';

/// Repository rekening, mutasi, register kasir, dan sesi kasir dengan sinkronisasi outbox (local-first).
class CashRepository {
  CashRepository(this._db, this._dao);

  final AppDatabase _db;
  final SyncableDao _dao;
  // ignore: prefer_const_constructors
  final Uuid _uuid = Uuid();

  /// Stream semua register kasir aktif.
  Stream<List<CashRegisterEntity>> watchRegisters({bool onlyActive = true}) {
    final q = _db.select(_db.cashRegisters);
    if (onlyActive) {
      q.where((t) => t.isActive.equals(true) & t.deletedAt.isNull());
    }
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          CashRegisterEntity(
            id: r.id,
            name: r.name,
            openingBalance: r.openingBalance,
            isActive: r.isActive,
          ),
      ];
    });
  }

  /// Stream semua sesi kasir.
  Stream<List<CashSessionEntity>> watchSessions({bool onlyActive = true}) {
    final q = _db.select(_db.cashSessions);
    if (onlyActive) {
      q.where((t) => t.status.equals('open'));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.openedAt)]);
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          CashSessionEntity(
            id: r.id,
            registerId: r.registerId,
            openedBy: r.openedBy,
            openedAt: r.openedAt,
            closedAt: r.closedAt,
            openingBalance: r.openingBalance,
            expectedBalance: r.expectedBalance,
            actualBalance: r.actualBalance,
            difference: r.difference,
            status: r.status,
          ),
      ];
    });
  }

  /// Stream mutasi rekening untuk akun tertentu.
  Stream<List<AccountTransactionEntity>> watchAccountTransactions(
      String accountId) {
    return (_db.select(_db.accountTransactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) {
      return [
        for (final r in rows)
          AccountTransactionEntity(
            id: r.id,
            accountId: r.accountId,
            type: r.type,
            amount: r.amount,
            referenceType: r.referenceType,
            referenceId: r.referenceId,
            createdBy: r.createdBy,
            createdAt: r.createdAt,
          ),
      ];
    });
  }

  /// Stream semua rekening aktif.
  Stream<List<AccountEntity>> watchAccounts({bool onlyActive = true}) {
    final q = _db.select(_db.accounts);
    if (onlyActive) {
      q.where((t) => t.isActive.equals(true));
    }
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          AccountEntity(
            id: r.id,
            name: r.name,
            type: r.type,
            balance: r.balance,
            isActive: r.isActive,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
      ];
    });
  }

  /// Simpan register kasir (create atau update) dan enqueue ke outbox.
  Future<void> saveCashRegister(CashRegisterEntity register) async {
    await _dao.upsertAndEnqueue(
      'cash_register',
      {
        'name': register.name,
        'opening_balance': register.openingBalance,
        'is_active': register.isActive,
      },
      id: register.id,
    );
  }

  /// Hapus register kasir (soft delete) dan enqueue ke outbox.
  Future<void> deleteCashRegister(String id) async {
    await _dao.softDeleteAndEnqueue('cash_register', id);
  }

  /// Buka sesi kasir baru.
  Future<void> openSession({
    required String registerId,
    required double openingBalance,
    required String openedBy,
  }) async {
    final sessionId = _uuid.v4();
    await _dao.upsertAndEnqueue(
      'cash_session',
      {
        'register_id': registerId,
        'opened_by': openedBy,
        'opened_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        'opening_balance': openingBalance,
        'status': 'open',
      },
      id: sessionId,
    );
  }

  /// Tutup sesi kasir.
  Future<void> closeSession({
    required String sessionId,
    required double actualBalance,
    required double expectedBalance,
    required double difference,
  }) async {
    await _dao.upsertAndEnqueue(
      'cash_session',
      {
        'closed_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        'actual_balance': actualBalance,
        'expected_balance': expectedBalance,
        'difference': difference,
        'status': 'closed',
      },
      id: sessionId,
    );
  }

  /// Simpan rekening (create atau update) dan enqueue ke outbox.
  Future<void> saveAccount(AccountEntity account) async {
    await _dao.upsertAndEnqueue(
      'account',
      {
        'name': account.name,
        'type': account.type,
        'balance': account.balance,
        'is_active': account.isActive,
      },
      id: account.id,
    );
  }

  /// Hapus rekening (soft delete) dan enqueue ke outbox.
  Future<void> deleteAccount(String id) async {
    await _dao.softDeleteAndEnqueue('account', id);
  }

  /// Tambah mutasi rekening (debit/kredit) dan update saldo rekening.
  Future<void> addAccountTransaction({
    required String accountId,
    required String type, // debit | credit
    required double amount,
    String? referenceType,
    String? referenceId,
    String? createdBy,
  }) async {
    final transactionId = _uuid.v4();
    await _db.transaction(() async {
      // Insert transaksi
      await _db.into(_db.accountTransactions).insert(
            AccountTransactionsCompanion.insert(
              id: transactionId,
              accountId: accountId,
              type: type,
              amount: amount,
              referenceType: Value(referenceType),
              referenceId: Value(referenceId),
              createdBy: Value(createdBy),
              createdAt: Value(DateTime.now().toUtc()),
            ),
          );

      // Update saldo rekening
      final account = await (_db.select(_db.accounts)
            ..where((t) => t.id.equals(accountId)))
          .getSingleOrNull();

      if (account != null) {
        final newBalance = type == 'debit'
            ? account.balance + amount
            : account.balance - amount;
        await (_db.update(_db.accounts)..where((t) => t.id.equals(accountId)))
            .write(AccountsCompanion(balance: Value(newBalance)));
      }
    });

    // Enqueue transaksi ke outbox
    await _dao.upsertAndEnqueue(
      'account_transaction',
      {
        'id': transactionId,
        'account_id': accountId,
        'type': type,
        'amount': amount,
        'reference_type': referenceType,
        'reference_id': referenceId,
        'created_by': createdBy,
        'created_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      id: transactionId,
    );
  }

  /// Total saldo kas (semua register + sesi terbuka).
  Future<double> totalCashBalance() async {
    final registers = await _db.select(_db.cashRegisters).get();
    final sessions = await (_db.select(_db.cashSessions)
          ..where((t) => t.status.equals('open')))
        .get();

    double total = registers.fold(0.0, (sum, r) => sum + r.openingBalance);
    total += sessions.fold(0.0, (sum, s) => sum + (s.actualBalance ?? 0));
    return total;
  }

  /// Total saldo per tipe rekening.
  Future<Map<String, double>> balanceByAccountType() async {
    final accounts = await _db.select(_db.accounts).get();
    final Map<String, double> result = {};
    for (final a in accounts) {
      if (!a.isActive) continue;
      result[a.type] = (result[a.type] ?? 0) + a.balance;
    }
    return result;
  }
}

/// Provider repository kas.
final cashRepositoryProvider = Provider<CashRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(syncDaoProvider);
  return CashRepository(db, dao);
});

/// Stream register kasir aktif untuk UI.
final cashRegistersProvider = StreamProvider<List<CashRegisterEntity>>((ref) {
  final repo = ref.watch(cashRepositoryProvider);
  return repo.watchRegisters();
});

/// Stream sesi kasir untuk UI.
final cashSessionsProvider = StreamProvider<List<CashSessionEntity>>((ref) {
  final repo = ref.watch(cashRepositoryProvider);
  return repo.watchSessions();
});

/// Stream rekening untuk UI.
final accountsProvider = StreamProvider<List<AccountEntity>>((ref) {
  final repo = ref.watch(cashRepositoryProvider);
  return repo.watchAccounts();
});