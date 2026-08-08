import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/features/programs/models/program_model.dart';
import 'package:agreemint/features/students/models/student_model.dart';
import 'package:agreemint/features/students/models/enrollment_model.dart';
import 'package:agreemint/features/contracts/models/contract_model.dart';

void main() {
  group('ProgramModel Unit Tests', () {
    test('fromJson correctly parses ProgramModel data', () {
      final json = {
        'id': 'prog-123',
        'name': 'Flutter Mastery',
        'description': 'Advanced Mentorship Program',
        'total_price': 1500.0,
        'currency': 'EUR',
        'created_at': '2026-07-01T10:00:00Z',
      };

      final program = ProgramModel.fromJson(json);

      expect(program.id, 'prog-123');
      expect(program.name, 'Flutter Mastery');
      expect(program.description, 'Advanced Mentorship Program');
      expect(program.totalPrice, 1500.0);
      expect(program.currency, 'EUR');
      expect(program.createdAt, DateTime.parse('2026-07-01T10:00:00Z'));
    });

    test('toJson produces expected Map representation', () {
      final program = ProgramModel(
        id: 'prog-456',
        name: 'React Cohort',
        totalPrice: 2000.0,
        currency: 'RON',
      );

      final json = program.toJson();

      expect(json['id'], 'prog-456');
      expect(json['name'], 'React Cohort');
      expect(json['total_price'], 2000.0);
      expect(json['currency'], 'RON');
    });
  });

  group('EnrollmentModel & canBeDeleted Unit Tests', () {
    test('canBeDeleted returns true when no contract exists', () {
      const enrollment = EnrollmentModel(
        id: 'enr-1',
        programId: 'prog-1',
        studentId: 'stud-1',
        contract: null,
      );

      expect(enrollment.isSignedByBeneficiary, false);
      expect(enrollment.canBeDeleted, true);
    });

    test('canBeDeleted returns true when contract is NOT signed', () {
      final contract = ContractModel(
        id: 'cnt-1',
        enrollmentId: 'enr-1',
        contractNumber: 1,
        status: 'Draft',
        clientSignatureUrl: null,
        clientSignedDate: null,
      );

      final enrollment = EnrollmentModel(
        id: 'enr-1',
        programId: 'prog-1',
        studentId: 'stud-1',
        contract: contract,
      );

      expect(enrollment.isSignedByBeneficiary, false);
      expect(enrollment.canBeDeleted, true);
    });

    test('canBeDeleted returns false when contract is signed', () {
      final contract = ContractModel(
        id: 'cnt-2',
        enrollmentId: 'enr-2',
        contractNumber: 2,
        status: 'FullySigned',
        clientSignatureUrl: 'https://storage.supabase.com/sig.png',
        clientSignedDate: DateTime.now(),
      );

      final enrollment = EnrollmentModel(
        id: 'enr-2',
        programId: 'prog-1',
        studentId: 'stud-2',
        contract: contract,
      );

      expect(enrollment.isSignedByBeneficiary, true);
      expect(enrollment.canBeDeleted, false);
    });
  });

  group('StudentModel & ContractModel Serialization Tests', () {
    test('StudentModel json roundtrip with PFA fields', () {
      final json = {
        'id': 'stud-99',
        'name': 'Jane Doe PFA',
        'email': 'jane@example.com',
        'phone': '+40712345678',
        'client_type': 'PFA',
        'cui': 'RO12345678',
        'reg_com': 'F40/123/2026',
        'billing_address': 'Str. Test 10, Bucuresti',
      };

      final student = StudentModel.fromJson(json);
      expect(student.id, 'stud-99');
      expect(student.name, 'Jane Doe PFA');
      expect(student.email, 'jane@example.com');
      expect(student.phone, '+40712345678');
      expect(student.clientType, 'PFA');
      expect(student.cui, 'RO12345678');
      expect(student.regCom, 'F40/123/2026');
      expect(student.billingAddress, 'Str. Test 10, Bucuresti');

      final serialized = student.toJson();
      expect(serialized['id'], 'stud-99');
      expect(serialized['name'], 'Jane Doe PFA');
      expect(serialized['client_type'], 'PFA');
      expect(serialized['cui'], 'RO12345678');
      expect(serialized['reg_com'], 'F40/123/2026');
      expect(serialized['billing_address'], 'Str. Test 10, Bucuresti');
    });
  });
}

