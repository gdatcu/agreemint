import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agreemint/main.dart';
import 'package:agreemint/features/payments/services/receipt_generator_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Agreemint End-to-End (E2E) App & Receipt Generation Flow Test', () {
    testWidgets('App loads and renders main application root', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify MyApp component is mounted in widget tree
      expect(find.byType(MyApp), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('E2E receipt PDF generation and byte signature validation', (WidgetTester tester) async {
      final service = ReceiptGeneratorService();
      final pdfBytes = await service.generateReceiptPdf(
        receiptNumber: 'REC-E2E-9999',
        paymentDate: DateTime.now(),
        studentName: 'E2E Student',
        studentEmail: 'e2e@example.com',
        programName: 'Fullstack Mentorship',
        installmentNumber: 1,
        totalInstallments: 1,
        amountPaid: 1500.0,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      expect(pdfBytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
    });
  });
}
