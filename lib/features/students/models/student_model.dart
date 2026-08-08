class StudentModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? createdAt;
  final String clientType;
  final String? cui;
  final String? regCom;
  final String? billingAddress;

  const StudentModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.createdAt,
    this.clientType = 'PF',
    this.cui,
    this.regCom,
    this.billingAddress,
  });

  /// Factory constructor to parse PostgreSQL json results cleanly and defensively.
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final rawClientType = json['client_type'] as String?;
    return StudentModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      clientType: (rawClientType != null && rawClientType.isNotEmpty)
          ? rawClientType
          : 'PF',
      cui: json['cui'] as String?,
      regCom: json['reg_com'] as String?,
      billingAddress: json['billing_address'] as String?,
    );
  }

  /// Converts the model to a JSON map suitable for PostgreSQL insertion.
  Map<String, dynamic> toJson() {
    final created = createdAt;
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'client_type': clientType,
      'cui': cui,
      'reg_com': regCom,
      'billing_address': billingAddress,
      if (created != null) 'created_at': created.toIso8601String(),
    };
  }
}

