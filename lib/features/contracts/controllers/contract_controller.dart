import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/contract_model.dart';
import '../repositories/contract_repository.dart';
import '../services/pdf_generator_service.dart';
import '../../payments/repositories/payment_repository.dart';
import '../../payments/controllers/payment_controller.dart';
import '../../analytics/controllers/analytics_controller.dart';
import '../../students/controllers/student_controller.dart';

part 'contract_controller.g.dart';

@riverpod
class EnrollmentContractController extends _$EnrollmentContractController {
  late final PdfGeneratorService _pdfService;

  @override
  Future<ContractModel?> build(String enrollmentId) async {
    _pdfService = PdfGeneratorService();
    return ref
        .watch(contractRepositoryProvider)
        .fetchContractForEnrollment(enrollmentId);
  }

  /// Generates the PDF, uploads it, inserts a DB row, and updates the local state.
  Future<void> issueContract({
    required String studentName,
    required String adresaCursant,
    required String cnpCursant,
    required String serieNrCi,
    required String eliberatorCi,
    required String dataEliberariiCi,
    required String emailCursant,
    required String telefonCursant,
    required String programName,
    required String editionName,
    required int durataOre,
    required int nrSesiuni,
    required String dataIncepere,
    required String frecventa,
    required double priceRon,
    required String priceLitere,
    required String modalitatePlata,
    required String prestatorNume,
    required String prestatorSediu,
    required String prestatorRegCom,
    required String prestatorCif,
    required String prestatorIban,
    required String prestatorBanca,
    String prestatorEuid = 'ROONRC.F2026003426005',
    String clientType = 'PF',
    String? cuiCursant,
    String? regComCursant,
    String? billingAddressCursant,
    String? technologiesCurriculum,
    String? beneficiaryEntity,
    String? serviceDescription,
    String? paymentTerm,
    String? refundDeadline,
    int? customContractNumber,
    bool updateSequenceBase = true,
    required Uint8List signatureBytes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(contractRepositoryProvider);

      // 1. Create database row placeholder to get or set contract number
      final placeholder = await repository.createContractPlaceholder(
        enrollmentId: enrollmentId,
        customContractNumber: customContractNumber,
        updateSequenceBase: updateSequenceBase,
      );

      // 2. Generate PDF with mentor signature and contract details
      final pdfBytes = await _pdfService.generateContractPdf(
        contractNumber: placeholder.contractNumber.toString(),
        date: DateTime.now(),
        studentName: studentName,
        adresaCursant: adresaCursant,
        cnpCursant: cnpCursant,
        serieNrCi: serieNrCi,
        eliberatorCi: eliberatorCi,
        dataEliberariiCi: dataEliberariiCi,
        emailCursant: emailCursant,
        telefonCursant: telefonCursant,
        programName: programName,
        editionName: editionName,
        durataOre: durataOre,
        nrSesiuni: nrSesiuni,
        dataIncepere: dataIncepere,
        frecventa: frecventa,
        priceRon: priceRon,
        priceLitere: priceLitere,
        modalitatePlata: modalitatePlata,
        prestatorNume: prestatorNume,
        prestatorSediu: prestatorSediu,
        prestatorRegCom: prestatorRegCom,
        prestatorCif: prestatorCif,
        prestatorEuid: prestatorEuid,
        prestatorIban: prestatorIban,
        prestatorBanca: prestatorBanca,
        clientType: clientType,
        cuiCursant: cuiCursant,
        regComCursant: regComCursant,
        billingAddressCursant: billingAddressCursant,
        technologiesCurriculum: technologiesCurriculum,
        beneficiaryEntity: beneficiaryEntity,
        serviceDescription: serviceDescription,
        paymentTerm: paymentTerm,
        refundDeadline: refundDeadline,
        mentorSignatureBytes: signatureBytes,
        clientSignatureBytes: Uint8List(0),
      );

      // 3. Upload mentor signature image and obtain its URL
      final mentorSigUrl = await repository.uploadMentorSignature(
        contractId: placeholder.id,
        enrollmentId: enrollmentId,
        signatureBytes: signatureBytes,
      );

      // 4. Upload PDF and update contract record
      await repository.updateContractPdf(
        contractId: placeholder.id,
        enrollmentId: enrollmentId,
        pdfBytes: pdfBytes,
      );

      // 5. Build contract details map snapshot to preserve contract terms
      final contractDetails = {
        'contract_number': placeholder.contractNumber,
        'student_name': studentName,
        'adresa_cursant': adresaCursant,
        'cnp_cursant': cnpCursant,
        'serie_nr_ci': serieNrCi,
        'eliberator_ci': eliberatorCi,
        'data_eliberarii_ci': dataEliberariiCi,
        'email_cursant': emailCursant,
        'telefon_cursant': telefonCursant,
        'client_type': clientType,
        if (cuiCursant != null) 'cui_cursant': cuiCursant,
        if (regComCursant != null) 'reg_com_cursant': regComCursant,
        if (billingAddressCursant != null) 'billing_address_cursant': billingAddressCursant,
        'program_name': programName,
        'edition_name': editionName,
        'durata_ore': durataOre,
        'nr_sesiuni': nrSesiuni,
        'data_incepere': dataIncepere,
        'frecventa': frecventa,
        'price_ron': priceRon,
        'price_litere': priceLitere,
        'modalitate_plata': modalitatePlata,
        'prestator_nume': prestatorNume,
        'prestator_sediu': prestatorSediu,
        'prestator_reg_com': prestatorRegCom,
        'prestator_cif': prestatorCif,
        'prestator_euid': prestatorEuid,
        'prestator_iban': prestatorIban,
        'prestator_banca': prestatorBanca,
        if (technologiesCurriculum != null)
          'technologies_curriculum': technologiesCurriculum,
        if (beneficiaryEntity != null) 'beneficiary_entity': beneficiaryEntity,
        if (serviceDescription != null)
          'service_description': serviceDescription,
        if (paymentTerm != null) 'payment_term': paymentTerm,
        if (refundDeadline != null) 'refund_deadline': refundDeadline,
      };

      // 6. Set contract status to PendingClient, save details snapshot, and update mentor signature url
      final finalContract = await repository.updateStatus(
        contractId: placeholder.id,
        status: 'PendingClient',
        mentorSignatureUrl: mentorSigUrl,
        priceRon: priceRon,
        details: contractDetails,
      );

      ref.invalidate(programEnrollmentsControllerProvider);
      ref.invalidate(globalContractsControllerProvider);
      ref.invalidate(analyticsSummaryControllerProvider);

      return finalContract;
    });
  }

  /// Handles client signing: uploads client signature, generates final PDF with both signatures, stores it and marks contract as FullySigned.
  Future<void> signAsClient({
    required Uint8List clientSignatureBytes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(contractRepositoryProvider);

      final contract = await repository.fetchContractForEnrollment(enrollmentId);
      if (contract == null) {
        throw Exception('Contract not found for enrollment');
      }

      final clientSigUrl = await repository.uploadClientSignature(
        contractId: contract.id,
        enrollmentId: enrollmentId,
        signatureBytes: clientSignatureBytes,
      );

      final d = contract.details ?? {};
      final mentorSigBytes =
          await repository.fetchMentorSignatureBytes(enrollmentId);
      final student = contract.enrollment?.student;
      final program = contract.enrollment?.program;

      final pdfBytes = await _pdfService.generateContractPdf(
        contractNumber: (d['contract_number'] ?? contract.contractNumber).toString(),
        date: contract.signedDate ?? DateTime.now(),
        studentName: d['student_name'] as String? ?? student?.name ?? 'Beneficiar Program Mentorat',
        adresaCursant: d['adresa_cursant'] as String? ?? '',
        cnpCursant: d['cnp_cursant'] as String? ?? '',
        serieNrCi: d['serie_nr_ci'] as String? ?? '',
        eliberatorCi: d['eliberator_ci'] as String? ?? '',
        dataEliberariiCi: d['data_eliberarii_ci'] as String? ?? '',
        emailCursant: d['email_cursant'] as String? ?? student?.email ?? '',
        telefonCursant: d['telefon_cursant'] as String? ?? student?.phone ?? '',
        clientType: d['client_type'] as String? ?? student?.clientType ?? 'PF',
        cuiCursant: d['cui_cursant'] as String? ?? student?.cui,
        regComCursant: d['reg_com_cursant'] as String? ?? student?.regCom,
        billingAddressCursant: d['billing_address_cursant'] as String? ?? student?.billingAddress,
        programName: d['program_name'] as String? ?? program?.name ?? 'Program Mentorat Tehnic',
        editionName: d['edition_name'] as String? ?? 'Ediția Curentă',
        durataOre: (d['durata_ore'] as num?)?.toInt() ?? 40,
        nrSesiuni: (d['nr_sesiuni'] as num?)?.toInt() ?? 20,
        dataIncepere: d['data_incepere'] as String? ?? DateTime.now().toIso8601String().split('T')[0],
        frecventa: d['frecventa'] as String? ?? '1 sesiune pe săptămână',
        priceRon: (d['price_ron'] as num?)?.toDouble() ?? contract.priceRon ?? program?.totalPrice ?? 0.0,
        priceLitere: d['price_litere'] as String? ?? '',
        modalitatePlata: d['modalitate_plata'] as String? ?? 'Conform înțelegerii',
        prestatorNume: d['prestator_nume'] as String? ?? 'DATCU GEORGE-CRISTIAN PERSOANA FIZICĂ AUTORIZATĂ',
        prestatorSediu: d['prestator_sediu'] as String? ?? 'Bucureşti Sectorul 1, Bulevardul BUCUREŞTII NOI, Nr. 136, Etaj PARTER, Ap. 5',
        prestatorRegCom: d['prestator_reg_com'] as String? ?? 'F2026003426005',
        prestatorCif: d['prestator_cif'] as String? ?? '53430793',
        prestatorEuid: d['prestator_euid'] as String? ?? 'ROONRC.F2026003426005',
        prestatorIban: d['prestator_iban'] as String? ?? 'RO54ROIN4021Q3YWTH1KTUTH',
        prestatorBanca: d['prestator_banca'] as String? ?? 'Salt Bank',
        technologiesCurriculum: d['technologies_curriculum'] as String?,
        beneficiaryEntity: d['beneficiary_entity'] as String?,
        serviceDescription: d['service_description'] as String?,
        paymentTerm: d['payment_term'] as String?,
        refundDeadline: d['refund_deadline'] as String?,
        mentorSignatureBytes: mentorSigBytes,
        clientSignatureBytes: clientSignatureBytes,
      );

      await repository.uploadSignedContractPdf(
        contractId: contract.id,
        enrollmentId: enrollmentId,
        pdfBytes: pdfBytes,
      );

      final finalContract = await repository.updateStatus(
        contractId: contract.id,
        status: 'FullySigned',
        clientSignatureUrl: clientSigUrl,
        clientSignedDate: DateTime.now(),
      );

      ref.invalidate(programEnrollmentsControllerProvider);
      ref.invalidate(globalContractsControllerProvider);
      ref.invalidate(analyticsSummaryControllerProvider);

      return finalContract;
    });
  }

  /// Manually uploads a signed PDF contract (e.g. from file picker).
  Future<void> uploadSignedContract({
    required Uint8List pdfBytes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(contractRepositoryProvider);

      var contract = await repository.fetchContractForEnrollment(enrollmentId);
      contract ??= await repository.createContractPlaceholder(
        enrollmentId: enrollmentId,
      );

      await repository.uploadSignedContractPdf(
        contractId: contract.id,
        enrollmentId: enrollmentId,
        pdfBytes: pdfBytes,
      );

      final finalContract = await repository.updateStatus(
        contractId: contract.id,
        status: 'FullySigned',
      );

      ref.invalidate(programEnrollmentsControllerProvider);
      ref.invalidate(globalContractsControllerProvider);
      ref.invalidate(analyticsSummaryControllerProvider);

      return finalContract;
    });
  }

  /// Processes client retirement / cancellation and refund:
  /// Updates contract status to 'Refunded', saves refund details in contract.details snapshot,
  /// updates associated payments to 'Refunded', and invalidates analytics summary.
  Future<void> cancelAndRefundContract({
    required String refundReason,
    required double refundAmount,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final contractRepo = ref.read(contractRepositoryProvider);
      final paymentRepo = ref.read(paymentRepositoryProvider);

      var contract = await contractRepo.fetchContractForEnrollment(enrollmentId);
      if (contract == null) {
        throw Exception('Contract not found for enrollment');
      }

      final existingDetails = Map<String, dynamic>.from(contract.details ?? {});
      existingDetails['refund_reason'] = refundReason;
      existingDetails['refund_amount'] = refundAmount;
      existingDetails['refund_date'] = DateTime.now().toIso8601String();

      // 1. Update contract status to 'Refunded' and store refund details snapshot
      final updatedContract = await contractRepo.updateStatus(
        contractId: contract.id,
        status: 'Refunded',
        details: existingDetails,
      );

      // 2. Mark payments as refunded
      await paymentRepo.markPaymentsAsRefunded(enrollmentId);

      // 3. Invalidate analytics summary provider, enrollment payments provider, program enrollments provider, and pending dashboard to refresh UI
      ref.invalidate(analyticsSummaryControllerProvider);
      ref.invalidate(enrollmentPaymentsControllerProvider(enrollmentId));
      ref.invalidate(programEnrollmentsControllerProvider);
      ref.invalidate(globalContractsControllerProvider);
      ref.invalidate(globalPendingPaymentsControllerProvider);
      return updatedContract;
    });
  }
}

@riverpod
class GlobalContractsController extends _$GlobalContractsController {
  @override
  Future<List<ContractModel>> build() async {
    return ref.watch(contractRepositoryProvider).fetchAllContracts();
  }
}
