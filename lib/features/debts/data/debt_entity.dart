import 'package:intl/intl.dart';

/// Entity hutang/piutang (debt) untuk layer domain/presentation.
class DebtEntity {
  const DebtEntity({
    required this.id,
    this.supplierId,
    this.customerId,
    required this.type, // payable | receivable
    required this.amount,
    this.paidAmount = 0,
    this.status = 'open', // open | partially_paid | paid
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? supplierId;
  final String? customerId;
  final String type;
  final double amount;
  final double paidAmount;
  final String status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Helper untuk formatting Rupiah.
  String get formattedAmount => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(amount);

  String get formattedPaidAmount => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(paidAmount);

  String get formattedRemainingAmount => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(amount - paidAmount);

  /// Apakah ini hutang (payable) atau piutang (receivable).
  bool get isPayable => type == 'payable';
  bool get isReceivable => type == 'receivable';

  /// Label tipe.
  String get typeLabel => isPayable ? 'Hutang (Supplier)' : 'Piutang (Pelanggan)';

  /// Label status.
  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Belum Bayar';
      case 'partially_paid':
        return 'Sebagian Dibayar';
      case 'paid':
        return 'Lunas';
      default:
        return status;
    }
  }

  /// Copy with untuk update.
  DebtEntity copyWith({
    String? id,
    String? supplierId,
    String? customerId,
    String? type,
    double? amount,
    double? paidAmount,
    String? status,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DebtEntity(
        id: id ?? this.id,
        supplierId: supplierId ?? this.supplierId,
        customerId: customerId ?? this.customerId,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        paidAmount: paidAmount ?? this.paidAmount,
        status: status ?? this.status,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Entity pembayaran hutang/piutang.
class DebtPaymentEntity {
  const DebtPaymentEntity({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.paidAt,
    this.createdBy,
  });

  final String id;
  final String debtId;
  final double amount;
  final DateTime paidAt;
  final String? createdBy;

  String get formattedAmount => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(amount);
}