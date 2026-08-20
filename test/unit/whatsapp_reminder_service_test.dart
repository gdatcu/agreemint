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

    test('buildReminderMessage constructs polite Romanian reminder string with formatting', () {
      final msgOverdue = WhatsAppReminderService.buildReminderMessage(
        studentName: 'Ion Popescu',
        programName: 'Web Development',
        amount: 500.0,
        currency: 'RON',
        dueDateStr: '2026-08-14',
        isDueTomorrow: false,
      );

      expect(msgOverdue, contains('*Ion Popescu*'));
      expect(msgOverdue, contains('*500.00 RON*'));
      expect(msgOverdue, contains('*Web Development*'));
      expect(msgOverdue, contains('*2026-08-14*'));
      expect(msgOverdue, contains('QualiAdept Billing'));

      final msgTomorrow = WhatsAppReminderService.buildReminderMessage(
        studentName: 'Ion Popescu',
        programName: 'Web Development',
        amount: 500.0,
        currency: 'RON',
        dueDateStr: '2026-08-17',
        dueStage: 'tomorrow',
      );

      expect(msgTomorrow, contains('*mâine, 2026-08-17*'));

      final msgToday = WhatsAppReminderService.buildReminderMessage(
        studentName: 'Ion Popescu',
        programName: 'Web Development',
        amount: 500.0,
        currency: 'RON',
        dueDateStr: '2026-08-16',
        dueStage: 'today',
        invoiceUrl: 'https://example.com/invoice.pdf',
        invoiceNumber: 'SOLO-1042',
        contractPdfUrl: 'https://example.com/contract.pdf',
      );

      expect(msgToday, contains('*astăzi, 2026-08-16*'));
      expect(msgToday, contains('https://agreemint.qualiadept.eu/#/view-doc?url=https%3A%2F%2Fexample.com%2Finvoice.pdf'));
      expect(msgToday, contains('https://agreemint.qualiadept.eu/#/view-doc?url=https%3A%2F%2Fexample.com%2Fcontract.pdf'));
    });

    test('buildContractFollowUpMessage constructs polite contract follow-up string', () {
      final msg = WhatsAppReminderService.buildContractFollowUpMessage(
        studentName: 'Ana Maria',
        programName: 'QA Automation',
        createdDateStr: '2026-08-10',
        contractSigningUrl: 'https://example.com/sign-contract.pdf',
      );

      expect(msg, contains('*Ana Maria*'));
      expect(msg, contains('*QA Automation*'));
      expect(msg, contains('2026-08-10'));
      expect(msg, contains('https://example.com/sign-contract.pdf'));
      expect(msg, contains('🔔 *[QualiAdept Contract Follow-Up]*'));
    });
  });
}
