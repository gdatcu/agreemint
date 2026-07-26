import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';

part 'payment_repository.g.dart';

class PaymentRepository {
  final SupabaseClient _client;

  PaymentRepository(this._client);

  /// Fetches all payments for a given enrollment, sorted by due_date ascending.
  Future<List<PaymentModel>> fetchPaymentsForEnrollment(
      String enrollmentId) async {
    try {
      final response = await _client
          .from('payments')
          .select()
          .eq('enrollment_id', enrollmentId)
          .order('due_date', ascending: true);

      final data = response as List<dynamic>;
      return data
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch payments for enrollment: $e');
    }
  }

  /// Fetches unpaid installments app-wide with student and program details.
  Future<List<PaymentModel>> fetchGlobalPendingPayments() async {
    try {
      final response = await _client
          .from('payments')
          .select('*, enrollments(*, students(*), programs(*))')
          .neq('status', 'Paid')
          .order('due_date', ascending: true);

      final data = response as List<dynamic>;
      return data
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch global pending payments: $e');
    }
  }

  /// Calculates installment amounts and batch-inserts a schedule of rows.
  Future<void> createPaymentPlan({
    required String enrollmentId,
    required double totalAmount,
    required int numberOfInstallments,
    String? defaultMethod,
  }) async {
    try {
      if (numberOfInstallments <= 0) {
        throw Exception('Number of installments must be greater than zero.');
      }

      final installmentAmount = totalAmount / numberOfInstallments;
      final List<Map<String, dynamic>> rows = [];
      final today = DateTime.now();

      for (int i = 0; i < numberOfInstallments; i++) {
        final dueDate = today.add(Duration(days: i * 30));
        rows.add({
          'enrollment_id': enrollmentId,
          'amount_due': installmentAmount,
          'amount_paid': 0.0,
          // Format date as YYYY-MM-DD
          'due_date': dueDate.toIso8601String().split('T')[0],
          'status': 'Pending',
          'payment_method': defaultMethod,
        });
      }

      await _client.from('payments').insert(rows);
    } catch (e) {
      throw Exception('Failed to create payment plan: $e');
    }
  }

  /// Updates an existing payment installment record.
  Future<void> recordPayment({
    required String paymentId,
    required double amountPaid,
    required String status,
    required String paymentMethod,
  }) async {
    try {
      await _client.from('payments').update({
        'amount_paid': amountPaid,
        'status': status,
        'payment_method': paymentMethod,
      }).eq('id', paymentId);
    } catch (e) {
      throw Exception('Failed to record payment: $e');
    }
  }

  /// Updates an existing payment installment record with full field flexibility.
  Future<void> updatePaymentRecord({
    required String paymentId,
    required double amountDue,
    required double amountPaid,
    required String status,
    required String paymentMethod,
  }) async {
    try {
      await _client.from('payments').update({
        'amount_due': amountDue,
        'amount_paid': amountPaid,
        'status': status,
        'payment_method': paymentMethod,
      }).eq('id', paymentId);
    } catch (e) {
      throw Exception('Failed to update payment record: $e');
    }
  }

  /// Adds an additional custom installment record for an enrollment.
  Future<void> addInstallment({
    required String enrollmentId,
    required double amountDue,
    required DateTime dueDate,
    String status = 'Pending',
    String? paymentMethod,
  }) async {
    try {
      await _client.from('payments').insert({
        'enrollment_id': enrollmentId,
        'amount_due': amountDue,
        'amount_paid': 0.0,
        'due_date': dueDate.toIso8601String().split('T')[0],
        'status': status,
        'payment_method': paymentMethod,
      });
    } catch (e) {
      throw Exception('Failed to add installment: $e');
    }
  }

  /// Deletes an installment record.
  Future<void> deleteInstallment(String paymentId) async {
    try {
      await _client.from('payments').delete().eq('id', paymentId);
    } catch (e) {
      throw Exception('Failed to delete installment: $e');
    }
  }

  /// Uploads a generated PDF receipt to Supabase Storage bucket 'contracts' (under receipts/)
  /// and updates the database row with the public URL and generation timestamp.
  Future<String> uploadReceiptPdf({
    required String paymentId,
    required String enrollmentId,
    required Uint8List pdfBytes,
  }) async {
    try {
      final fileName = 'receipts/${enrollmentId}_${paymentId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await _client.storage.from('contracts').uploadBinary(
            fileName,
            pdfBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );

      final publicUrl = _client.storage.from('contracts').getPublicUrl(fileName);
      final now = DateTime.now();

      try {
        await _client.from('payments').update({
          'receipt_url': publicUrl,
          'receipt_generated_at': now.toIso8601String(),
        }).eq('id', paymentId);
      } catch (_) {}

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload receipt PDF: $e');
    }
  }
}

@riverpod
PaymentRepository paymentRepository(Ref ref) {
  return PaymentRepository(Supabase.instance.client);
}
