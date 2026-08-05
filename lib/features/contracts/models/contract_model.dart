import '../../students/models/enrollment_model.dart';

class ContractModel {
  final String id;
  final String enrollmentId;
  final int contractNumber;
  final String? pdfUrl;
  final String? signedPdfUrl;
  final DateTime? signedDate;
  final String status; // 'Draft', 'PendingClient', 'FullySigned'
  final DateTime? createdAt;
  final String? mentorSignatureUrl;
  final String? clientSignatureUrl;
  final DateTime? clientSignedDate;
  final double? priceRon;
  final Map<String, dynamic>? details;
  final EnrollmentModel? enrollment;

  const ContractModel({
    required this.id,
    required this.enrollmentId,
    required this.contractNumber,
    this.pdfUrl,
    this.signedPdfUrl,
    this.signedDate,
    this.status = 'Draft',
    this.createdAt,
    this.mentorSignatureUrl,
    this.clientSignatureUrl,
    this.clientSignedDate,
    this.priceRon,
    this.details,
    this.enrollment,
  });

  /// Sanitizes signed/expiring Supabase storage URLs into permanent public URLs.
  static String? normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.contains('/object/sign/')) {
      final publicUrl = url.replaceAll('/object/sign/', '/object/public/');
      return publicUrl.split('?')[0];
    }
    if (url.contains('?token=')) {
      return url.split('?')[0];
    }
    return url;
  }

  /// Factory constructor to parse PostgreSQL json results cleanly and defensively.
  /// Maps the auto-incrementing SERIAL `contract_number` sequence.
  factory ContractModel.fromJson(Map<String, dynamic> json) {
    final enrollmentRaw = json['enrollments'];
    Map<String, dynamic>? enrollmentJson;
    if (enrollmentRaw is Map<String, dynamic>) {
      enrollmentJson = enrollmentRaw;
    } else if (enrollmentRaw is List && enrollmentRaw.isNotEmpty) {
      enrollmentJson = enrollmentRaw.first as Map<String, dynamic>?;
    }

    final rawDetails = json['details'] ?? json['contract_details'];
    Map<String, dynamic>? detailsJson;
    if (rawDetails is Map<String, dynamic>) {
      detailsJson = rawDetails;
    }

    return ContractModel(
      id: json['id'] as String? ?? '',
      enrollmentId: json['enrollment_id'] as String? ?? '',
      contractNumber: json['contract_number'] as int? ?? 0,
      pdfUrl: normalizeUrl(json['pdf_url'] as String?),
      signedPdfUrl: normalizeUrl(json['signed_pdf_url'] as String?),
      signedDate: json['signed_date'] != null
          ? DateTime.tryParse(json['signed_date'] as String)
          : null,
      status: json['status'] as String? ?? 'Draft',
      mentorSignatureUrl: normalizeUrl(json['mentor_signature_url'] as String?),
      clientSignatureUrl: normalizeUrl(json['client_signature_url'] as String?),
      clientSignedDate: json['client_signed_date'] != null
          ? DateTime.tryParse(json['client_signed_date'] as String)
          : null,
      priceRon: (json['price_ron'] as num?)?.toDouble() ??
          (json['total_price'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      details: detailsJson,
      enrollment: enrollmentJson != null
          ? EnrollmentModel.fromJson(enrollmentJson)
          : null,
    );
  }

  /// Converts the model to a JSON map suitable for PostgreSQL insertion.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enrollment_id': enrollmentId,
      'contract_number': contractNumber,
      'pdf_url': pdfUrl,
      'signed_pdf_url': signedPdfUrl,
      if (signedDate != null) 'signed_date': signedDate?.toIso8601String(),
      'status': status,
      if (mentorSignatureUrl != null)
        'mentor_signature_url': mentorSignatureUrl,
      if (clientSignatureUrl != null)
        'client_signature_url': clientSignatureUrl,
      if (clientSignedDate != null)
        'client_signed_date': clientSignedDate?.toIso8601String(),
      if (priceRon != null) 'price_ron': priceRon,
      if (details != null) 'details': details,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (enrollment != null) 'enrollments': enrollment?.toJson(),
    };
  }

  void printMigration() {
    print(
        'ALTER TABLE contracts\n      ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT \'Draft\',\n      ADD COLUMN IF NOT EXISTS mentor_signature_url TEXT,\n      ADD COLUMN IF NOT EXISTS client_signature_url TEXT,\n      ADD COLUMN IF NOT EXISTS client_signed_date TIMESTAMP WITH TIME ZONE,\n      ADD COLUMN IF NOT EXISTS price_ron NUMERIC,\n      ADD COLUMN IF NOT EXISTS details JSONB,\n      ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE;');
  }
}
