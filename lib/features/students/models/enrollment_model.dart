import 'student_model.dart';
import '../../programs/models/program_model.dart';
import '../../contracts/models/contract_model.dart';
import '../../payments/models/payment_model.dart';

class EnrollmentModel {
  final String id;
  final String programId;
  final String studentId;
  final DateTime? enrollmentDate;
  final StudentModel? student;
  final ProgramModel? program;
  final ContractModel? contract;
  final List<PaymentModel>? payments;

  const EnrollmentModel({
    required this.id,
    required this.programId,
    required this.studentId,
    this.enrollmentDate,
    this.student,
    this.program,
    this.contract,
    this.payments,
  });

  /// True if the contract has been signed by the student / beneficiary and is active.
  bool get isSignedByBeneficiary {
    if (contract == null) return false;
    if (contract!.status == 'Refunded' || contract!.status == 'Cancelled') {
      return false;
    }
    return contract!.status == 'FullySigned' ||
        contract!.clientSignatureUrl != null ||
        contract!.clientSignedDate != null;
  }

  /// True if the contract status is Refunded or Cancelled.
  bool get isRetired =>
      contract?.status == 'Refunded' || contract?.status == 'Cancelled';

  /// Returns date contract was signed or updated.
  DateTime? get signedDate {
    if (contract == null) return null;
    return contract!.clientSignedDate ?? contract!.createdDate;
  }

  /// True if payments list exists, is non-empty, and all installments are Paid.
  bool get isFullyPaid {
    if (payments == null || payments!.isEmpty) return false;
    return payments!.every((p) => p.status == 'Paid');
  }

  /// Number of paid installments.
  int get paidInstallmentsCount {
    if (payments == null) return 0;
    return payments!.where((p) => p.status == 'Paid').length;
  }

  /// Total amount paid so far.
  double get totalPaidAmount {
    if (payments == null) return 0.0;
    return payments!
        .where((p) => p.status == 'Paid')
        .fold(0.0, (sum, p) => sum + p.amountPaid);
  }

  /// True if a payment schedule has been generated for this enrollment.
  bool get hasPaymentPlan => payments != null && payments!.isNotEmpty;

  /// True if a payment plan exists and at least one installment is missing a SOLO invoice.
  bool get hasMissingSoloInvoice =>
      hasPaymentPlan &&
      payments!.any((p) => p.externalInvoiceNumber == null || p.externalInvoiceNumber!.isEmpty);

  /// Number of installments that have a SOLO invoice attached.
  int get soloInvoicesCount {
    if (payments == null) return 0;
    return payments!
        .where((p) => p.externalInvoiceNumber != null && p.externalInvoiceNumber!.isNotEmpty)
        .length;
  }

  /// Number of Paid installments missing a SOLO invoice.
  int get paidMissingSoloInvoicesCount {
    if (payments == null) return 0;
    return payments!
        .where((p) =>
            p.status == 'Paid' &&
            (p.externalInvoiceNumber == null || p.externalInvoiceNumber!.isEmpty))
        .length;
  }

  /// Total sum of all scheduled installments.
  double get totalPaymentsAmount {
    if (payments == null) return 0.0;
    return payments!.fold(0.0, (sum, p) => sum + p.amountDue);
  }

  /// A student can be deleted if the contract has NOT been signed by the beneficiary yet or is refunded/cancelled.
  bool get canBeDeleted {
    if (contract == null) return true;
    if (isRetired) return true;
    return !isSignedByBeneficiary;
  }

  /// Factory constructor to parse PostgreSQL json results cleanly and defensively.
  /// Handles nested `students`, `programs`, `contracts`, and `payments` objects from relational joins.
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

    final paymentsRaw = json['payments'];
    List<PaymentModel>? paymentsList;
    if (paymentsRaw is List) {
      paymentsList = paymentsRaw
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
      payments: paymentsList,
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
      if (payments != null) 'payments': payments?.map((p) => p.toJson()).toList(),
    };
  }
}
