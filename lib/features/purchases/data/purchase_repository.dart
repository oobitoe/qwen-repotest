import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';

/// Entitas pembelian (simplified, tanpa Drift tabel dedicated).
class PurchaseEntity {
  const PurchaseEntity({
    required this.id,
    required this.referenceNumber,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.isCredit,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String referenceNumber;
  final String supplierId;
  final String supplierName;
  final String status;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final bool isCredit;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PurchaseEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Item pembelian.
class PurchaseItemEntity {
  const PurchaseItemEntity({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unitPrice,
    required this.costPrice,
    required this.quantity,
    required this.receivedQuantity,
    required this.lineTotal,
  });

  final String id;
  final String purchaseId;
  final String productId;
  final String productName;
  final String sku;
  final double unitPrice;
  final double costPrice;
  final double quantity;
  final double receivedQuantity;
  final double lineTotal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PurchaseItemEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Repository pembelian — menyimpan data dalam sinkronisasi outbox
/// (JSON payload) untuk persamaan offline-first.
class PurchaseRepository {
  PurchaseRepository(this._dao);

  final SyncableDao _dao;
  // ignore: prefer_const_constructors
  final Uuid _uuid = Uuid();

  Stream<List<PurchaseEntity>> watchPurchases() => Stream.value([]);

  Future<List<PurchaseEntity>> searchPurchases(String query) async => [];

  Future<void> savePurchase({
    required String referenceNumber,
    required String supplierId,
    required String supplierName,
    required List<PurchaseItemInput> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required String paymentMethod,
    required bool isCredit,
    required String createdBy,
  }) async {
    final purchaseId = _uuid.v4();
    await _dao.enqueue(
      entityType: 'purchase',
      entityId: purchaseId,
      operation: 'upsert',
      payload: {
        'id': purchaseId,
        'reference_number': referenceNumber,
        'supplier_id': supplierId,
        'supplier_name': supplierName,
        'status': 'completed',
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'payment_method': paymentMethod,
        'is_credit': isCredit,
        'created_by': createdBy,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }
}

/// Input item pembelian.
class PurchaseItemInput {
  const PurchaseItemInput({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unitPrice,
    required this.costPrice,
    required this.quantity,
  });

  final String productId;
  final String productName;
  final String sku;
  final double unitPrice;
  final double costPrice;
  final double quantity;

  double get lineTotal => unitPrice * quantity;
}

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final dao = ref.watch(syncDaoProvider);
  return PurchaseRepository(dao);
});

final purchasesProvider = StreamProvider<List<PurchaseEntity>>((ref) {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.watchPurchases();
});
