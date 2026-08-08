import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/features/programs/models/program_model.dart';
import 'package:agreemint/features/students/models/student_model.dart';
import 'package:agreemint/features/students/models/enrollment_model.dart';
import 'package:agreemint/features/contracts/models/contract_model.dart';
import 'package:agreemint/features/payments/models/payment_model.dart';

void main() {
  group('ContractModel Complete Unit Tests', () {
    test('ContractModel.fromJson and toJson roundtrip', () {
      final json = {
        'id': 'cnt-100',
        'enrollment_id': 'enr-100',
        'contract_number': 42,
        'pdf_url': 'https://storage.com/pdf.pdf',
        'signed_pdf_url': 'https://storage.com/signed.pdf',
        'signed_date': '2026-07-01T12:00:00Z',
        'status': 'FullySigned',
        'mentor_signature_url': 'https://storage.com/mentor.png',
        'client_signature_url': 'https://storage.com/client.png',
        'client_signed_date': '2026-07-01T12:00:00Z',
        'price_ron': 4500.0,
        'created_at': '2026-07-01T10:00:00Z',
        'details': {
          'prestator_iban': 'RO54ROIN4021Q3YWTH1KTUTH',
          'durata_ore': 50,
          'modalitate_plata': 'în 2 tranșe egale',
        },
        'enrollments': {
          'id': 'enr-100',
          'program_id': 'prog-1',
          'student_id': 'stud-1',
        },
      };

      final contract = ContractModel.fromJson(json);

      expect(contract.id, 'cnt-100');
      expect(contract.enrollmentId, 'enr-100');
      expect(contract.contractNumber, 42);
      expect(contract.pdfUrl, 'https://storage.com/pdf.pdf');
      expect(contract.signedPdfUrl, 'https://storage.com/signed.pdf');
      expect(contract.signedDate, isNotNull);
      expect(contract.status, 'FullySigned');
      expect(contract.priceRon, 4500.0);
      expect(contract.details, isNotNull);
      expect(contract.details?['prestator_iban'], 'RO54ROIN4021Q3YWTH1KTUTH');
      expect(contract.details?['durata_ore'], 50);
      expect(contract.enrollment, isNotNull);
      expect(contract.enrollment?.id, 'enr-100');

      final serialized = contract.toJson();
      expect(serialized['id'], 'cnt-100');
      expect(serialized['contract_number'], 42);
      expect(serialized['status'], 'FullySigned');
      expect(serialized['price_ron'], 4500.0);
      expect(serialized['details'], isNotNull);
      expect(serialized['details']['prestator_iban'], 'RO54ROIN4021Q3YWTH1KTUTH');
    });

    test('ContractModel.fromJson with total_price fallback and null fields', () {
      final json = {
        'id': 'cnt-fallback',
        'enrollment_id': 'enr-1',
        'contract_number': 10,
        'total_price': 2500.5,
      };

      final contract = ContractModel.fromJson(json);

      expect(contract.id, 'cnt-fallback');
      expect(contract.contractNumber, 10);
      expect(contract.priceRon, 2500.5);
      expect(contract.pdfUrl, isNull);
      expect(contract.signedPdfUrl, isNull);
      expect(contract.signedDate, isNull);
      expect(contract.status, 'Draft');
    });
    test('ContractModel.normalizeUrl converts expiring signed URLs to permanent public URLs', () {
      const expiringSignedUrl =
          'https://jkbouvnzft.supabase.co/storage/v1/object/sign/contracts/signed_contract_123.pdf?token=eyJhbGciOi...';
      final normalized = ContractModel.normalizeUrl(expiringSignedUrl);

      expect(
        normalized,
        'https://jkbouvnzft.supabase.co/storage/v1/object/public/contracts/signed_contract_123.pdf',
      );

      final json = {
        'id': 'cnt-signed',
        'enrollment_id': 'enr-1',
        'signed_pdf_url': expiringSignedUrl,
      };
      final contract = ContractModel.fromJson(json);
      expect(
        contract.signedPdfUrl,
        'https://jkbouvnzft.supabase.co/storage/v1/object/public/contracts/signed_contract_123.pdf',
      );
    });
    test('ContractModel.printMigration executes without error', () {
      const contract = ContractModel(
        id: 'cnt-1',
        enrollmentId: 'enr-1',
        contractNumber: 1,
      );
      expect(() => contract.printMigration(), returnsNormally);
    });
  });

  group('StudentModel Complete 100% Coverage Unit Tests', () {
    test('StudentModel fromJson and toJson with all fields', () {
      final now = DateTime.now();
      final json = {
        'id': 'stud-full',
        'name': 'Maria Ionescu SRL',
        'email': 'maria@example.com',
        'phone': '+40722123456',
        'client_type': 'SRL',
        'cui': 'RO99887766',
        'reg_com': 'J40/999/2025',
        'billing_address': 'Bd. Unirii 1, Bucuresti',
        'created_at': now.toIso8601String(),
      };

      final student = StudentModel.fromJson(json);

      expect(student.id, 'stud-full');
      expect(student.name, 'Maria Ionescu SRL');
      expect(student.email, 'maria@example.com');
      expect(student.phone, '+40722123456');
      expect(student.clientType, 'SRL');
      expect(student.cui, 'RO99887766');
      expect(student.regCom, 'J40/999/2025');
      expect(student.billingAddress, 'Bd. Unirii 1, Bucuresti');
      expect(student.createdAt, isNotNull);

      final serialized = student.toJson();
      expect(serialized['id'], 'stud-full');
      expect(serialized['phone'], '+40722123456');
      expect(serialized['client_type'], 'SRL');
      expect(serialized['cui'], 'RO99887766');
      expect(serialized['reg_com'], 'J40/999/2025');
      expect(serialized['billing_address'], 'Bd. Unirii 1, Bucuresti');
      expect(serialized['created_at'], isNotNull);
    });

    test('StudentModel fromJson and toJson with null phone, B2B fields defaults', () {
      final json = {
        'id': 'stud-minimal',
        'name': 'Dan Radu',
        'email': 'dan@example.com',
      };

      final student = StudentModel.fromJson(json);

      expect(student.id, 'stud-minimal');
      expect(student.clientType, 'PF');
      expect(student.cui, isNull);
      expect(student.regCom, isNull);
      expect(student.billingAddress, isNull);
      expect(student.phone, isNull);
      expect(student.createdAt, isNull);

      final serialized = student.toJson();
      expect(serialized['id'], 'stud-minimal');
      expect(serialized['client_type'], 'PF');
      expect(serialized.containsKey('created_at'), false);
    });
  });


  group('EnrollmentModel Complete 100% Coverage Unit Tests', () {
    test('EnrollmentModel parses List representation for relational joins', () {
      final now = DateTime.now();
      final json = {
        'id': 'enr-list',
        'program_id': 'prog-list',
        'student_id': 'stud-list',
        'enrollment_date': now.toIso8601String(),
        'students': [
          {'id': 'stud-list', 'name': 'List Student', 'email': 'list@example.com'}
        ],
        'programs': [
          {'id': 'prog-list', 'name': 'List Program', 'total_price': 999.0}
        ],
        'contracts': [
          {'id': 'cnt-list', 'enrollment_id': 'enr-list', 'contract_number': 5, 'status': 'Draft'}
        ],
      };

      final enrollment = EnrollmentModel.fromJson(json);

      expect(enrollment.id, 'enr-list');
      expect(enrollment.student?.name, 'List Student');
      expect(enrollment.program?.name, 'List Program');
      expect(enrollment.contract?.contractNumber, 5);
      expect(enrollment.canBeDeleted, true);

      final serialized = enrollment.toJson();
      expect(serialized['id'], 'enr-list');
      expect(serialized['students'], isNotNull);
      expect(serialized['programs'], isNotNull);
      expect(serialized['contracts'], isNotNull);
    });
  });

  group('PaymentModel Complete Unit Tests', () {
    test('PaymentModel.fromJson and toJson roundtrip', () {
      final now = DateTime.now();
      final json = {
        'id': 'pay-1',
        'enrollment_id': 'enr-1',
        'amount_due': 500.0,
        'amount_paid': 500.0,
        'due_date': now.toIso8601String(),
        'status': 'Paid',
        'payment_method': 'Bank Transfer',
        'receipt_url': 'https://storage/receipts/pay-1.pdf',
        'receipt_generated_at': now.toIso8601String(),
        'enrollments': [
          {
            'id': 'enr-1',
            'program_id': 'prog-1',
            'student_id': 'stud-1',
          }
        ],
      };

      final payment = PaymentModel.fromJson(json);

      expect(payment.id, 'pay-1');
      expect(payment.enrollmentId, 'enr-1');
      expect(payment.amountDue, 500.0);
      expect(payment.amountPaid, 500.0);
      expect(payment.status, 'Paid');
      expect(payment.paymentMethod, 'Bank Transfer');
      expect(payment.receiptUrl, 'https://storage/receipts/pay-1.pdf');
      expect(payment.receiptGeneratedAt, isNotNull);
      expect(payment.enrollment, isNotNull);

      final serialized = payment.toJson();
      expect(serialized['id'], 'pay-1');
      expect(serialized['amount_due'], 500.0);
      expect(serialized['amount_paid'], 500.0);
      expect(serialized['status'], 'Paid');
      expect(serialized['payment_method'], 'Bank Transfer');
      expect(serialized['receipt_url'], 'https://storage/receipts/pay-1.pdf');
    });
  });
}
