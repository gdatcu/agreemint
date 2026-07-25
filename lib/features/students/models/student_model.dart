class StudentModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? createdAt;

  const StudentModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.createdAt,
  });

  /// Factory constructor to parse PostgreSQL json results cleanly and defensively.
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
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
      'email': email,
      'phone': phone,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }
}
