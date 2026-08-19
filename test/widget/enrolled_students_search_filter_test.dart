import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agreemint/features/programs/models/program_model.dart';
import 'package:agreemint/features/students/views/enrolled_students_view.dart';
import 'package:agreemint/features/students/controllers/student_controller.dart';
import 'package:agreemint/features/students/models/enrollment_model.dart';
import 'package:agreemint/features/students/models/student_model.dart';

void main() {
  final testProgram = ProgramModel(
    id: 'prog-1',
    name: 'Flutter Mastery 2026',
    totalPrice: 1500.0,
    currency: 'RON',
    createdAt: DateTime.now(),
  );

  final testEnrollments = [
    EnrollmentModel(
      id: 'enr-1',
      studentId: 'stud-1',
      programId: 'prog-1',
      enrollmentDate: DateTime.now(),
      student: const StudentModel(
        id: 'stud-1',
        name: 'Alex Ionescu',
        email: 'alex@example.com',
        phone: '0712345678',
        clientType: 'PF',
      ),
    ),
    EnrollmentModel(
      id: 'enr-2',
      studentId: 'stud-2',
      programId: 'prog-1',
      enrollmentDate: DateTime.now(),
      student: const StudentModel(
        id: 'stud-2',
        name: 'Elena Popa Tech SRL',
        email: 'office@elenatech.ro',
        cui: 'RO987654321',
        clientType: 'SRL',
      ),
    ),
  ];

  testWidgets('EnrolledStudentsView renders search field and filter chips',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programEnrollmentsControllerProvider('prog-1')
              .overrideWith(() => MockEnrollmentsController(testEnrollments)),
        ],
        child: MaterialApp(
          home: EnrolledStudentsView(program: testProgram),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Flutter Mastery 2026 - Students'), findsOneWidget);

    // Verify Search Field
    expect(
        find.widgetWithText(TextField, 'Search by Name, Email, Phone, CUI/CIF...'),
        findsOneWidget);

    // Verify Filter Chips
    expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Signed'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Unsigned'), findsOneWidget);

    // Verify Students rendered
    expect(find.text('Alex Ionescu'), findsOneWidget);
    expect(find.text('Elena Popa Tech SRL'), findsOneWidget);

    // Enter Search Query
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.pumpAndSettle();

    // Verify Search Results
    expect(find.text('Alex Ionescu'), findsOneWidget);
    expect(find.text('Elena Popa Tech SRL'), findsNothing);
    expect(find.text('Showing 1 of 2 students'), findsOneWidget);

    // Enter CUI query
    await tester.enterText(find.byType(TextField), 'RO987654321');
    await tester.pumpAndSettle();

    // Verify CUI Search Results
    expect(find.text('Alex Ionescu'), findsNothing);
    expect(find.text('Elena Popa Tech SRL'), findsOneWidget);
    expect(find.text('Showing 1 of 2 students'), findsOneWidget);
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
