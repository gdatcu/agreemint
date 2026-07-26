import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agreemint/features/programs/models/program_model.dart';
import 'package:agreemint/features/programs/repositories/program_repository.dart';
import 'package:agreemint/features/programs/controllers/program_controller.dart';
import 'package:agreemint/features/payments/models/payment_model.dart';
import 'package:agreemint/features/payments/repositories/payment_repository.dart';
import 'package:agreemint/features/payments/controllers/payment_controller.dart';
import 'package:agreemint/features/contracts/models/contract_model.dart';
import 'package:agreemint/features/contracts/repositories/contract_repository.dart';
import 'package:agreemint/features/contracts/controllers/contract_controller.dart';

class MockProgramRepository extends Mock implements ProgramRepository {}
class MockPaymentRepository extends Mock implements PaymentRepository {}
class MockContractRepository extends Mock implements ContractRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late MockProgramRepository mockProgramRepo;
  late MockPaymentRepository mockPaymentRepo;
  late MockContractRepository mockContractRepo;

  setUp(() {
    mockProgramRepo = MockProgramRepository();
    mockPaymentRepo = MockPaymentRepository();
    mockContractRepo = MockContractRepository();
  });

  group('ProgramController Unit Tests 100% Coverage', () {
    test('build fetches list of programs', () async {
      final mockPrograms = [
        const ProgramModel(id: 'p1', name: 'Program 1', totalPrice: 1000),
      ];

      when(() => mockProgramRepo.fetchPrograms())
          .thenAnswer((_) async => mockPrograms);

      final container = ProviderContainer(
        overrides: [
          programRepositoryProvider.overrideWithValue(mockProgramRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(programControllerProvider.future);
      expect(result, mockPrograms);
      verify(() => mockProgramRepo.fetchPrograms()).called(1);
    });

    test('addProgram, updateProgram, deleteProgram call repository methods', () async {
      when(() => mockProgramRepo.fetchPrograms())
          .thenAnswer((_) async => []);
      when(() => mockProgramRepo.createProgram(
            name: 'New Prog',
            description: 'Desc',
            totalPrice: 1200.0,
            currency: 'EUR',
          )).thenAnswer((_) async => const ProgramModel(id: 'p2', name: 'New Prog', totalPrice: 1200));

      when(() => mockProgramRepo.updateProgram(
            id: 'p2',
            name: 'Updated Prog',
            description: 'Desc 2',
            totalPrice: 1500.0,
            currency: 'RON',
          )).thenAnswer((_) async => const ProgramModel(id: 'p2', name: 'Updated Prog', totalPrice: 1500));

      when(() => mockProgramRepo.deleteProgram('p2')).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          programRepositoryProvider.overrideWithValue(mockProgramRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(programControllerProvider.future);
      final notifier = container.read(programControllerProvider.notifier);

      await notifier.addProgram(
        name: 'New Prog',
        description: 'Desc',
        totalPrice: 1200.0,
        currency: 'EUR',
      );

      await notifier.updateProgram(
        id: 'p2',
        name: 'Updated Prog',
        description: 'Desc 2',
        totalPrice: 1500.0,
        currency: 'RON',
      );

      await notifier.deleteProgram('p2');

      verify(() => mockProgramRepo.createProgram(
            name: 'New Prog',
            description: 'Desc',
            totalPrice: 1200.0,
            currency: 'EUR',
          )).called(1);

      verify(() => mockProgramRepo.updateProgram(
            id: 'p2',
            name: 'Updated Prog',
            description: 'Desc 2',
            totalPrice: 1500.0,
            currency: 'RON',
          )).called(1);

      verify(() => mockProgramRepo.deleteProgram('p2')).called(1);
    });
  });

  group('EnrollmentPaymentsController & GlobalPendingPaymentsController Unit Tests 100% Coverage', () {
    const enrollmentId = 'enr-999';

    test('GlobalPendingPaymentsController build fetches global pending payments', () async {
      final List<PaymentModel> mockGlobalPayments = [
        PaymentModel(
          id: 'pay-global-1',
          enrollmentId: 'enr-global',
          amountDue: 300,
          amountPaid: 0,
          dueDate: DateTime.now(),
          status: 'Pending',
        ),
      ];

      when(() => mockPaymentRepo.fetchGlobalPendingPayments())
          .thenAnswer((_) async => mockGlobalPayments);

      final container = ProviderContainer(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(mockPaymentRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(globalPendingPaymentsControllerProvider.future);
      expect(result, mockGlobalPayments);
      verify(() => mockPaymentRepo.fetchGlobalPendingPayments()).called(1);
    });

    test('build, generatePlan, logPayment, and deleteInstallment execute cleanly', () async {
      final mockPayments = [
        PaymentModel(
          id: 'pay-1',
          enrollmentId: enrollmentId,
          amountDue: 500,
          amountPaid: 500,
          dueDate: DateTime.now(),
          status: 'Paid',
        ),
      ];

      when(() => mockPaymentRepo.fetchPaymentsForEnrollment(enrollmentId))
          .thenAnswer((_) async => mockPayments);

      when(() => mockPaymentRepo.fetchGlobalPendingPayments())
          .thenAnswer((_) async => []);

      when(() => mockPaymentRepo.createPaymentPlan(
            enrollmentId: enrollmentId,
            totalAmount: 1000,
            numberOfInstallments: 2,
          )).thenAnswer((_) async {});

      when(() => mockPaymentRepo.recordPayment(
            paymentId: 'pay-1',
            amountPaid: 500,
            status: 'Paid',
            paymentMethod: 'Bank Transfer',
          )).thenAnswer((_) async {});

      when(() => mockPaymentRepo.deleteInstallment('pay-1'))
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(mockPaymentRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(enrollmentPaymentsControllerProvider(enrollmentId).future);
      expect(result, mockPayments);

      final notifier = container
          .read(enrollmentPaymentsControllerProvider(enrollmentId).notifier);

      await notifier.generatePlan(totalAmount: 1000, numberOfInstallments: 2);
      await notifier.logPayment(
        paymentId: 'pay-1',
        amountPaid: 500,
        status: 'Paid',
        paymentMethod: 'Bank Transfer',
      );
      await notifier.deleteInstallment('pay-1');

      verify(() => mockPaymentRepo.createPaymentPlan(
            enrollmentId: enrollmentId,
            totalAmount: 1000,
            numberOfInstallments: 2,
          )).called(1);

      verify(() => mockPaymentRepo.recordPayment(
            paymentId: 'pay-1',
            amountPaid: 500,
            status: 'Paid',
            paymentMethod: 'Bank Transfer',
          )).called(1);

      verify(() => mockPaymentRepo.deleteInstallment('pay-1')).called(1);
    });
  });

  group('EnrollmentContractController Unit Tests 100% Coverage', () {
    const enrollmentId = 'enr-777';

    test('build fetches contract for enrollment', () async {
      const mockContract = ContractModel(
        id: 'cnt-777',
        enrollmentId: enrollmentId,
        contractNumber: 777,
        status: 'Draft',
      );

      when(() => mockContractRepo.fetchContractForEnrollment(enrollmentId))
          .thenAnswer((_) async => mockContract);

      final container = ProviderContainer(
        overrides: [
          contractRepositoryProvider.overrideWithValue(mockContractRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(enrollmentContractControllerProvider(enrollmentId).future);
      expect(result, mockContract);
      verify(() => mockContractRepo.fetchContractForEnrollment(enrollmentId))
          .called(1);
    });

    test('issueContract generates PDF, uploads, and updates state', () async {
      const mockPlaceholder = ContractModel(
        id: 'cnt-placeholder',
        enrollmentId: enrollmentId,
        contractNumber: 101,
        status: 'Draft',
      );

      const mockFinalContract = ContractModel(
        id: 'cnt-placeholder',
        enrollmentId: enrollmentId,
        contractNumber: 101,
        status: 'PendingClientSignature',
      );

      when(() => mockContractRepo.fetchContractForEnrollment(enrollmentId))
          .thenAnswer((_) async => null);

      when(() => mockContractRepo.createContractPlaceholder(
            enrollmentId: enrollmentId,
            customContractNumber: null,
            updateSequenceBase: true,
          )).thenAnswer((_) async => mockPlaceholder);

      when(() => mockContractRepo.uploadMentorSignature(
            contractId: 'cnt-placeholder',
            enrollmentId: enrollmentId,
            signatureBytes: any(named: 'signatureBytes'),
          )).thenAnswer((_) async => 'https://storage/mentor.png');

      when(() => mockContractRepo.updateContractPdf(
            contractId: 'cnt-placeholder',
            enrollmentId: enrollmentId,
            pdfBytes: any(named: 'pdfBytes'),
          )).thenAnswer((_) async => mockFinalContract);

      when(() => mockContractRepo.updateStatus(
            contractId: 'cnt-placeholder',
            status: 'PendingClientSignature',
            mentorSignatureUrl: 'https://storage/mentor.png',
            priceRon: 5000.0,
          )).thenAnswer((_) async => mockFinalContract);

      final container = ProviderContainer(
        overrides: [
          contractRepositoryProvider.overrideWithValue(mockContractRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(enrollmentContractControllerProvider(enrollmentId).future);
      final notifier = container.read(enrollmentContractControllerProvider(enrollmentId).notifier);

      final dummySig = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82
      ]);

      await notifier.issueContract(
        studentName: 'Ion Popescu',
        adresaCursant: 'Bucuresti',
        cnpCursant: '1900101123456',
        serieNrCi: 'RR123456',
        eliberatorCi: 'SPCLEP',
        dataEliberariiCi: '2020-01-01',
        emailCursant: 'ion@example.com',
        telefonCursant: '+40712345678',
        programName: 'Flutter Mentorship',
        editionName: 'Editia I',
        durataOre: 40,
        nrSesiuni: 20,
        dataIncepere: '2026-08-01',
        frecventa: 'Saptamanal',
        priceRon: 5000.0,
        priceLitere: 'Cinci mii',
        modalitatePlata: 'Integral',
        prestatorNume: 'QualiAdept SRL',
        prestatorSediu: 'Bucuresti',
        prestatorRegCom: 'J40/123/2025',
        prestatorCif: 'RO123456',
        prestatorIban: 'RO98AAAA123456',
        prestatorBanca: 'BT',
        signatureBytes: dummySig,
      );

      verify(() => mockContractRepo.createContractPlaceholder(
            enrollmentId: enrollmentId,
            customContractNumber: null,
            updateSequenceBase: true,
          )).called(1);

      verify(() => mockContractRepo.updateStatus(
            contractId: 'cnt-placeholder',
            status: 'PendingClientSignature',
            mentorSignatureUrl: 'https://storage/mentor.png',
            priceRon: 5000.0,
          )).called(1);
    });
  });
}
