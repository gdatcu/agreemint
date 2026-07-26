import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agreemint/features/programs/models/program_model.dart';
import 'package:agreemint/features/students/models/student_model.dart';
import 'package:agreemint/features/students/models/enrollment_model.dart';
import 'package:agreemint/features/contracts/models/contract_model.dart';
import 'package:agreemint/features/students/views/enrolled_students_view.dart';
import 'package:agreemint/features/students/controllers/student_controller.dart';

void main() {
  group('EnrolledStudentsView Widget Tests', () {
    const testProgram = ProgramModel(
      id: 'prog-1',
      name: 'Flutter Mastery',
      totalPrice: 1000,
      currency: 'EUR',
    );

    testWidgets('Renders empty state when student list is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            programEnrollmentsControllerProvider('prog-1')
                .overrideWith(() => MockEnrollmentsController([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EnrolledStudentsView(program: testProgram),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No students enrolled yet'), findsOneWidget);
    });

    testWidgets('Displays lock icon for student with signed contract',
        (WidgetTester tester) async {
      final signedContract = ContractModel(
        id: 'cnt-signed',
        enrollmentId: 'enr-1',
        contractNumber: 1,
        status: 'FullySigned',
        clientSignatureUrl: 'https://storage.supabase.com/sig.png',
      );

      final signedEnrollment = EnrollmentModel(
        id: 'enr-1',
        programId: 'prog-1',
        studentId: 'stud-1',
        student: const StudentModel(
          id: 'stud-1',
          name: 'John Signed',
          email: 'john@example.com',
        ),
        contract: signedContract,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            programEnrollmentsControllerProvider('prog-1')
                .overrideWith(() => MockEnrollmentsController([signedEnrollment])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EnrolledStudentsView(program: testProgram),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('John Signed'), findsOneWidget);
      expect(find.text('Signed'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('Displays delete icon and opens confirmation modal for unsigned student',
        (WidgetTester tester) async {
      const unsignedEnrollment = EnrollmentModel(
        id: 'enr-2',
        programId: 'prog-1',
        studentId: 'stud-2',
        student: StudentModel(
          id: 'stud-2',
          name: 'Alice Unsigned',
          email: 'alice@example.com',
        ),
        contract: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            programEnrollmentsControllerProvider('prog-1')
                .overrideWith(() => MockEnrollmentsController([unsignedEnrollment])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EnrolledStudentsView(program: testProgram),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Alice Unsigned'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Tap delete button to open confirmation dialog
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete Student'), findsNWidgets(2));
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}

class MockEnrollmentsController extends ProgramEnrollmentsController {
  final List<EnrollmentModel> initialData;
  MockEnrollmentsController(this.initialData);

  @override
  Future<List<EnrollmentModel>> build(String programId) async {
    return initialData;
  }
}
