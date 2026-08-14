import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/services/notification_service.dart';
import 'package:agreemint/features/payments/models/payment_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Unit Tests', () {
    test('checkAndNotifyOverduePayments evaluates list without errors', () async {
      final payments = [
        PaymentModel(
          id: 'pay-1',
          enrollmentId: 'enr-1',
          amountDue: 500.0,
          amountPaid: 0.0,
          status: 'Pending',
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
        PaymentModel(
          id: 'pay-2',
          enrollmentId: 'enr-1',
          amountDue: 500.0,
          amountPaid: 500.0,
          status: 'Paid',
          dueDate: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ];

      await expectLater(
        NotificationService.checkAndNotifyOverduePayments(payments),
        completes,
      );
    });

    test('checkAndNotifyOverduePayments handles empty list cleanly', () async {
      await expectLater(
        NotificationService.checkAndNotifyOverduePayments([]),
        completes,
      );
    });
  });
}
