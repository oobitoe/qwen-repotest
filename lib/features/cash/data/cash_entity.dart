/// Entitas sesi kasir.
class CashSessionEntity {
  const CashSessionEntity({
    required this.id,
    required this.registerId,
    required this.registerName,
    required this.openedBy,
    required this.openedAt,
    this.closedAt,
    required this.openingBalance,
    this.expectedBalance,
    this.actualBalance,
    this.difference,
    required this.status,
  });

  final String id;
  final String registerId;
  final String registerName;
  final String openedBy;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingBalance;
  final double? expectedBalance;
  final double? actualBalance;
  final double? difference;
  final String status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashSessionEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Entitas rekas kas.
class CashRegisterEntity {
  const CashRegisterEntity({
    required this.id,
    required this.name,
    required this.openingBalance,
    required this.isActive,
  });

  final String id;
  final String name;
  final double openingBalance;
  final bool isActive;
}
