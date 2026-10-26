/// Entitas pembelian.
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
