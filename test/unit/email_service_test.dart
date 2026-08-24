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
  });
}
