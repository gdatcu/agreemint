import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enrollment_model.dart';

part 'student_repository.g.dart';

class StudentRepository {
  final SupabaseClient _client;

  StudentRepository(this._client);

  /// Fetches all enrollments for a specific program, joining student, program, and contract details.
  Future<List<EnrollmentModel>> fetchEnrollmentsForProgram(
      String programId) async {
    try {
      final response = await _client
          .from('enrollments')
          .select('*, students(*), programs(*), contracts(*)')
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
    String clientType = 'PF',
    String? cui,
    String? regCom,
    String? billingAddress,
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
              'client_type': clientType,
              'cui': cui,
              'reg_com': regCom,
              'billing_address': billingAddress,
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


  /// Deletes an enrollment (and associated unsigned contracts/payments) for a student.
  /// If the student has no other active enrollments, cleans up the student record.
  Future<void> deleteEnrollment({
    required String enrollmentId,
    required String studentId,
  }) async {
    try {
      // 1. Delete associated payments for this enrollment
      await _client
          .from('payments')
          .delete()
          .eq('enrollment_id', enrollmentId);

      // 2. Delete associated contracts for this enrollment
      await _client
          .from('contracts')
          .delete()
          .eq('enrollment_id', enrollmentId);

      // 3. Delete the enrollment record
      await _client
          .from('enrollments')
          .delete()
          .eq('id', enrollmentId);

      // 4. Check if student has any other remaining enrollments
      if (studentId.isNotEmpty) {
        final remaining = await _client
            .from('enrollments')
            .select('id')
            .eq('student_id', studentId);

        if ((remaining as List).isEmpty) {
          await _client
              .from('students')
              .delete()
              .eq('id', studentId);
        }
      }
    } catch (e) {
      throw Exception('Failed to delete student enrollment: $e');
    }
  }
}

@riverpod
StudentRepository studentRepository(Ref ref) {
  return StudentRepository(Supabase.instance.client);
}
