import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/features/payments/services/receipt_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiptGeneratorService Comprehensive Unit Tests', () {
    test('generateReceiptPdf builds valid non-empty PDF bytes', () async {
      final service = ReceiptGeneratorService();
      final pdfBytes = await service.generateReceiptPdf(
        receiptNumber: 'REC-2026-0001',
        paymentDate: DateTime(2026, 7, 26),
        studentName: 'Ion Popescu',
        studentEmail: 'ion.popescu@example.com',
        programName: 'Flutter Mentorship Cohort 1',
        installmentNumber: 1,
        totalInstallments: 3,
        amountPaid: 500.0,
        currency: 'EUR',
        paymentMethod: 'Bank Transfer',
        transactionReference: 'TXN-998877',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      // PDF documents start with %PDF header
      expect(pdfBytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
    });

    test('generateReceiptPdf works with RON currency and fallback values', () async {
      final service = ReceiptGeneratorService();
      final pdfBytes = await service.generateReceiptPdf(
        receiptNumber: 'REC-2026-0002',
        paymentDate: DateTime(2026, 8, 1),
        studentName: 'Maria Ionescu',
        studentEmail: 'maria@example.com',
        programName: 'Fullstack Mentorship',
        installmentNumber: 2,
        totalInstallments: 2,
        amountPaid: 2500.0,
        currency: 'RON',
        paymentMethod: 'Card',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      expect(pdfBytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
    });
  });
}
