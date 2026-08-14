import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/services/whatsapp_reminder_service.dart';

void main() {
  group('WhatsAppReminderService Unit Tests', () {
    test('cleanPhoneNumber formats Romanian 07xx numbers correctly', () {
      expect(WhatsAppReminderService.cleanPhoneNumber('0722571081'), equals('40722571081'));
      expect(WhatsAppReminderService.cleanPhoneNumber('+40722571081'), equals('40722571081'));
      expect(WhatsAppReminderService.cleanPhoneNumber('+40 722 571 081'), equals('40722571081'));
      expect(WhatsAppReminderService.cleanPhoneNumber('40722571081'), equals('40722571081'));
    });

    test('buildReminderMessage constructs polite Romanian reminder string', () {
      final msg = WhatsAppReminderService.buildReminderMessage(
        studentName: 'Ion Popescu',
        programName: 'Web Development',
        amount: 500.0,
        currency: 'RON',
        dueDateStr: '2026-08-14',
      );

      expect(msg, contains('Ion Popescu'));
      expect(msg, contains('500.00 RON'));
      expect(msg, contains('Web Development'));
      expect(msg, contains('2026-08-14'));
      expect(msg, contains('Salut Ion Popescu! Îți reamintesc că plata tranșei de 500.00 RON'));
    });
  });
}
