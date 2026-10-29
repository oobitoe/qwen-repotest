/// Item keranjang belanja.
class CartItem {
  const CartItem({
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

  CartItem copyWith({
    String? productId,
    String? productName,
    String? sku,
    double? unitPrice,
    double? costPrice,
    double? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Entitas penjualan.
class SaleEntity {
  const SaleEntity({
    required this.id,
    required this.invoiceNumber,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.isCredit,
    required this.cashierId,
    required this.createdAt,
    this.status = 'completed',
    this.customerNameSnapshot,
  });

  final String id;
  final String invoiceNumber;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final bool isCredit;
  final String cashierId;
  final DateTime createdAt;
  final String? status; // completed | voided | held
  final String? customerNameSnapshot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SaleEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Transaksi yang ditahan (hold) untuk dilanjutkan nanti.
class HoldTransactionEntity {
  const HoldTransactionEntity({
    required this.id,
    required this.invoiceNumber,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.isCredit,
    required this.cashierId,
    required this.createdAt,
    this.customerNameSnapshot,
  });

  final String id;
  final String invoiceNumber;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final bool isCredit;
  final String cashierId;
  final DateTime createdAt;
  final String? customerNameSnapshot;
}
