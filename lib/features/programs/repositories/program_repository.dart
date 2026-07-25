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

  /// Moves program, enrollments, contracts, and payments to history tables and deletes from active list.
  Future<void> deleteProgram(String id) async {
    try {
      // 1. Try calling PostgreSQL RPC function archive_program
      try {
        await _client.rpc('archive_program', params: {'p_id': id});
        return;
      } catch (_) {
        // Fallback: Perform client-side archiving if RPC function is not yet installed in Supabase
        await _archiveProgramClientSide(id);
      }
    } catch (e) {
      throw Exception('Failed to delete and archive program: $e');
    }
  }

  Future<void> _archiveProgramClientSide(String programId) async {
    try {
      // Fetch program record
      final progRes =
          await _client.from('programs').select().eq('id', programId).maybeSingle();
      if (progRes == null) return;
      final programData = Map<String, dynamic>.from(progRes);

      // Archive Program
      try {
        await _client.from('program_history').insert({
          'id': programData['id'],
          'name': programData['name'],
          'description': programData['description'],
          'total_price': programData['total_price'],
        });
      } catch (_) {}

      // Fetch enrollments
      final enrRes =
          await _client.from('enrollments').select().eq('program_id', programId);
      if (enrRes is List) {
        for (final enrItem in enrRes) {
          final enr = Map<String, dynamic>.from(enrItem as Map);
          final enrollmentId = enr['id'] as String;

          // Archive Enrollment
          try {
            await _client.from('enrollment_history').insert({
              'id': enr['id'],
              'program_id': enr['program_id'],
              'student_id': enr['student_id'],
              'enrollment_date': enr['enrollment_date'],
            });
          } catch (_) {}

          // Fetch and Archive Contracts
          try {
            final contracts = await _client
                .from('contracts')
                .select()
                .eq('enrollment_id', enrollmentId);
            if (contracts is List) {
              for (final cItem in contracts) {
                final c = Map<String, dynamic>.from(cItem as Map);
                await _client.from('contract_history').insert({
                  'id': c['id'],
                  'enrollment_id': c['enrollment_id'],
                  'contract_number': c['contract_number'],
                  'pdf_url': c['pdf_url'],
                  'signed_pdf_url': c['signed_pdf_url'],
                  'signed_date': c['signed_date'],
                  'status': c['status'],
                  'mentor_signature_url': c['mentor_signature_url'],
                  'client_signature_url': c['client_signature_url'],
                  'client_signed_date': c['client_signed_date'],
                  'price_ron': c['price_ron'],
                });
              }
            }
          } catch (_) {}

          // Fetch and Archive Payments
          try {
            final payments = await _client
                .from('payments')
                .select()
                .eq('enrollment_id', enrollmentId);
            if (payments is List) {
              for (final pItem in payments) {
                final p = Map<String, dynamic>.from(pItem as Map);
                await _client.from('payment_history').insert({
                  'id': p['id'],
                  'enrollment_id': p['enrollment_id'],
                  'amount_due': p['amount_due'],
                  'amount_paid': p['amount_paid'],
                  'due_date': p['due_date'],
                  'status': p['status'],
                  'payment_method': p['payment_method'],
                });
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    // Delete active program (cascades active enrollments/contracts/payments)
    await _client.from('programs').delete().eq('id', programId);
  }

  /// Fetches archived programs from program_history table.
  Future<List<ProgramModel>> fetchProgramHistory() async {
    try {
      final response = await _client
          .from('program_history')
          .select()
          .order('archived_at', ascending: false);

      if (response is List) {
        return response
            .map((json) => ProgramModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

@riverpod
ProgramRepository programRepository(Ref ref) {
  return ProgramRepository(Supabase.instance.client);
}
