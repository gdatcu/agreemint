import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enrollment_model.dart';

part 'student_repository.g.dart';

class StudentRepository {
  final SupabaseClient _client;

  StudentRepository(this._client);

  /// Fetches all enrollments for a specific program, joining student details.
  Future<List<EnrollmentModel>> fetchEnrollmentsForProgram(
      String programId) async {
    try {
      final response = await _client
          .from('enrollments')
          .select('*, students(*), programs(*)')
          .eq('program_id', programId)
          .order('enrollment_date', ascending: false);

      final data = response as List<dynamic>;
      return data
          .map((json) => EnrollmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch enrollments for program: $e');
    }
  }

  /// Inserts/upserts a student by email, and inserts an enrollment linking them to a program.
  Future<void> enrollStudent({
    required String programId,
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      // 1. Insert/upsert the student by email to retrieve the student ID
      final studentResponse = await _client
          .from('students')
          .upsert(
            {
              'name': name,
              'email': email,
              'phone': phone,
            },
            onConflict: 'email',
          )
          .select()
          .single();

      final studentId = studentResponse['id'] as String? ?? '';
      if (studentId.isEmpty) {
        throw Exception('Failed to obtain student ID during enrollment.');
      }

      // 2. Insert enrollment linking the student and the program
      await _client.from('enrollments').insert({
        'program_id': programId,
        'student_id': studentId,
      });
    } catch (e) {
      throw Exception('Failed to enroll student: $e');
    }
  }
}

@riverpod
StudentRepository studentRepository(Ref ref) {
  return StudentRepository(Supabase.instance.client);
}
