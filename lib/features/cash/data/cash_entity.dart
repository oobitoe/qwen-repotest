import 'package:intl/intl.dart';

/// Entitas sesi kasir.
class CashSessionEntity {
  const CashSessionEntity({
    required this.id,
    required this.registerId,
    this.openedBy,
    required this.openedAt,
    this.closedAt,
    required this.openingBalance,
    this.expectedBalance,
    this.actualBalance,
    this.difference,
    this.status = 'open', // open | closed
  });

  final String id;
  final String registerId;
  final String? openedBy;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingBalance;
  final double? expectedBalance;
  final double? actualBalance;
  final double? difference;
  final String status;

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  /// Helper untuk formatting Rupiah.
  String get formattedOpeningBalance => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(openingBalance);

  String? get formattedExpectedBalance => expectedBalance != null
      ? NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(expectedBalance!)
      : null;

  String? get formattedActualBalance => actualBalance != null
      ? NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(actualBalance!)
      : null;

  String? get formattedDifference => difference != null
      ? NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(difference!)
      : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashSessionEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;

  /// Copy with untuk update.
  CashSessionEntity copyWith({
    String? id,
    String? registerId,
    String? openedBy,
    DateTime? openedAt,
    DateTime? closedAt,
    double? openingBalance,
    double? expectedBalance,
    double? actualBalance,
    double? difference,
    String? status,
  }) =>
      CashSessionEntity(
        id: id ?? this.id,
        registerId: registerId ?? this.registerId,
        openedBy: openedBy ?? this.openedBy,
        openedAt: openedAt ?? this.openedAt,
        closedAt: closedAt ?? this.closedAt,
        openingBalance: openingBalance ?? this.openingBalance,
        expectedBalance: expectedBalance ?? this.expectedBalance,
        actualBalance: actualBalance ?? this.actualBalance,
        difference: difference ?? this.difference,
        status: status ?? this.status,
      );
}

/// Entitas rekas kas.
class CashRegisterEntity {
  const CashRegisterEntity({
    required this.id,
    required this.name,
    this.openingBalance = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final double openingBalance;
  final bool isActive;

  String get formattedOpeningBalance => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(openingBalance);

  /// Copy with untuk update.
  CashRegisterEntity copyWith({
    String? id,
    String? name,
    double? openingBalance,
    bool? isActive,
  }) =>
      CashRegisterEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        openingBalance: openingBalance ?? this.openingBalance,
        isActive: isActive ?? this.isActive,
      );
}

/// Entity rekening (account) untuk layer domain/presentation.
class AccountEntity {
  const AccountEntity({
    required this.id,
    required this.name,
    required this.type, // cash | bank | e_wallet
    this.balance = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String type;
  final double balance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Helper untuk formatting Rupiah.
  String get formattedBalance => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(balance);

  /// Label tipe rekening.
  String get typeLabel {
    switch (type) {
      case 'cash':
        return 'Kas';
      case 'bank':
        return 'Bank';
      case 'e_wallet':
        return 'E-Wallet';
      default:
        return type;
    }
  }

  /// Copy with untuk update.
  AccountEntity copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AccountEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        balance: balance ?? this.balance,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Entity mutasi rekening (account transaction).
class AccountTransactionEntity {
  const AccountTransactionEntity({
    required this.id,
    required this.accountId,
    required this.type, // debit | credit
    required this.amount,
    this.referenceType,
    this.referenceId,
    this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String accountId;
  final String type;
  final double amount;
  final String? referenceType;
  final String? referenceId;
  final String? createdBy;
  final DateTime createdAt;

  /// Helper untuk formatting Rupiah.
  String get formattedAmount => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(amount);

  bool get isDebit => type == 'debit';
  bool get isCredit => type == 'credit';

  /// Copy with untuk update.
  AccountTransactionEntity copyWith({
    String? id,
    String? accountId,
    String? type,
    double? amount,
    String? referenceType,
    String? referenceId,
    String? createdBy,
    DateTime? createdAt,
  }) =>
      AccountTransactionEntity(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        referenceType: referenceType ?? this.referenceType,
        referenceId: referenceId ?? this.referenceId,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
      );
}