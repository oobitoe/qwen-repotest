/// Entitas supplier.
class SupplierEntity {
  const SupplierEntity({
    required this.id,
    required this.businessId,
    required this.storeId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String businessId;
  final String storeId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupplierEntity copyWith({
    String? id,
    String? businessId,
    String? storeId,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplierEntity(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupplierEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
