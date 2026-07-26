import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agreemint/core/views/access_denied_view.dart';
import 'package:agreemint/features/programs/models/program_model.dart';
import 'package:agreemint/features/programs/views/programs_view.dart';
import 'package:agreemint/features/programs/controllers/program_controller.dart';
import 'package:agreemint/features/analytics/views/analytics_view.dart';
import 'package:agreemint/core/auth/mentor_auth_controller.dart';
import 'package:agreemint/features/payments/views/pending_dashboard_view.dart';
import 'package:agreemint/features/payments/controllers/payment_controller.dart';
import 'package:agreemint/features/payments/models/payment_model.dart';

void main() {
  group('AccessDeniedView Widget Tests', () {
    testWidgets('Renders access denied screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mentorAuthControllerProvider.overrideWith(() => MockMentorAuthController()),
          ],
          child: const MaterialApp(
            home: AccessDeniedView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AccessDeniedView), findsOneWidget);
    });
  });

  group('ProgramsView Widget Tests', () {
    testWidgets('Displays program cards when list is loaded', (WidgetTester tester) async {
      final mockPrograms = [
        const ProgramModel(
          id: 'prog-1',
          name: 'Flutter Cohort 1',
          description: 'Learn Flutter & Supabase',
          totalPrice: 1500,
          currency: 'EUR',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            programControllerProvider.overrideWith(() => MockProgramController(mockPrograms)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProgramsView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Flutter Cohort 1'), findsOneWidget);
      expect(find.text('Total Price: 1,500.00 EUR'), findsOneWidget);
    });
  });

  group('AnalyticsView & PendingDashboardView Widget Tests', () {
    testWidgets('AnalyticsView renders summary cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            programControllerProvider.overrideWith(() => MockProgramController([])),
            globalPendingPaymentsControllerProvider.overrideWith(() => MockGlobalPaymentsController([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AnalyticsView(),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AnalyticsView), findsOneWidget);
    });

    testWidgets('PendingDashboardView renders tab structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalPendingPaymentsControllerProvider.overrideWith(() => MockGlobalPaymentsController([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PendingDashboardView(),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(PendingDashboardView), findsOneWidget);
    });
  });
}

class MockProgramController extends ProgramController {
  final List<ProgramModel> data;
  MockProgramController(this.data);

  @override
  Future<List<ProgramModel>> build() async {
    return data;
  }
}

class MockGlobalPaymentsController extends GlobalPendingPaymentsController {
  final List<PaymentModel> data;
  MockGlobalPaymentsController(this.data);

  @override
  Future<List<PaymentModel>> build() async {
    return data;
  }
}

class MockMentorAuthController extends MentorAuthController {
  @override
  Future<bool> build() async {
    return false;
  }
}
