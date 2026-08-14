import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/prospect_model.dart';
import '../repositories/prospect_repository.dart';

part 'prospect_controller.g.dart';

@riverpod
class ProspectsController extends _$ProspectsController {
  @override
  Future<List<ProspectModel>> build() async {
    return ref.watch(prospectRepositoryProvider).fetchProspects();
  }

  Future<void> loadProspects() async {
    ref.invalidateSelf();
  }

  Future<void> addProspect({
    required String name,
    String? phone,
    String? email,
    String? programId,
    String? notes,
    required DateTime followUpDate,
    String status = 'Pending',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(prospectRepositoryProvider).createProspect(
        name: name,
        phone: phone,
        email: email,
        programId: programId,
        notes: notes,
        followUpDate: followUpDate,
        status: status,
      );
      return ref.read(prospectRepositoryProvider).fetchProspects();
    });
  }

  Future<void> updateProspect({
    required String prospectId,
    required String name,
    String? phone,
    String? email,
    String? programId,
    String? notes,
    required DateTime followUpDate,
    required String status,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(prospectRepositoryProvider).updateProspect(
        prospectId: prospectId,
        name: name,
        phone: phone,
        email: email,
        programId: programId,
        notes: notes,
        followUpDate: followUpDate,
        status: status,
      );
      return ref.read(prospectRepositoryProvider).fetchProspects();
    });
  }

  Future<void> deleteProspect(String prospectId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(prospectRepositoryProvider).deleteProspect(prospectId);
      return ref.read(prospectRepositoryProvider).fetchProspects();
    });
  }

  Future<void> convertToStudent({
    required ProspectModel prospect,
    required String programId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(prospectRepositoryProvider).convertToStudent(
        prospect: prospect,
        programId: programId,
      );
      return ref.read(prospectRepositoryProvider).fetchProspects();
    });
  }
}
