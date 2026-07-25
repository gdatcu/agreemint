import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contract_model.dart';

part 'contract_repository.g.dart';

@riverpod
ContractRepository contractRepository(Ref ref) {
  return ContractRepository(Supabase.instance.client);
}

class ContractRepository {
  final SupabaseClient _client;

  ContractRepository(this._client);

  /// Fetches a contract by contract ID. Returns null if none exists or on error.
  Future<ContractModel?> fetchContractById(String contractId) async {
    try {
      if (contractId.isEmpty) return null;

      final response = await _client
          .from('contracts')
          .select('*, enrollments(*, students(*), programs(*))')
          .eq('id', contractId);

      if (response is List && response.isNotEmpty) {
        return ContractModel.fromJson(response.first as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches a contract for a given enrollment. Returns null if none exists or on error.
  Future<ContractModel?> fetchContractForEnrollment(String enrollmentId) async {
    try {
      if (enrollmentId.isEmpty) return null;

      final response = await _client
          .from('contracts')
          .select()
          .eq('enrollment_id', enrollmentId);

      if (response is List && response.isNotEmpty) {
        return ContractModel.fromJson(response.first as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Creates a database row first to reserve the auto-incremented contract number.
  Future<ContractModel> createContractPlaceholder({
    required String enrollmentId,
  }) async {
    try {
      final response = await _client
          .from('contracts')
          .insert({
            'enrollment_id': enrollmentId,
            'signed_date': DateTime.now().toIso8601String(),
          })
          .select();

      if (response is List && response.isNotEmpty) {
        return ContractModel.fromJson(response.first as Map<String, dynamic>);
      }
      throw Exception('Failed to create contract placeholder in database.');
    } catch (e) {
      throw Exception('Failed to create contract placeholder: $e');
    }
  }

  /// Uploads PDF bytes to storage and updates the database row with the PDF URL.
  Future<ContractModel> updateContractPdf({
    required String contractId,
    required String enrollmentId,
    required Uint8List pdfBytes,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'contract_${enrollmentId}_$timestamp.pdf';

      await _client.storage.from('contracts').uploadBinary(
            path,
            pdfBytes,
            fileOptions: const FileOptions(
                upsert: true, contentType: 'application/pdf'),
          );

      final pdfUrl = _client.storage.from('contracts').getPublicUrl(path);

      final response = await _client
          .from('contracts')
          .update({'pdf_url': pdfUrl})
          .eq('id', contractId)
          .select();

      if (response is List && response.isNotEmpty) {
        return ContractModel.fromJson(response.first as Map<String, dynamic>);
      }
      throw Exception('Failed to update contract PDF record.');
    } catch (e) {
      throw Exception('Failed to update contract PDF: $e');
    }
  }

  /// Uploads final signed PDF bytes and updates the signed_pdf_url database column.
  Future<ContractModel> uploadSignedContractPdf({
    required String contractId,
    required String enrollmentId,
    required Uint8List pdfBytes,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'signed_contract_${enrollmentId}_$timestamp.pdf';

      await _client.storage.from('contracts').uploadBinary(
            path,
            pdfBytes,
            fileOptions: const FileOptions(
                upsert: true, contentType: 'application/pdf'),
          );

      final signedPdfUrl =
          _client.storage.from('contracts').getPublicUrl(path);

      final response = await _client
          .from('contracts')
          .update({
            'signed_pdf_url': signedPdfUrl,
            'signed_date': DateTime.now().toIso8601String(),
          })
          .eq('id', contractId)
          .select();

      if (response is List && response.isNotEmpty) {
        return ContractModel.fromJson(response.first as Map<String, dynamic>);
      }
      throw Exception('Failed to update signed contract PDF record.');
    } catch (e) {
      throw Exception('Failed to upload signed contract PDF: $e');
    }
  }

  /// Uploads mentor signature image to storage and returns its public URL.
  Future<String> uploadMentorSignature({
    required String contractId,
    required String enrollmentId,
    required Uint8List signatureBytes,
  }) async {
    try {
      final path = 'mentor_signatures/contract_${enrollmentId}_mentor.png';
      await _client.storage.from('contracts').uploadBinary(
            path,
            signatureBytes,
            fileOptions: const FileOptions(
                upsert: true, contentType: 'image/png'),
          );
      return _client.storage.from('contracts').getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload mentor signature: $e');
    }
  }

  /// Downloads mentor signature image bytes from storage bucket 'contracts'.
  Future<Uint8List?> fetchMentorSignatureBytes(String enrollmentId) async {
    try {
      final path = 'mentor_signatures/contract_${enrollmentId}_mentor.png';
      final bytes = await _client.storage.from('contracts').download(path);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Uploads client signature image to storage and returns its public URL.
  Future<String> uploadClientSignature({
    required String contractId,
    required String enrollmentId,
    required Uint8List signatureBytes,
  }) async {
    try {
      final path = 'client_signatures/contract_${enrollmentId}_client.png';
      await _client.storage.from('contracts').uploadBinary(
            path,
            signatureBytes,
            fileOptions: const FileOptions(
                upsert: true, contentType: 'image/png'),
          );
      return _client.storage.from('contracts').getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload client signature: $e');
    }
  }

  /// Updates contract status column and price.
  Future<ContractModel> updateStatus({
    required String contractId,
    required String status,
    String? mentorSignatureUrl,
    String? clientSignatureUrl,
    DateTime? clientSignedDate,
    double? priceRon,
  }) async {
    try {
      final Map<String, dynamic> updates = {'status': status};
      if (mentorSignatureUrl != null) {
        updates['mentor_signature_url'] = mentorSignatureUrl;
      }
      if (clientSignatureUrl != null) {
        updates['client_signature_url'] = clientSignatureUrl;
      }
      if (clientSignedDate != null) {
        updates['client_signed_date'] = clientSignedDate.toIso8601String();
      }
      if (priceRon != null) {
        updates['price_ron'] = priceRon;
      }

      final response = await _client
          .from('contracts')
          .update(updates)
          .eq('id', contractId)
          .select();

      if (response is List && response.isNotEmpty) {
        return ContractModel.fromJson(response.first as Map<String, dynamic>);
      }
      throw Exception('Failed to update contract status.');
    } catch (e) {
      throw Exception('Failed to update contract status: $e');
    }
  }

  /// Watches contract changes via Supabase Realtime.
  Stream<ContractModel> watchContract(String contractId) {
    return _client
        .from('contracts')
        .stream(primaryKey: ['id'])
        .eq('id', contractId)
        .map((list) {
          if (list.isEmpty) {
            throw Exception('Contract not found');
          }
          return ContractModel.fromJson(list.first);
        });
  }
}
