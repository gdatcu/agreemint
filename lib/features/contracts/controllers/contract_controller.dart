import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/contract_model.dart';
import '../repositories/contract_repository.dart';
import '../services/pdf_generator_service.dart';

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
    String? technologiesCurriculum,
    String? beneficiaryEntity,
    String? serviceDescription,
    String? paymentTerm,
    String? refundDeadline,
    required Uint8List signatureBytes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(contractRepositoryProvider);

      // 1. Create database row placeholder to get contract number
      final placeholder = await repository.createContractPlaceholder(
        enrollmentId: enrollmentId,
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

      // 5. Set contract status to PendingClient and update mentor signature url
      final finalContract = await repository.updateStatus(
        contractId: placeholder.id,
        status: 'PendingClient',
        mentorSignatureUrl: mentorSigUrl,
      );

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

      final pdfBytes = await _pdfService.generateContractPdf(
        contractNumber: contract.contractNumber.toString(),
        date: contract.signedDate ?? DateTime.now(),
        studentName: '',
        adresaCursant: '',
        cnpCursant: '',
        serieNrCi: '',
        eliberatorCi: '',
        dataEliberariiCi: '',
        emailCursant: '',
        telefonCursant: '',
        programName: '',
        editionName: '',
        durataOre: 0,
        nrSesiuni: 0,
        dataIncepere: '',
        frecventa: '',
        priceRon: 0.0,
        priceLitere: '',
        modalitatePlata: '',
        prestatorNume: '',
        prestatorSediu: '',
        prestatorRegCom: '',
        prestatorCif: '',
        prestatorIban: '',
        prestatorBanca: '',
        mentorSignatureBytes: Uint8List(0),
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

      return finalContract;
    });
  }
}
