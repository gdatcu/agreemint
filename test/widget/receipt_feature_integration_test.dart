import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agreemint/features/payments/views/receipt_preview_dialog.dart';
import 'package:agreemint/features/payments/views/receipt_signature_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Uint8List testPdfBytes = Uint8List.fromList([
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35, 0x0A, 0x25, 0xE2, 0xE3, 0xCF, 0xD3
  ]);

  group('Receipt Preview & Signature Integration Widget Tests', () {
    testWidgets('ReceiptPreviewDialog renders title and actions cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReceiptPreviewDialog(
                pdfBytes: testPdfBytes,
                filename: 'Chitanta_REC-TEST-001.pdf',
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(ReceiptPreviewDialog), findsOneWidget);
      expect(find.text('Chitanță Plată / Payment Receipt'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('ReceiptSignatureDialog renders signature pad and action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReceiptSignatureDialog(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(ReceiptSignatureDialog), findsOneWidget);
      expect(find.text('Semnătură Mentor / Signature'), findsOneWidget);
      expect(find.text('Șterge / Clear'), findsOneWidget);
      expect(find.text('Aplică / Confirm'), findsOneWidget);
    });

    testWidgets('ReceiptPreviewDialog shows Sign button when onSignReceipt is provided', (WidgetTester tester) async {
      bool signed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReceiptPreviewDialog(
                pdfBytes: testPdfBytes,
                filename: 'Chitanta_REC-TEST-001.pdf',
                onSignReceipt: (bytes) async {
                  signed = true;
                  return testPdfBytes;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Semnează / Sign'), findsOneWidget);
      expect(signed, isFalse);
    });
  });
}
