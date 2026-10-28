import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import 'sale_entity.dart';

/// Repository penjualan & retur (simplified, via sync_queue).
class SaleRepository {
  SaleRepository(this._dao);

  final SyncableDao _dao;
  // ignore: prefer_const_constructors
  final Uuid _uuid = Uuid();

  Stream<List<SaleEntity>> watchSales() => Stream.value([]);

  Future<List<SaleEntity>> searchSales(String query) async => [];

  Future<void> saveSale({
    required String invoiceNumber,
    required String customerId,
    required String customerName,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required String paymentMethod,
    required bool isCredit,
    required String status,
    required String cashierId,
  }) async {
    final saleId = _uuid.v4();
    await _dao.enqueue(
      entityType: 'sale',
      entityId: saleId,
      operation: 'upsert',
      payload: {
        'id': saleId,
        'invoice_number': invoiceNumber,
        'customer_id': customerId,
        'customer_name': customerName,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'payment_method': paymentMethod,
        'is_credit': isCredit,
        'status': status,
        'cashier_id': cashierId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> saveReturn({
    required String returnNumber,
    required String saleId,
    required double total,
    required String cashierId,
  }) async {
    final returnId = _uuid.v4();
    await _dao.enqueue(
      entityType: 'sale_return',
      entityId: returnId,
      operation: 'upsert',
      payload: {
        'id': returnId,
        'return_number': returnNumber,
        'sale_id': saleId,
        'total': total,
        'cashier_id': cashierId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }
}

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final dao = ref.watch(syncDaoProvider);
  return SaleRepository(dao);
});

final salesProvider = StreamProvider<List<SaleEntity>>((ref) {
  final repo = ref.watch(saleRepositoryProvider);
  return repo.watchSales();
});
