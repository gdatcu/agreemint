class ProgramModel {
  final String id;
  final String name;
  final String? description;
  final double totalPrice;
  final String currency;
  final DateTime? createdAt;
  final bool hasSignedContractsOrPayments;

  const ProgramModel({
    required this.id,
    required this.name,
    this.description,
    required this.totalPrice,
    this.currency = 'RON',
    this.createdAt,
    this.hasSignedContractsOrPayments = false,
  });

  bool get canBeDeleted => !hasSignedContractsOrPayments;

  /// Factory constructor to parse PostgreSQL json results cleanly and defensively.
  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    bool hasSignedContractsOrPayments = false;
    final enrollmentsRaw = json['enrollments'];

    if (enrollmentsRaw is List) {
      for (final enr in enrollmentsRaw) {
        if (enr is Map<String, dynamic>) {
          // Check contracts
          final contractsRaw = enr['contracts'];
          List contractsList = [];
          if (contractsRaw is List) {
            contractsList = contractsRaw;
          } else if (contractsRaw is Map<String, dynamic>) {
            contractsList = [contractsRaw];
          }
          for (final c in contractsList) {
            if (c is Map<String, dynamic>) {
              final status = c['status'] as String?;
              final clientSig = c['client_signature_url'] as String?;
              final signedDate = c['signed_date'];
              if (status == 'FullySigned' ||
                  (clientSig != null && clientSig.isNotEmpty) ||
                  signedDate != null) {
                hasSignedContractsOrPayments = true;
                break;
              }
            }
          }

          // Check payments
          final paymentsRaw = enr['payments'];
          List paymentsList = [];
          if (paymentsRaw is List) {
            paymentsList = paymentsRaw;
          } else if (paymentsRaw is Map<String, dynamic>) {
            paymentsList = [paymentsRaw];
          }
          for (final p in paymentsList) {
            if (p is Map<String, dynamic>) {
              final amountPaid = (p['amount_paid'] as num?)?.toDouble() ?? 0.0;
              final status = p['status'] as String?;
              if (amountPaid > 0 || status == 'Paid' || status == 'Partial') {
                hasSignedContractsOrPayments = true;
                break;
              }
            }
          }
        }
      }
    }

    return ProgramModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'RON',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      hasSignedContractsOrPayments: hasSignedContractsOrPayments,
    );
  }

  /// Converts the model to a JSON map suitable for PostgreSQL insertion.
  Map<String, dynamic> toJson() {
    final created = createdAt;
    return {
      'id': id,
      'name': name,
      'description': description,
      'total_price': totalPrice,
      'currency': currency,
      if (created != null) 'created_at': created.toIso8601String(),
    };
  }
}

