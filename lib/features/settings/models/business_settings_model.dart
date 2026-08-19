import 'dart:convert';
import 'dart:typed_data';

class BusinessSettingsModel {
  final String companyName;
  final String companyAddress;
  final String regCom;
  final String cuiCif;
  final String euid;
  final String iban;
  final String bankName;
  final String beneficiaryEntity;
  final String serviceDescription;
  final String paymentTerm;
  final String refundDeadline;
  final String? mentorSignatureBase64;

  const BusinessSettingsModel({
    this.companyName = 'DATCU GEORGE-CRISTIAN PERSOANA FIZICĂ AUTORIZATĂ',
    this.companyAddress =
        'Bucureşti Sectorul 1, Bulevardul BUCUREŞTII NOI, Nr. 136, Etaj PARTER, Ap. 5',
    this.regCom = 'F2026003426005',
    this.cuiCif = '53430793',
    this.euid = 'ROONRC.F2026003426005',
    this.iban = 'RO54ROIN4021Q3YWTH1KTUTH',
    this.bankName = 'Salt Bank',
    this.beneficiaryEntity = 'QualiAdept Community',
    this.serviceDescription =
        'sesiuni live online, feedback pe cod (code review) și consultanță',
    this.paymentTerm = '3 (trei) zile calendaristice',
    this.refundDeadline = '5 (cinci) zile calendaristice',
    this.mentorSignatureBase64,
  });

  /// Helper getter returning decoded signature bytes if base64 string is present.
  Uint8List? get mentorSignatureBytes {
    if (mentorSignatureBase64 == null || mentorSignatureBase64!.isEmpty) {
      return null;
    }
    try {
      return base64Decode(mentorSignatureBase64!);
    } catch (_) {
      return null;
    }
  }

  BusinessSettingsModel copyWith({
    String? companyName,
    String? companyAddress,
    String? regCom,
    String? cuiCif,
    String? euid,
    String? iban,
    String? bankName,
    String? beneficiaryEntity,
    String? serviceDescription,
    String? paymentTerm,
    String? refundDeadline,
    String? mentorSignatureBase64,
  }) {
    return BusinessSettingsModel(
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      regCom: regCom ?? this.regCom,
      cuiCif: cuiCif ?? this.cuiCif,
      euid: euid ?? this.euid,
      iban: iban ?? this.iban,
      bankName: bankName ?? this.bankName,
      beneficiaryEntity: beneficiaryEntity ?? this.beneficiaryEntity,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      paymentTerm: paymentTerm ?? this.paymentTerm,
      refundDeadline: refundDeadline ?? this.refundDeadline,
      mentorSignatureBase64:
          mentorSignatureBase64 ?? this.mentorSignatureBase64,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'company_address': companyAddress,
      'reg_com': regCom,
      'cui_cif': cuiCif,
      'euid': euid,
      'iban': iban,
      'bank_name': bankName,
      'beneficiary_entity': beneficiaryEntity,
      'service_description': serviceDescription,
      'payment_term': paymentTerm,
      'refund_deadline': refundDeadline,
      'mentor_signature_base64': mentorSignatureBase64,
    };
  }

  factory BusinessSettingsModel.fromJson(Map<String, dynamic> json) {
    return BusinessSettingsModel(
      companyName: (json['company_name'] as String?) ??
          'DATCU GEORGE-CRISTIAN PERSOANA FIZICĂ AUTORIZATĂ',
      companyAddress: (json['company_address'] as String?) ??
          'Bucureşti Sectorul 1, Bulevardul BUCUREŞTII NOI, Nr. 136, Etaj PARTER, Ap. 5',
      regCom: (json['reg_com'] as String?) ?? 'F2026003426005',
      cuiCif: (json['cui_cif'] as String?) ?? '53430793',
      euid: (json['euid'] as String?) ?? 'ROONRC.F2026003426005',
      iban: (json['iban'] as String?) ?? 'RO54ROIN4021Q3YWTH1KTUTH',
      bankName: (json['bank_name'] as String?) ?? 'Salt Bank',
      beneficiaryEntity:
          (json['beneficiary_entity'] as String?) ?? 'QualiAdept Community',
      serviceDescription: (json['service_description'] as String?) ??
          'sesiuni live online, feedback pe cod (code review) și consultanță',
      paymentTerm:
          (json['payment_term'] as String?) ?? '3 (trei) zile calendaristice',
      refundDeadline: (json['refund_deadline'] as String?) ??
          '5 (cinci) zile calendaristice',
      mentorSignatureBase64: json['mentor_signature_base64'] as String?,
    );
  }
}
