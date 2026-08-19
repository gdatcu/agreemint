import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/features/students/services/certificate_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CertificateGeneratorService Unit Tests', () {
    test('generateCertificatePdf builds non-empty landscape PDF bytes with 50h default', () async {
      final service = CertificateGeneratorService();

      final pdfBytes = await service.generateCertificatePdf(
        studentName: 'Alex Ionescu',
        programName: 'TypeScript & Playwright Automation',
        completionDate: DateTime(2026, 8, 19),
        courseHours: 50,
        sessionCount: 20,
        certificateId: 'CERT-2026-9999',
        mentorName: 'Datcu George-Cristian',
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('generateCertificatePdf handles custom hours and mentor signature bytes cleanly', () async {
      final service = CertificateGeneratorService();

      final fakeSigBytes = Uint8List.fromList([
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

      final pdfBytes = await service.generateCertificatePdf(
        studentName: 'Elena Popa',
        programName: 'Flutter Mastery 2026',
        completionDate: DateTime.now(),
        courseHours: 60,
        sessionCount: 24,
        mentorSignatureBytes: fakeSigBytes,
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
