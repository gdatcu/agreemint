import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/enrollment_model.dart';
import '../repositories/student_repository.dart';

part 'student_controller.g.dart';

@riverpod
class ProgramEnrollmentsController extends _$ProgramEnrollmentsController {
  @override
  Future<List<EnrollmentModel>> build(String programId) async {
    return ref.watch(studentRepositoryProvider).fetchEnrollmentsForProgram(programId);
  }

  /// Adds a student to the database and registers them in the program,
  /// setting the state to loading and capturing errors via guard.
  Future<void> addAndEnrollStudent({
    required String name,
    required String email,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(studentRepositoryProvider);
      await repository.enrollStudent(
        programId: programId,
        name: name,
        email: email,
        phone: phone,
      );
      return repository.fetchEnrollmentsForProgram(programId);
    });
  }
}
