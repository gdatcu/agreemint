import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/program_model.dart';

part 'program_repository.g.dart';

class ProgramRepository {
  final SupabaseClient _client;

  ProgramRepository(this._client);

  /// Fetches all programs ordered by created_at descending.
  Future<List<ProgramModel>> fetchPrograms() async {
    try {
      final response = await _client
          .from('programs')
          .select()
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data
          .map((json) => ProgramModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch programs: $e');
    }
  }

  /// Fetches a single program by its ID. Returns null if not found.
  Future<ProgramModel?> fetchProgramById(String programId) async {
    try {
      final response = await _client
          .from('programs')
          .select()
          .eq('id', programId)
          .maybeSingle();

      if (response == null) return null;
      return ProgramModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch program by ID: $e');
    }
  }

  /// Inserts a new program into the database.
  Future<ProgramModel> createProgram({
    required String name,
    String? description,
    required double totalPrice,
  }) async {
    try {
      final response = await _client
          .from('programs')
          .insert({
            'name': name,
            'description': description,
            'total_price': totalPrice,
          })
          .select()
          .single();

      return ProgramModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create program: $e');
    }
  }

  /// Updates an existing program in the database.
  Future<ProgramModel> updateProgram({
    required String id,
    required String name,
    String? description,
    required double totalPrice,
  }) async {
    try {
      final response = await _client
          .from('programs')
          .update({
            'name': name,
            'description': description,
            'total_price': totalPrice,
          })
          .eq('id', id)
          .select()
          .single();

      return ProgramModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update program: $e');
    }
  }

  /// Deletes a program from the database by its ID.
  Future<void> deleteProgram(String id) async {
    try {
      await _client.from('programs').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete program: $e');
    }
  }
}

@riverpod
ProgramRepository programRepository(Ref ref) {
  return ProgramRepository(Supabase.instance.client);
}
