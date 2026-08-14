import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';

part 'payment_controller.g.dart';

@riverpod
class EnrollmentPaymentsController extends _$EnrollmentPaymentsController {
  @override
  Future<List<PaymentModel>> build(String enrollmentId) async {
    return ref
        .watch(paymentRepositoryProvider)
        .fetchPaymentsForEnrollment(enrollmentId);
  }

  /// Generates a schedule of payments, refreshing local state and invalidating the global dashboard.
  Future<void> generatePlan({
    required double totalAmount,
    required int numberOfInstallments,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.createPaymentPlan(
        enrollmentId: enrollmentId,
        totalAmount: totalAmount,
        numberOfInstallments: numberOfInstallments,
      );

      // Invalidate the global pending payments controller to refresh the dashboard
      ref.invalidate(globalPendingPaymentsControllerProvider);

      return repository.fetchPaymentsForEnrollment(enrollmentId);
    });
  }

  /// Logs a payment update, refreshing local state and invalidating the global dashboard.
  Future<void> logPayment({
    required String paymentId,
    required double amountPaid,
    required String status,
    required String paymentMethod,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.recordPayment(
        paymentId: paymentId,
        amountPaid: amountPaid,
        status: status,
        paymentMethod: paymentMethod,
      );

      // Invalidate the global pending payments controller to refresh the dashboard
      ref.invalidate(globalPendingPaymentsControllerProvider);

      return repository.fetchPaymentsForEnrollment(enrollmentId);
    });
  }

  /// Adds an extra custom installment record.
  Future<void> addExtraInstallment({
    required double amountDue,
    required DateTime dueDate,
    String? paymentMethod,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.addInstallment(
        enrollmentId: enrollmentId,
        amountDue: amountDue,
        dueDate: dueDate,
        paymentMethod: paymentMethod,
      );
      ref.invalidate(globalPendingPaymentsControllerProvider);
      return repository.fetchPaymentsForEnrollment(enrollmentId);
    });
  }

  /// Deletes an installment record.
  Future<void> deleteInstallment(String paymentId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.deleteInstallment(paymentId);
      ref.invalidate(globalPendingPaymentsControllerProvider);
      return repository.fetchPaymentsForEnrollment(enrollmentId);
    });
  }

  /// Saves external SOLO invoice details for an installment.
  Future<void> saveExternalInvoice({
    required String paymentId,
    required String invoiceNumber,
    String? invoiceUrl,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(paymentRepositoryProvider);
      await repository.updateExternalInvoice(
        paymentId: paymentId,
        invoiceNumber: invoiceNumber,
        invoiceUrl: invoiceUrl,
      );
      ref.invalidate(globalPendingPaymentsControllerProvider);
      return repository.fetchPaymentsForEnrollment(enrollmentId);
    });
  }

  /// Uploads SOLO invoice PDF bytes to Supabase storage and links it to the payment.
  Future<String> uploadSoloInvoicePdf({
    required String paymentId,
    required String invoiceNumber,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    final repository = ref.read(paymentRepositoryProvider);
    final url = await repository.uploadSoloInvoicePdf(
      paymentId: paymentId,
      invoiceNumber: invoiceNumber,
      pdfBytes: pdfBytes,
      fileName: fileName,
    );
    ref.invalidate(globalPendingPaymentsControllerProvider);
    ref.invalidateSelf();
    return url;
  }
}

@riverpod
class GlobalPendingPaymentsController extends _$GlobalPendingPaymentsController {
  @override
  Future<List<PaymentModel>> build() async {
    return ref.watch(paymentRepositoryProvider).fetchGlobalPendingPayments();
  }
}
