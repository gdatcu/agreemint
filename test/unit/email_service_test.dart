import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/services/email_service.dart';

void main() {
  group('EmailService Unit Tests', () {
    test('EmailService instantiation with API key', () {
      const service = EmailService(apiKey: 're_test_123');
      expect(service.apiKey, equals('re_test_123'));
    });

    test('sendContractLink throws when recipient email is empty or invalid', () async {
      const service = EmailService(apiKey: 're_test_123');
      expect(
        () => service.sendContractLink(email: '', name: 'George', url: 'https://agreemint.eu/sign'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => service.sendContractLink(email: 'notanemail', name: 'George', url: 'https://agreemint.eu/sign'),
        throwsA(isA<Exception>()),
      );
    });

    test('sendPaymentReminder throws when API key is empty', () async {
      const service = EmailService(apiKey: '');
      expect(
        () => service.sendPaymentReminder(
          email: 'student@example.com',
          name: 'George',
          amount: 500.0,
          dueDate: '2026-09-01',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('sendPaymentReceipt throws when API key is empty', () async {
      const service = EmailService(apiKey: '');
      expect(
        () => service.sendPaymentReceipt(
          email: 'student@example.com',
          name: 'George',
          amount: 500.0,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('formatRelativeDueTextHtml formats today, tomorrow, future days, yesterday, and overdue', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final inThreeDays = today.add(const Duration(days: 3));
      final yesterday = today.subtract(const Duration(days: 1));
      final fourDaysAgo = today.subtract(const Duration(days: 4));

      final todayStr = today.toIso8601String().split('T')[0];
      final tomorrowStr = tomorrow.toIso8601String().split('T')[0];
      final inThreeDaysStr = inThreeDays.toIso8601String().split('T')[0];
      final yesterdayStr = yesterday.toIso8601String().split('T')[0];
      final fourDaysAgoStr = fourDaysAgo.toIso8601String().split('T')[0];

      expect(EmailService.formatRelativeDueTextHtml(todayStr, today), contains('scadența <strong>astăzi'));
      expect(EmailService.formatRelativeDueTextHtml(tomorrowStr, tomorrow), contains('scadența <strong>mâine'));
      expect(EmailService.formatRelativeDueTextHtml(inThreeDaysStr, inThreeDays), contains('scadența în <strong>3 zile</strong>'));
      expect(EmailService.formatRelativeDueTextHtml(yesterdayStr, yesterday), contains('scadența <strong>ieri'));
      expect(EmailService.formatRelativeDueTextHtml(fourDaysAgoStr, fourDaysAgo), contains('depășit termenul de scadență cu <strong>4 zile</strong>'));
    });
  });
}
