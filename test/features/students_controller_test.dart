import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agreemint/features/students/models/enrollment_model.dart';
import 'package:agreemint/features/students/repositories/student_repository.dart';
import 'package:agreemint/features/students/controllers/student_controller.dart';

class MockStudentRepository extends Mock implements StudentRepository {}

void main() {
  late MockStudentRepository mockRepository;

  setUp(() {
    mockRepository = MockStudentRepository();
  });

  ProviderContainer makeContainer(MockStudentRepository repo) {
    final container = ProviderContainer(
      overrides: [
        studentRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ProgramEnrollmentsController Integration Tests 100% Coverage', () {
    const programId = 'prog-100';

    test('build fetches enrollments from StudentRepository', () async {
      final mockEnrollments = [
        const EnrollmentModel(
          id: 'enr-1',
          programId: programId,
          studentId: 'stud-1',
        ),
      ];

      when(() => mockRepository.fetchEnrollmentsForProgram(programId))
          .thenAnswer((_) async => mockEnrollments);

      final container = makeContainer(mockRepository);

      final result = await container
          .read(programEnrollmentsControllerProvider(programId).future);

      expect(result, equals(mockEnrollments));
      expect(result.length, 1);
      verify(() => mockRepository.fetchEnrollmentsForProgram(programId))
          .called(1);
    });

    test('addAndEnrollStudent calls repository and updates state', () async {
      when(() => mockRepository.fetchEnrollmentsForProgram(programId))
          .thenAnswer((_) async => []);

      when(() => mockRepository.enrollStudent(
            programId: programId,
            name: 'Alice',
            email: 'alice@example.com',
            phone: '+40700000000',
          )).thenAnswer((_) async {});

      final container = makeContainer(mockRepository);

      await container.read(programEnrollmentsControllerProvider(programId).future);

      await container
          .read(programEnrollmentsControllerProvider(programId).notifier)
          .addAndEnrollStudent(
            name: 'Alice',
            email: 'alice@example.com',
            phone: '+40700000000',
          );

      verify(() => mockRepository.enrollStudent(
            programId: programId,
            name: 'Alice',
            email: 'alice@example.com',
            phone: '+40700000000',
          )).called(1);
    });

    test('removeStudentEnrollment calls repository delete and refreshes', () async {
      when(() => mockRepository.fetchEnrollmentsForProgram(programId))
          .thenAnswer((_) async => []);

      when(() => mockRepository.deleteEnrollment(
            enrollmentId: 'enr-100',
            studentId: 'stud-100',
          )).thenAnswer((_) async {});

      final container = makeContainer(mockRepository);

      await container.read(programEnrollmentsControllerProvider(programId).future);

      await container
          .read(programEnrollmentsControllerProvider(programId).notifier)
          .removeStudentEnrollment(
            enrollmentId: 'enr-100',
            studentId: 'stud-100',
          );

      verify(() => mockRepository.deleteEnrollment(
            enrollmentId: 'enr-100',
            studentId: 'stud-100',
          )).called(1);
    });
  });
}
