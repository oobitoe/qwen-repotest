/// Entitas bersama untuk fitur produk dan kategori.

class ProductEntity {
  const ProductEntity({
    required this.id,
    required this.sku,
    this.barcode,
    required this.name,
    this.description,
    this.categoryId,
    this.unitId,
    required this.costPrice,
    required this.sellPrice,
    this.wholesalePrice,
    required this.minStock,
    required this.stock,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sku;
  final String? barcode;
  final String name;
  final String? description;
  final String? categoryId;
  final String? unitId;
  final double costPrice;
  final double sellPrice;
  final double? wholesalePrice;
  final double minStock;
  final double stock;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductEntity copyWith({
    String? id,
    String? sku,
    String? barcode,
    String? name,
    String? description,
    String? categoryId,
    String? unitId,
    double? costPrice,
    double? sellPrice,
    double? wholesalePrice,
    double? minStock,
    double? stock,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      unitId: unitId ?? this.unitId,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      minStock: minStock ?? this.minStock,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'ProductEntity(id: $id, sku: $sku, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryEntity copyWith({
    String? id,
    String? name,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'CategoryEntity(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
