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
    String clientType = 'PF',
    String? cui,
    String? regCom,
    String? billingAddress,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(studentRepositoryProvider);
      await repository.enrollStudent(
        programId: programId,
        name: name,
        email: email,
        phone: phone,
        clientType: clientType,
        cui: cui,
        regCom: regCom,
        billingAddress: billingAddress,
      );
      return repository.fetchEnrollmentsForProgram(programId);
    });
  }


  /// Deletes a student enrollment if the contract has not been signed by the beneficiary.
  Future<void> removeStudentEnrollment({
    required String enrollmentId,
    required String studentId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(studentRepositoryProvider);
      await repository.deleteEnrollment(
        enrollmentId: enrollmentId,
        studentId: studentId,
      );
      return repository.fetchEnrollmentsForProgram(programId);
    });
  }
}
