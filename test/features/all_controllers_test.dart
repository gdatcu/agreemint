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
  late MockProgramRepository mockProgramRepo;
  late MockPaymentRepository mockPaymentRepo;
  late MockContractRepository mockContractRepo;

  setUp(() {
    mockProgramRepo = MockProgramRepository();
    mockPaymentRepo = MockPaymentRepository();
    mockContractRepo = MockContractRepository();
  });

  group('ProgramController Unit Tests', () {
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

    test('addProgram calls repository and refreshes state', () async {
      when(() => mockProgramRepo.fetchPrograms())
          .thenAnswer((_) async => []);
      when(() => mockProgramRepo.createProgram(
            name: 'New Prog',
            description: 'Desc',
            totalPrice: 1200.0,
            currency: 'EUR',
          )).thenAnswer((_) async => const ProgramModel(id: 'p2', name: 'New Prog', totalPrice: 1200));

      final container = ProviderContainer(
        overrides: [
          programRepositoryProvider.overrideWithValue(mockProgramRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(programControllerProvider.future);
      await container.read(programControllerProvider.notifier).addProgram(
            name: 'New Prog',
            description: 'Desc',
            totalPrice: 1200.0,
            currency: 'EUR',
          );

      verify(() => mockProgramRepo.createProgram(
            name: 'New Prog',
            description: 'Desc',
            totalPrice: 1200.0,
            currency: 'EUR',
          )).called(1);
    });
  });

  group('EnrollmentPaymentsController Unit Tests', () {
    const enrollmentId = 'enr-999';

    test('build fetches payment installments', () async {
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

      final container = ProviderContainer(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(mockPaymentRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(enrollmentPaymentsControllerProvider(enrollmentId).future);
      expect(result, mockPayments);
      verify(() => mockPaymentRepo.fetchPaymentsForEnrollment(enrollmentId))
          .called(1);
    });
  });

  group('EnrollmentContractController Unit Tests', () {
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
  });
}
