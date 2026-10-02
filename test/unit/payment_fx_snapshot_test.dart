import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/features/payments/models/payment_model.dart';

void main() {
  group('PaymentModel FX Rate Snapshotting Tests [F-02]', () {
    test('PaymentModel parses fx_rate_snapshot and fx_rate_date correctly from JSON', () {
      final json = {
        'id': 'pay_123',
        'enrollment_id': 'enr_456',
        'amount_due': 500.0,
        'amount_paid': 500.0,
        'due_date': '2026-10-01',
        'status': 'Paid',
        'payment_method': 'Bank Transfer',
        'fx_rate_snapshot': 4.9745,
        'fx_rate_date': '2026-10-01T10:00:00Z',
      };

      final payment = PaymentModel.fromJson(json);

      expect(payment.id, 'pay_123');
      expect(payment.amountDue, 500.0);
      expect(payment.amountPaid, 500.0);
      expect(payment.fxRateSnapshot, 4.9745);
      expect(payment.fxRateDate, isNotNull);
      expect(payment.fxRateDate!.year, 2026);
      expect(payment.fxRateDate!.month, 10);
      expect(payment.fxRateDate!.day, 1);
    });

    test('PaymentModel toJson serializes fx_rate_snapshot and fx_rate_date properly', () {
      final payment = PaymentModel(
        id: 'pay_789',
        enrollmentId: 'enr_789',
        amountDue: 1000.0,
        amountPaid: 0.0,
        dueDate: DateTime(2026, 11, 15),
        status: 'Pending',
        fxRateSnapshot: 4.9810,
        fxRateDate: DateTime.parse('2026-10-02T12:00:00Z'),
      );

      final json = payment.toJson();

      expect(json['fx_rate_snapshot'], 4.9810);
      expect(json['fx_rate_date'], contains('2026-10-02T12:00:00'));
    });

    test('Backward compatibility: PaymentModel handles null fx_rate_snapshot gracefully', () {
      final legacyJson = {
        'id': 'legacy_pay_1',
        'enrollment_id': 'enr_1',
        'amount_due': 300.0,
        'amount_paid': 300.0,
        'due_date': '2026-05-01',
        'status': 'Paid',
      };

      final payment = PaymentModel.fromJson(legacyJson);

      expect(payment.fxRateSnapshot, isNull);
      expect(payment.fxRateDate, isNull);
      expect(payment.toJson().containsKey('fx_rate_snapshot'), isFalse);
      expect(payment.toJson().containsKey('fx_rate_date'), isFalse);
    });

    test('getAmountInRon uses locked fxRateSnapshot for EUR programs', () {
      final payment = PaymentModel(
        id: 'pay_locked',
        enrollmentId: 'enr_1',
        amountDue: 1000.0,
        amountPaid: 1000.0,
        dueDate: DateTime.now(),
        status: 'Paid',
        fxRateSnapshot: 4.9500, // Locked at 4.9500
      );

      // Even if fallback live rate is 5.0500, the locked snapshot must be prioritized
      final ron = payment.getAmountInRon(
        currency: 'EUR',
        fallbackLiveRate: 5.0500,
      );

      expect(ron, closeTo(4950.0, 0.001));
    });

    test('getAmountInRon falls back to live rate when fxRateSnapshot is null for EUR', () {
      final payment = PaymentModel(
        id: 'pay_fallback',
        enrollmentId: 'enr_1',
        amountDue: 1000.0,
        amountPaid: 1000.0,
        dueDate: DateTime.now(),
        status: 'Paid',
        fxRateSnapshot: null,
      );

      final ron = payment.getAmountInRon(
        currency: 'EUR',
        fallbackLiveRate: 4.9800,
      );

      expect(ron, closeTo(4980.0, 0.001));
    });

    test('getAmountInRon returns exact amountPaid for RON programs regardless of fxRate', () {
      final payment = PaymentModel(
        id: 'pay_ron',
        enrollmentId: 'enr_1',
        amountDue: 5000.0,
        amountPaid: 5000.0,
        dueDate: DateTime.now(),
        status: 'Paid',
        fxRateSnapshot: 4.9750,
      );

      final ron = payment.getAmountInRon(
        currency: 'RON',
        fallbackLiveRate: 4.9750,
      );

      expect(ron, 5000.0);
    });
  });
}
