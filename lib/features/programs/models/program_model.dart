class ProgramModel {
  final String id;
  final String name;
  final String? description;
  final double totalPrice;
  final DateTime? createdAt;

  const ProgramModel({
    required this.id,
    required this.name,
    this.description,
    required this.totalPrice,
    this.createdAt,
  });

  /// Factory constructor to parse PostgreSQL json results cleanly and defensively.
  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Converts the model to a JSON map suitable for PostgreSQL insertion.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'total_price': totalPrice,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }
}
