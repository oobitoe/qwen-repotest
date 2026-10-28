/// Entitas pergerakan stok.
class StockMovementEntity {
  const StockMovementEntity({
    required this.id,
    required this.productId,
    this.productName,
    required this.type,
    required this.quantity,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.note,
    this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String? productName;
  final String type;
  final double quantity;
  final double balanceAfter;
  final String? referenceType;
  final String? referenceId;
  final String? note;
  final String? createdBy;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMovementEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Entitas penyesuaian stok.
class StockAdjustmentEntity {
  const StockAdjustmentEntity({
    required this.id,
    required this.referenceNumber,
    this.note,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String referenceNumber;
  final String? note;
  final String createdBy;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockAdjustmentEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Entitas stock opname.
class StockOpnameEntity {
  const StockOpnameEntity({
    required this.id,
    required this.referenceNumber,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String referenceNumber;
  final String status;
  final String createdBy;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockOpnameEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
