/// Entitas pelanggan dengan tier dan poin reward (PRD 19.3).
class CustomerEntity {
  const CustomerEntity({
    required this.id,
    this.code,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.tier = 'Regular',
    this.rewardPoints = 0,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? code;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final String tier;
  final int rewardPoints;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerEntity copyWith({
    String? id,
    String? code,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    String? tier,
    int? rewardPoints,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      tier: tier ?? this.tier,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
