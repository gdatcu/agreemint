import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agreemint/features/programs/models/program_model.dart';
import 'package:agreemint/features/students/models/student_model.dart';
import 'package:agreemint/features/students/models/enrollment_model.dart';
import 'package:agreemint/features/students/views/widgets/edit_student_dialog.dart';
import 'package:agreemint/features/students/views/enrolled_students_view.dart';
import 'package:agreemint/features/students/controllers/student_controller.dart';

class MockEnrollmentsController extends ProgramEnrollmentsController {
  final List<EnrollmentModel> _initial;
  MockEnrollmentsController(this._initial);

  @override
  Future<List<EnrollmentModel>> build(String programId) async {
    return _initial;
  }
}

void main() {
  group('ANAF CUI Lookup Widget Integration Tests', () {
    const testProgram = ProgramModel(
      id: 'prog-1',
      name: 'Fullstack Academy',
      totalPrice: 1500,
      currency: 'RON',
    );

    testWidgets('EditStudentDialog shows ANAF search icon only for PFA/Company',
        (WidgetTester tester) async {
      const pfaStudent = StudentModel(
        id: 'stud-pfa',
        name: 'Tech Solutions SRL',
        email: 'office@tech.ro',
        clientType: 'PFA',
        cui: '53430793',
        regCom: 'J40/100/2022',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            programEnrollmentsControllerProvider('prog-1')
                .overrideWith(() => MockEnrollmentsController([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EditStudentDialog(
                student: pfaStudent,
                programId: 'prog-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify ANAF search button icon is rendered for PFA
      final searchIcon = find.byIcon(Icons.search);
      expect(searchIcon, findsOneWidget);

      // Verify tooltip
      final iconButton = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Caută date companie în ANAF',
      );
      expect(iconButton, findsOneWidget);
    });

    testWidgets('EditStudentDialog shows warning SnackBar when CUI is empty on search tap',
        (WidgetTester tester) async {
      const pfaStudentWithoutCui = StudentModel(
        id: 'stud-pfa-empty',
        name: 'Empty CUI SRL',
        email: 'empty@tech.ro',
        clientType: 'PFA',
        cui: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            programEnrollmentsControllerProvider('prog-1')
                .overrideWith(() => MockEnrollmentsController([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EditStudentDialog(
                student: pfaStudentWithoutCui,
                programId: 'prog-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap ANAF search button
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify SnackBar warning appears
      expect(
        find.text('Introduceți mai întâi un CUI / CIF pentru interogare.'),
        findsOneWidget,
      );
    });

    testWidgets('EnrolledStudentsView enrollment dialog dynamically toggles ANAF search icon',
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

      // Open Enroll New Student Dialog
      final enrollFab = find.byType(FloatingActionButton);
      expect(enrollFab, findsOneWidget);
      await tester.tap(enrollFab);
      await tester.pumpAndSettle();

      // Initially on PF (Individual), ANAF search icon should NOT be visible
      expect(find.text('Enroll New Student'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNothing);

      // Switch to PFA / Company segment
      final pfaSegment = find.text('PFA / Company');
      expect(pfaSegment, findsOneWidget);
      await tester.tap(pfaSegment);
      await tester.pumpAndSettle();

      // Now ANAF search icon should be present
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Tapping search with empty field displays warning SnackBar
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(
        find.text('Introduceți mai întâi un CUI / CIF pentru interogare.'),
        findsOneWidget,
      );
    });
  });
}
