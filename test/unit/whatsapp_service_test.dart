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
  });
}
