import '../../students/models/enrollment_model.dart';

class PaymentModel {
  final String id;
  final String enrollmentId;
  final double amountDue;
  final double amountPaid;
  final DateTime dueDate;
  final String status;
  final String? paymentMethod;
  final EnrollmentModel? enrollment;

  const PaymentModel({
    required this.id,
    required this.enrollmentId,
    required this.amountDue,
    required this.amountPaid,
    required this.dueDate,
    required this.status,
    this.paymentMethod,
    this.enrollment,
  });

  /// Factory constructor to parse PostgreSQL json results cleanly and defensively.
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final enrollmentRaw = json['enrollments'];
    Map<String, dynamic>? enrollmentJson;
    if (enrollmentRaw is Map<String, dynamic>) {
      enrollmentJson = enrollmentRaw;
    } else if (enrollmentRaw is List && enrollmentRaw.isNotEmpty) {
      enrollmentJson = enrollmentRaw.first as Map<String, dynamic>?;
    }

    return PaymentModel(
      id: json['id'] as String? ?? '',
      enrollmentId: json['enrollment_id'] as String? ?? '',
      amountDue: (json['amount_due'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'Pending',
      paymentMethod: json['payment_method'] as String?,
      enrollment: enrollmentJson != null
          ? EnrollmentModel.fromJson(enrollmentJson)
          : null,
    );
  }

  /// Converts the model to a JSON map suitable for PostgreSQL insertion.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount_due': amountDue,
      'amount_paid': amountPaid,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'payment_method': paymentMethod,
      if (enrollment != null) 'enrollments': enrollment?.toJson(),
    };
  }
}
