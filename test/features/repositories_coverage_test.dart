import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agreemint/features/programs/repositories/program_repository.dart';
import 'package:agreemint/features/students/repositories/student_repository.dart';
import 'package:agreemint/features/contracts/repositories/contract_repository.dart';
import 'package:agreemint/features/payments/repositories/payment_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSupabaseClient mockClient;

  setUp(() {
    mockClient = MockSupabaseClient();
  });

  group('Repository Error Handling & Edge Case Coverage Tests', () {
    test('ProgramRepository methods handle exceptions gracefully', () async {
      final repo = ProgramRepository(mockClient);

      expect(() => repo.fetchPrograms(), throwsA(anything));
      expect(() => repo.fetchProgramById('p-1'), throwsA(anything));
      expect(() => repo.createProgram(name: 'P', totalPrice: 100), throwsA(anything));
      expect(() => repo.updateProgram(id: '1', name: 'P', totalPrice: 100), throwsA(anything));
      expect(() => repo.deleteProgram('p-1'), throwsA(anything));
    });

    test('StudentRepository methods handle exceptions gracefully', () async {
      final repo = StudentRepository(mockClient);

      expect(() => repo.fetchEnrollmentsForProgram('p-1'), throwsA(anything));
      expect(() => repo.enrollStudent(programId: 'p1', name: 'N', email: 'e@test.com'), throwsA(anything));
      expect(() => repo.deleteEnrollment(enrollmentId: 'e1', studentId: 's1'), throwsA(anything));
    });

    test('ContractRepository methods handle exceptions and edge cases', () async {
      final repo = ContractRepository(mockClient);

      expect(await repo.fetchContractById(''), isNull);
      expect(await repo.fetchContractForEnrollment(''), isNull);
      expect(await repo.fetchContractById('invalid-id'), isNull);
      expect(await repo.fetchContractForEnrollment('invalid-id'), isNull);
    });

    test('PaymentRepository methods handle exceptions gracefully', () async {
      final repo = PaymentRepository(mockClient);

      expect(() => repo.fetchPaymentsForEnrollment('e-1'), throwsA(anything));
      expect(() => repo.fetchGlobalPendingPayments(), throwsA(anything));
      expect(() => repo.createPaymentPlan(enrollmentId: 'e1', totalAmount: 100, numberOfInstallments: 0), throwsA(anything));
      expect(() => repo.recordPayment(paymentId: 'p1', amountPaid: 100, status: 'Paid', paymentMethod: 'Cash'), throwsA(anything));
      expect(() => repo.addInstallment(enrollmentId: 'e1', amountDue: 100, dueDate: DateTime.now()), throwsA(anything));
    });
  });
}
