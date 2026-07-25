import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/program_model.dart';
import '../repositories/program_repository.dart';

part 'program_controller.g.dart';

@riverpod
class ProgramController extends _$ProgramController {
  @override
  Future<List<ProgramModel>> build() async {
    return ref.watch(programRepositoryProvider).fetchPrograms();
  }

  /// Adds a new program, setting loading state and capturing errors via guard.
  Future<void> addProgram({
    required String name,
    String? description,
    required double totalPrice,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(programRepositoryProvider);
      await repository.createProgram(
        name: name,
        description: description,
        totalPrice: totalPrice,
      );
      return repository.fetchPrograms();
    });
  }

  /// Updates an existing program, setting loading state and refreshing list.
  Future<void> updateProgram({
    required String id,
    required String name,
    String? description,
    required double totalPrice,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(programRepositoryProvider);
      await repository.updateProgram(
        id: id,
        name: name,
        description: description,
        totalPrice: totalPrice,
      );
      return repository.fetchPrograms();
    });
  }

  /// Deletes a program by ID, archiving all records to history tables and refreshing active list.
  Future<void> deleteProgram(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(programRepositoryProvider);
      await repository.deleteProgram(id);
      ref.invalidate(programHistoryProvider);
      return repository.fetchPrograms();
    });
  }
}

/// Fetches archived programs from program_history.
@riverpod
Future<List<ProgramModel>> programHistory(Ref ref) async {
  return ref.watch(programRepositoryProvider).fetchProgramHistory();
}

/// Fetches a single program by ID. Used by the router when navigating
/// directly to a deep-link URL (i.e. state.extra is null on browser reload).
@riverpod
Future<ProgramModel?> programById(Ref ref, String programId) async {
  return ref.watch(programRepositoryProvider).fetchProgramById(programId);
}
