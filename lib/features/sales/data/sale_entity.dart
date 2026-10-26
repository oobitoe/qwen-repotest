/// Entitas penjualan.
class SaleEntity {
  const SaleEntity({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.isCredit,
    required this.status,
    required this.cashierId,
    required this.createdAt,
  });

  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final bool isCredit;
  final String status;
  final String cashierId;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SaleEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
