import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agreemint/features/payments/models/payment_model.dart';
import 'package:agreemint/features/payments/views/solo_invoice_dialog.dart';
import 'package:agreemint/features/payments/controllers/payment_controller.dart';
import 'package:agreemint/features/programs/models/program_model.dart';
import 'package:agreemint/features/students/models/enrollment_model.dart';
import 'package:agreemint/features/students/models/student_model.dart';

class MockEnrollmentPaymentsController extends EnrollmentPaymentsController {
  @override
  Future<List<PaymentModel>> build(String enrollmentId) async {
    return [];
  }

  @override
  Future<void> saveExternalInvoice({
    required String paymentId,
    required String invoiceNumber,
    String? invoiceUrl,
  }) async {
    // Mock save success
  }
}

void main() {
  group('SoloInvoiceDialog Widget Tests', () {
    const testEnrollment = EnrollmentModel(
      id: 'enr-1',
      programId: 'prog-1',
      studentId: 'stud-1',
      program: ProgramModel(
        id: 'prog-1',
        name: 'Mentorat',
        totalPrice: 2000,
        currency: 'RON',
      ),
      student: StudentModel(
        id: 'stud-1',
        name: 'Andrei Popescu',
        email: 'andrei@test.ro',
      ),
    );

    final testPayment = PaymentModel(
      id: 'pay-1',
      enrollmentId: 'enr-1',
      dueDate: DateTime(2024, 10, 15),
      amountDue: 1000,
      amountPaid: 1000,
      status: 'Paid',
      enrollment: testEnrollment,
    );

    testWidgets('renders all dialog elements and smart parser components',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enrollmentPaymentsControllerProvider('enr-1')
                .overrideWith(() => MockEnrollmentPaymentsController()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SoloInvoiceDialog(
                payment: testPayment,
                enrollmentId: 'enr-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Factură Fiscală SOLO / Link Parser'), findsOneWidget);
      expect(find.text('Smart Link & Text Parser'), findsOneWidget);
      expect(find.text('Paste Clipboard'), findsOneWidget);
      expect(find.text('⚡ Parsează Link / Text'), findsOneWidget);
      expect(find.text('Număr Factură SOLO (ex: SL-10492, SOLO-10492) *'),
          findsOneWidget);
      expect(find.text('Link Factură / URL PDF (Opțional)'), findsOneWidget);
      expect(find.text('Încarcă PDF Factură'), findsOneWidget);
      expect(find.text('Salvează Factura'), findsOneWidget);
    });

    testWidgets(
        'smart link parser extracts series and fills controllers from SOLO URL',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enrollmentPaymentsControllerProvider('enr-1')
                .overrideWith(() => MockEnrollmentPaymentsController()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SoloInvoiceDialog(
                payment: testPayment,
                enrollmentId: 'enr-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter a SOLO URL into the smart input field
      final smartInput = find.byWidgetPredicate((w) =>
          w is TextField &&
          w.decoration?.hintText?.contains('Pasează un link SOLO') == true);
      expect(smartInput, findsOneWidget);

      await tester.enterText(
          smartInput, 'https://app.solo.ro/invoices/SL-10492');
      await tester.pumpAndSettle();

      // Tap the Parse button
      await tester.tap(find.text('⚡ Parsează Link / Text'));
      await tester.pumpAndSettle();

      // Verify the invoice number controller is updated
      expect(find.text('SL-10492'), findsWidgets);
      expect(find.text('https://app.solo.ro/invoices/SL-10492'), findsWidgets);
      // Verify detected badge is visible
      expect(find.textContaining('Detectat: SL-10492'), findsWidgets);
    });

    testWidgets('auto-detects and extracts when URL is pasted in number field',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enrollmentPaymentsControllerProvider('enr-1')
                .overrideWith(() => MockEnrollmentPaymentsController()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SoloInvoiceDialog(
                payment: testPayment,
                enrollmentId: 'enr-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the invoice number field
      final numberField = find.byWidgetPredicate((w) =>
          w is TextField &&
          w.decoration?.labelText
                  ?.contains('Număr Factură SOLO') ==
              true);
      expect(numberField, findsOneWidget);

      // User accidentally pastes the whole URL into the invoice number field
      await tester.enterText(
          numberField, 'https://app.solo.ro/invoices/SL-998877');
      await tester.pumpAndSettle();

      // It should auto-clean the number field to SL-998877 and populate the URL field
      expect(find.text('SL-998877'), findsWidgets);
      expect(
          find.text('https://app.solo.ro/invoices/SL-998877'), findsWidgets);
    });

    testWidgets('shows warning on empty invoice number submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            enrollmentPaymentsControllerProvider('enr-1')
                .overrideWith(() => MockEnrollmentPaymentsController()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SoloInvoiceDialog(
                payment: testPayment,
                enrollmentId: 'enr-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap save directly without entering anything
      await tester.tap(find.text('Salvează Factura'));
      await tester.pumpAndSettle();

      expect(find.text('Vă rugăm să introduceți seria și numărul facturii.'),
          findsOneWidget);
    });
  });
}
