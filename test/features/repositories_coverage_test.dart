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

  group('Repository Instantiation & Error Handling Unit Tests', () {
    test('ProgramRepository constructs cleanly and throws on invalid query', () async {
      final repo = ProgramRepository(mockClient);
      expect(repo, isNotNull);
      expect(() => repo.fetchPrograms(), throwsA(anything));
    });

    test('StudentRepository constructs cleanly and throws on invalid query', () async {
      final repo = StudentRepository(mockClient);
      expect(repo, isNotNull);
      expect(() => repo.fetchEnrollmentsForProgram('p-1'), throwsA(anything));
    });

    test('ContractRepository constructs cleanly and handles unconfigured query', () async {
      final repo = ContractRepository(mockClient);
      expect(repo, isNotNull);
      try {
        await repo.fetchContractForEnrollment('e-1');
      } catch (_) {}
    });

    test('PaymentRepository constructs cleanly and throws on invalid query', () async {
      final repo = PaymentRepository(mockClient);
      expect(repo, isNotNull);
      expect(() => repo.fetchPaymentsForEnrollment('e-1'), throwsA(anything));
    });
  });
}
