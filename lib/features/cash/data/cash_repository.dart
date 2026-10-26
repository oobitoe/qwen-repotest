import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import 'cash_entity.dart';

/// Repository sesi kasir dan rekas kas (via sync_queue).
class CashRepository {
  CashRepository(this._dao);

  final SyncableDao _dao;
  final Uuid _uuid = Uuid();

  Stream<List<CashSessionEntity>> watchSessions() => Stream.value([]);

  Stream<List<CashRegisterEntity>> watchRegisters() => Stream.value([]);

  Future<void> openSession({
    required String registerId,
    required String registerName,
    required double openingBalance,
    required String openedBy,
  }) async {
    final sessionId = _uuid.v4();
    await _dao.enqueue(
      entityType: 'cash_session',
      entityId: sessionId,
      operation: 'upsert',
      payload: {
        'id': sessionId,
        'register_id': registerId,
        'register_name': registerName,
        'opened_by': openedBy,
        'opened_at': DateTime.now().toUtc().toIso8601String(),
        'opening_balance': openingBalance,
        'status': 'open',
      },
    );
  }

  Future<void> closeSession({
    required String sessionId,
    required double actualBalance,
    required String closedBy,
  }) async {
    await _dao.enqueue(
      entityType: 'cash_session_close',
      entityId: sessionId,
      operation: 'upsert',
      payload: {
        'session_id': sessionId,
        'closed_at': DateTime.now().toUtc().toIso8601String(),
        'actual_balance': actualBalance,
        'closed_by': closedBy,
        'status': 'closed',
      },
    );
  }
}

final cashRepositoryProvider = Provider<CashRepository>((ref) {
  final dao = ref.watch(syncDaoProvider);
  return CashRepository(dao);
});

final cashSessionsProvider = StreamProvider<List<CashSessionEntity>>((ref) {
  final repo = ref.watch(cashRepositoryProvider);
  return repo.watchSessions();
});

final cashRegistersProvider = StreamProvider<List<CashRegisterEntity>>((ref) {
  final repo = ref.watch(cashRepositoryProvider);
  return repo.watchRegisters();
});
