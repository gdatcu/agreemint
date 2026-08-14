import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prospect_model.dart';

final prospectRepositoryProvider = Provider<ProspectRepository>((ref) {
  return ProspectRepository(Supabase.instance.client);
});

class ProspectRepository {
  final SupabaseClient _client;

  ProspectRepository(this._client);

  /// Fetches all prospects ordered by follow_up_date ascending.
  Future<List<ProspectModel>> fetchProspects() async {
    try {
      final response = await _client
          .from('prospects')
          .select('*, programs(*)')
          .order('follow_up_date', ascending: true);

      return (response as List)
          .map((data) => ProspectModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch prospects: $e');
    }
  }

  /// Creates a new prospect.
  Future<ProspectModel> createProspect({
    required String name,
    String? phone,
    String? email,
    String? programId,
    String? notes,
    required DateTime followUpDate,
    String status = 'Pending',
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'name': name,
        'phone': phone,
        'email': email,
        'program_id': programId,
        'notes': notes,
        'follow_up_date': followUpDate.toIso8601String(),
        'status': status,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _client
          .from('prospects')
          .insert(data)
          .select('*, programs(*)')
          .single();

      return ProspectModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create prospect: $e');
    }
  }

  /// Updates an existing prospect record.
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
      final data = {
        'name': name,
        'phone': phone,
        'email': email,
        'program_id': programId,
        'notes': notes,
        'follow_up_date': followUpDate.toIso8601String(),
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('prospects').update(data).eq('id', prospectId);
    } catch (e) {
      throw Exception('Failed to update prospect: $e');
    }
  }

  /// Deletes a prospect.
  Future<void> deleteProspect(String prospectId) async {
    try {
      await _client.from('prospects').delete().eq('id', prospectId);
    } catch (e) {
      throw Exception('Failed to delete prospect: $e');
    }
  }

  /// Converts a prospect into an enrolled student in the selected program.
  Future<void> convertToStudent({
    required ProspectModel prospect,
    required String programId,
  }) async {
    try {
      final now = DateTime.now();

      // 1. Insert into students table
      final studentRes = await _client
          .from('students')
          .insert({
            'name': prospect.name,
            'phone': prospect.phone,
            'email': prospect.email,
            'notes': prospect.notes,
            'created_at': now.toIso8601String(),
          })
          .select()
          .single();

      final studentId = studentRes['id'] as String;

      // 2. Insert into enrollments table
      await _client.from('enrollments').insert({
        'student_id': studentId,
        'program_id': programId,
        'created_at': now.toIso8601String(),
      });

      // 3. Mark prospect status as Converted
      await _client
          .from('prospects')
          .update({
            'status': 'Converted',
            'updated_at': now.toIso8601String(),
          })
          .eq('id', prospect.id);
    } catch (e) {
      throw Exception('Failed to convert prospect to student: $e');
    }
  }
}
