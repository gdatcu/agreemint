import '../../programs/models/program_model.dart';

class ProspectModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? programId;
  final String? notes;
  final DateTime followUpDate;
  final String status; // 'Pending', 'Contacted', 'Converted', 'Lost'
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProgramModel? program;

  const ProspectModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.programId,
    this.notes,
    required this.followUpDate,
    this.status = 'Pending',
    required this.createdAt,
    required this.updatedAt,
    this.program,
  });

  factory ProspectModel.fromJson(Map<String, dynamic> json) {
    return ProspectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      programId: json['program_id'] as String?,
      notes: json['notes'] as String?,
      followUpDate: DateTime.parse(json['follow_up_date'] as String).toLocal(),
      status: (json['status'] as String?) ?? 'Pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : DateTime.now(),
      program: json['programs'] != null
          ? ProgramModel.fromJson(json['programs'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'program_id': programId,
      'notes': notes,
      'follow_up_date': followUpDate.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProspectModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? programId,
    String? notes,
    DateTime? followUpDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProgramModel? program,
  }) {
    return ProspectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      programId: programId ?? this.programId,
      notes: notes ?? this.notes,
      followUpDate: followUpDate ?? this.followUpDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      program: program ?? this.program,
    );
  }
}
