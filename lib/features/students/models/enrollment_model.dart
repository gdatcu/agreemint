import 'student_model.dart';
import '../../programs/models/program_model.dart';
import '../../contracts/models/contract_model.dart';

class EnrollmentModel {
  final String id;
  final String programId;
  final String studentId;
  final DateTime? enrollmentDate;
  final StudentModel? student;
  final ProgramModel? program;
  final ContractModel? contract;

  const EnrollmentModel({
    required this.id,
    required this.programId,
    required this.studentId,
    this.enrollmentDate,
    this.student,
    this.program,
    this.contract,
  });

  /// True if the contract has been signed by the student / beneficiary.
  bool get isSignedByBeneficiary {
    if (contract == null) return false;
    return contract!.status == 'FullySigned' ||
        contract!.clientSignatureUrl != null ||
        contract!.clientSignedDate != null;
  }

  /// A student can be deleted if the contract has NOT been signed by the beneficiary yet.
  bool get canBeDeleted => !isSignedByBeneficiary;

  /// Factory constructor to parse PostgreSQL json results cleanly and defensively.
  /// Handles nested `students`, `programs`, and `contracts` objects from relational joins.
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

    final contractRaw = json['contracts'];
    Map<String, dynamic>? contractJson;
    if (contractRaw is Map<String, dynamic>) {
      contractJson = contractRaw;
    } else if (contractRaw is List && contractRaw.isNotEmpty) {
      contractJson = contractRaw.first as Map<String, dynamic>?;
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
      contract: contractJson != null ? ContractModel.fromJson(contractJson) : null,
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
      if (contract != null) 'contracts': contract?.toJson(),
    };
  }
}
