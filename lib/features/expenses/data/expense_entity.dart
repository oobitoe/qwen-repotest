import 'package:intl/intl.dart';

/// Entity pengeluaran (expense) untuk layer domain/presentation.
class ExpenseEntity {
  const ExpenseEntity({
    required this.id,
    this.categoryId,
    required this.description,
    required this.amount,
    this.paymentMethod = 'cash',
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isActive = true,
  });

  final String id;
  final String? categoryId;
  final String description;
  final double amount;
  final String paymentMethod;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isActive;

  /// Helper untuk formatting Rupiah.
  String get formattedAmount => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(amount);

  /// Copy with untuk update.
  ExpenseEntity copyWith({
    String? id,
    String? categoryId,
    String? description,
    double? amount,
    String? paymentMethod,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isActive,
  }) =>
      ExpenseEntity(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        isActive: isActive ?? this.isActive,
      );
}

/// Entity kategori pengeluaran.
class ExpenseCategoryEntity {
  const ExpenseCategoryEntity({
    required this.id,
    required this.name,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  ExpenseCategoryEntity copyWith({
    String? id,
    String? name,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      ExpenseCategoryEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}