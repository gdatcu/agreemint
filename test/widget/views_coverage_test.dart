import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:agreemint/core/constants.dart';
import 'package:agreemint/core/services/app_update_service.dart';
import 'package:agreemint/features/programs/models/program_model.dart';
import 'package:agreemint/features/students/models/student_model.dart';
import 'package:agreemint/features/students/models/enrollment_model.dart';
import 'package:agreemint/features/contracts/models/contract_model.dart';
import 'package:agreemint/features/payments/models/payment_model.dart';
import 'package:agreemint/features/payments/controllers/payment_controller.dart';
import 'package:agreemint/features/contracts/controllers/contract_controller.dart';
import 'package:agreemint/features/contracts/views/contract_signing_view.dart';
import 'package:agreemint/features/contracts/views/client_web_signature_view.dart';
import 'package:agreemint/features/payments/views/payment_tracker_view.dart';
import 'package:agreemint/features/contracts/repositories/contract_repository.dart';

class MockContractRepository extends Mock implements ContractRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testProgram = ProgramModel(
    id: 'prog-1',
    name: 'Flutter Mastery',
    totalPrice: 1000,
    currency: 'EUR',
  );

  final testStudent = StudentModel(
    id: 'stud-1',
    name: 'Ion Popescu',
    email: 'ion@example.com',
    phone: '+40712345678',
  );

  final testEnrollment = EnrollmentModel(
    id: 'enr-1',
    programId: 'prog-1',
    studentId: 'stud-1',
    student: testStudent,
    program: testProgram,
  );

  group('AppConstants Unit Tests', () {
    test('AppConstants getters return valid fallback values', () {
      expect(AppConstants.supabaseUrl, isNotEmpty);
      expect(AppConstants.supabaseAnonKey, isNotEmpty);
      expect(AppConstants.clientPortalBaseUrl, contains('https://agreemint.qualiadept.eu/'));
    });
  });

  group('UpdateCheckBanner Widget Tests', () {
    testWidgets('UpdateCheckBanner renders cleanly without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UpdateCheckBanner(),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(UpdateCheckBanner), findsOneWidget);
    });
  });

  group('PaymentTrackerView Widget Tests', () {
    testWidgets('Renders payment tracker view with enrollment details', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enrollmentPaymentsControllerProvider('enr-1')
                .overrideWith(() => MockPaymentsController([])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PaymentTrackerView(enrollment: testEnrollment),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(PaymentTrackerView), findsOneWidget);
      expect(find.textContaining('Ion Popescu'), findsOneWidget);
    });
  });

  group('ContractSigningView Widget Tests', () {
    testWidgets('Renders contract signing view form', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enrollmentContractControllerProvider('enr-1')
                .overrideWith(() => MockContractController(null)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ContractSigningView(enrollment: testEnrollment),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(ContractSigningView), findsOneWidget);
    });
  });

  group('ClientWebSignatureView Widget Tests', () {
    testWidgets('Renders client web signature view loading/error state', (WidgetTester tester) async {
      final mockRepo = MockContractRepository();
      when(() => mockRepo.fetchContractById('cnt-1')).thenAnswer((_) async => null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contractRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ClientWebSignatureView(contractId: 'cnt-1'),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ClientWebSignatureView), findsOneWidget);
    });
  });
}

class MockPaymentsController extends EnrollmentPaymentsController {
  final List<PaymentModel> initial;
  MockPaymentsController(this.initial);

  @override
  Future<List<PaymentModel>> build(String enrollmentId) async {
    return initial;
  }
}

class MockContractController extends EnrollmentContractController {
  final ContractModel? initial;
  MockContractController(this.initial);

  @override
  Future<ContractModel?> build(String enrollmentId) async {
    return initial;
  }
}
