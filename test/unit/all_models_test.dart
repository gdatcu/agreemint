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
      expect(contract.enrollment, isNotNull);
      expect(contract.enrollment?.id, 'enr-100');

      final serialized = contract.toJson();
      expect(serialized['id'], 'cnt-100');
      expect(serialized['contract_number'], 42);
      expect(serialized['status'], 'FullySigned');
      expect(serialized['price_ron'], 4500.0);
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
      expect(payment.enrollment, isNotNull);

      final serialized = payment.toJson();
      expect(serialized['id'], 'pay-1');
      expect(serialized['amount_due'], 500.0);
      expect(serialized['amount_paid'], 500.0);
      expect(serialized['status'], 'Paid');
      expect(serialized['payment_method'], 'Bank Transfer');
    });
  });
}
