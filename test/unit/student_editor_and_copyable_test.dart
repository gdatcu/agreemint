import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/features/students/views/widgets/edit_student_dialog.dart';
import 'package:agreemint/core/widgets/copyable_text.dart';

void main() {
  group('Diacritics Stripping Unit Tests', () {
    test('removeRomanianDiacritics strips Romanian diacritics correctly', () {
      expect(
        removeRomanianDiacritics('Bălan Lorena-Dumitrița'),
        'Balan Lorena-Dumitrita',
      );
      expect(
        removeRomanianDiacritics('Țuțuianu Ștefan Împăratul'),
        'Tutuianu Stefan Imparatul',
      );
      expect(
        removeRomanianDiacritics('Câmpulung Muscel'),
        'Campulung Muscel',
      );
      expect(
        removeRomanianDiacritics('George Datcu'),
        'George Datcu',
      );
    });
  });

  group('CopyableText Widget Tests', () {
    testWidgets('Renders text and handles tap without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CopyableText(
              text: 'test@example.com',
              label: 'Email',
              icon: Icons.email_outlined,
            ),
          ),
        ),
      );

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);

      await tester.tap(find.text('test@example.com'));
      await tester.pump();
    });
  });
}
