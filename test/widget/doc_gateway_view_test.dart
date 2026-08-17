import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/features/documents/views/doc_gateway_view.dart';

void main() {
  testWidgets('DocGatewayView renders PIN gateway card and verifies PIN input', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DocGatewayView(
          pdfUrl: 'https://example.com/test.pdf',
          expectedPin: '9506',
          docTitle: 'Chitanță Plată Test',
        ),
      ),
    );

    expect(find.text('Chitanță Plată Test'), findsOneWidget);
    expect(find.text('QualiAdept Secure Document'), findsOneWidget);
    expect(find.text('🔓 Deblochează Documentul'), findsOneWidget);

    // Enter wrong PIN
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('🔓 Deblochează Documentul'));
    await tester.pump();

    expect(find.textContaining('PIN incorect'), findsOneWidget);
  });
}
