import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prospect_model.dart';
import '../repositories/prospect_repository.dart';

final prospectsControllerProvider =
    StateNotifierProvider<ProspectsController, AsyncValue<List<ProspectModel>>>(
        (ref) {
  final repo = ref.watch(prospectRepositoryProvider);
  return ProspectsController(repo);
});

class ProspectsController extends StateNotifier<AsyncValue<List<ProspectModel>>> {
  final ProspectRepository _repository;

  ProspectsController(this._repository) : super(const AsyncValue.loading()) {
    loadProspects();
  }

  Future<void> loadProspects() async {
    state = const AsyncValue.loading();
    try {
      final prospects = await _repository.fetchProspects();
      state = AsyncValue.data(prospects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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
    try {
      await _repository.createProspect(
        name: name,
        phone: phone,
        email: email,
        programId: programId,
        notes: notes,
        followUpDate: followUpDate,
        status: status,
      );
      await loadProspects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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
    try {
      await _repository.updateProspect(
        prospectId: prospectId,
        name: name,
        phone: phone,
        email: email,
        programId: programId,
        notes: notes,
        followUpDate: followUpDate,
        status: status,
      );
      await loadProspects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProspect(String prospectId) async {
    try {
      await _repository.deleteProspect(prospectId);
      await loadProspects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> convertToStudent({
    required ProspectModel prospect,
    required String programId,
  }) async {
    try {
      await _repository.convertToStudent(
        prospect: prospect,
        programId: programId,
      );
      await loadProspects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
