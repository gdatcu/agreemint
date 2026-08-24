import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/services/whatsapp_service.dart';

void main() {
  group('WhatsAppService Unit Tests', () {
    test('cleanPhoneNumber formats Romanian 07xx numbers correctly', () {
      expect(WhatsAppService.cleanPhoneNumber('0712345678'), equals('40712345678'));
      expect(WhatsAppService.cleanPhoneNumber('0712 345 678'), equals('40712345678'));
      expect(WhatsAppService.cleanPhoneNumber('+40712345678'), equals('40712345678'));
      expect(WhatsAppService.cleanPhoneNumber('40712345678'), equals('40712345678'));
      expect(WhatsAppService.cleanPhoneNumber('+1 (555) 123-4567'), equals('15551234567'));
    });

    test('cleanPhoneNumber handles dashes, plus, and spaces', () {
      expect(WhatsAppService.cleanPhoneNumber('+40 712-345-678'), equals('40712345678'));
    });

    test('buildPaymentReminderMessage formats message with contract and invoice links', () {
      final msgWithLinks = WhatsAppService.buildPaymentReminderMessage(
        name: 'George Test',
        amount: 1000.0,
        dueDate: '2026-08-24',
        currency: 'RON',
        contractUrl: 'https://agreemint.qualiadept.eu/#/sign/abc-123',
        invoiceUrl: 'https://agreemint.qualiadept.eu/#/view-doc?url=inv_1&pin=5678&title=Factura',
        invoiceNumber: '1024',
        programName: 'Flutter Masterclass',
        studentPhone: '0712345678',
      );

      expect(msgWithLinks, contains('Salut *George Test*'));
      expect(msgWithLinks, contains('1000.00 RON'));
      expect(msgWithLinks, contains('• ✍️ *Contract Semnat:* https://agreemint.qualiadept.eu/#/sign/abc-123'));
      expect(msgWithLinks, contains('• 🧾 *Factură Fiscală (SOLO #1024):* https://agreemint.qualiadept.eu/#/view-doc?url=inv_1&pin=5678&title=Factura'));
      expect(msgWithLinks, contains('🔐 *PIN Deblocare Factură:* Ultimele 4 cifre ale numărului tău de telefon (*5678*)'));
      expect(msgWithLinks, contains('✉️ *Acces Securizat Contract:* Necesită validare prin cod OTP expediat pe email'));
      expect(msgWithLinks, contains('Flutter Masterclass'));
    });

    test('buildPaymentReminderMessage works cleanly without optional links', () {
      final msgPlain = WhatsAppService.buildPaymentReminderMessage(
        name: 'George Test',
        amount: 1000.0,
        dueDate: '2026-08-24',
      );

      expect(msgPlain, contains('Salut *George Test*'));
      expect(msgPlain, contains('1000.00 RON'));
      expect(msgPlain, isNot(contains('Documente & Detalii de Plată')));
    });

    test('formatRelativeDueText formats today, tomorrow, future days, yesterday, and overdue', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final inThreeDays = today.add(const Duration(days: 3));
      final yesterday = today.subtract(const Duration(days: 1));
      final fiveDaysAgo = today.subtract(const Duration(days: 5));

      final todayStr = today.toIso8601String().split('T')[0];
      final tomorrowStr = tomorrow.toIso8601String().split('T')[0];
      final inThreeDaysStr = inThreeDays.toIso8601String().split('T')[0];
      final yesterdayStr = yesterday.toIso8601String().split('T')[0];
      final fiveDaysAgoStr = fiveDaysAgo.toIso8601String().split('T')[0];

      expect(WhatsAppService.formatRelativeDueText(todayStr, today), contains('scadența *astăzi'));
      expect(WhatsAppService.formatRelativeDueText(tomorrowStr, tomorrow), contains('scadența *mâine'));
      expect(WhatsAppService.formatRelativeDueText(inThreeDaysStr, inThreeDays), contains('scadența în *3 zile*'));
      expect(WhatsAppService.formatRelativeDueText(yesterdayStr, yesterday), contains('scadența *ieri'));
      expect(WhatsAppService.formatRelativeDueText(fiveDaysAgoStr, fiveDaysAgo), contains('depășit termenul de scadență cu *5 zile*'));
    });
  });
}
