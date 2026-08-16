import '../../students/models/enrollment_model.dart';

class PaymentModel {
  final String id;
  final String enrollmentId;
  final double amountDue;
  final double amountPaid;
  final DateTime dueDate;
  final String status;
  final String? paymentMethod;
  final String? receiptUrl;
  final DateTime? receiptGeneratedAt;
  final String? externalInvoiceNumber;
  final String? externalInvoiceUrl;
  final EnrollmentModel? enrollment;

  const PaymentModel({
    required this.id,
    required this.enrollmentId,
    required this.amountDue,
    required this.amountPaid,
    required this.dueDate,
    required this.status,
    this.paymentMethod,
    this.receiptUrl,
    this.receiptGeneratedAt,
    this.externalInvoiceNumber,
    this.externalInvoiceUrl,
    this.enrollment,
  });

  /// Helper getter returning true if the receipt has been officially signed and saved.
  bool get isReceiptSigned =>
      receiptUrl != null && receiptUrl!.toLowerCase().contains('signed');

  /// Alias getters for SOLO invoice details
  String? get invoiceNumber => externalInvoiceNumber;
  String? get invoiceUrl => externalInvoiceUrl;

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
      receiptUrl: json['receipt_url'] as String?,
      receiptGeneratedAt: json['receipt_generated_at'] != null
          ? DateTime.tryParse(json['receipt_generated_at'] as String)
          : null,
      externalInvoiceNumber: json['external_invoice_number'] as String? ??
          json['invoice_number'] as String?,
      externalInvoiceUrl: json['external_invoice_url'] as String? ??
          json['invoice_url'] as String?,
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
      'receipt_url': receiptUrl,
      'receipt_generated_at': receiptGeneratedAt?.toIso8601String(),
      'external_invoice_number': externalInvoiceNumber,
      'external_invoice_url': externalInvoiceUrl,
      if (enrollment != null) 'enrollments': enrollment?.toJson(),
    };
  }
}
