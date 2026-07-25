import 'student_model.dart';
import '../../programs/models/program_model.dart';

class EnrollmentModel {
  final String id;
  final String programId;
  final String studentId;
  final DateTime? enrollmentDate;
  final StudentModel? student;
  final ProgramModel? program;

  const EnrollmentModel({
    required this.id,
    required this.programId,
    required this.studentId,
    this.enrollmentDate,
    this.student,
    this.program,
  });

  /// Factory constructor to parse PostgreSQL json results cleanly and defensively.
  /// Handles nested `students` and `programs` objects returned from relational joins,
  /// whether returned as a Map or a List from PostgREST.
  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    final studentRaw = json['students'];
    Map<String, dynamic>? studentJson;
    if (studentRaw is Map<String, dynamic>) {
      studentJson = studentRaw;
    } else if (studentRaw is List && studentRaw.isNotEmpty) {
      studentJson = studentRaw.first as Map<String, dynamic>?;
    }

    final programRaw = json['programs'];
    Map<String, dynamic>? programJson;
    if (programRaw is Map<String, dynamic>) {
      programJson = programRaw;
    } else if (programRaw is List && programRaw.isNotEmpty) {
      programJson = programRaw.first as Map<String, dynamic>?;
    }

    return EnrollmentModel(
      id: json['id'] as String? ?? '',
      programId: json['program_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      enrollmentDate: json['enrollment_date'] != null
          ? DateTime.tryParse(json['enrollment_date'] as String)
          : null,
      student: studentJson != null ? StudentModel.fromJson(studentJson) : null,
      program: programJson != null ? ProgramModel.fromJson(programJson) : null,
    );
  }

  /// Converts the model to a JSON map suitable for PostgreSQL insertion.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'program_id': programId,
      'student_id': studentId,
      if (enrollmentDate != null)
        'enrollment_date': enrollmentDate?.toIso8601String(),
      if (student != null) 'students': student?.toJson(),
      if (program != null) 'programs': program?.toJson(),
    };
  }
}
