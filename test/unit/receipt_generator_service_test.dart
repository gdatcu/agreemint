import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/features/payments/services/receipt_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummySignatureBytes = Uint8List.fromList([
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

    test('generateReceiptPdf embeds mentor signature PNG image cleanly', () async {
      final service = ReceiptGeneratorService();
      final pdfBytes = await service.generateReceiptPdf(
        receiptNumber: 'REC-2026-0003',
        paymentDate: DateTime(2026, 8, 2),
        studentName: 'Alex Popa',
        studentEmail: 'alex@example.com',
        programName: 'Android Mentorship',
        installmentNumber: 1,
        totalInstallments: 1,
        amountPaid: 1200.0,
        currency: 'EUR',
        paymentMethod: 'Bank Transfer',
        mentorSignatureBytes: dummySignatureBytes,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      expect(pdfBytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
    });
  });
}
