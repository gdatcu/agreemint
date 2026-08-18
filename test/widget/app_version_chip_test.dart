import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/widgets/app_version_chip.dart';

void main() {
  group('AppVersionChip Widget Tests', () {
    testWidgets('Renders version chip with provider override', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appVersionProvider.overrideWith((ref) async => 'v1.0.55'),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AppVersionChip(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('v1.0.55'), findsOneWidget);
    });
  });
}
