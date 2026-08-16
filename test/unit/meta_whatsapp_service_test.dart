import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/services/meta_whatsapp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MetaWhatsAppService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveConfig and getConfig roundtrip correctly', () async {
      await MetaWhatsAppService.saveConfig(
        phoneNumberId: '1264011373461547',
        accessToken: 'EAAG...',
        templateName: 'payment_overdue_reminder',
      );

      final config = await MetaWhatsAppService.getConfig();
      expect(config['phoneNumberId'], equals('1264011373461547'));
      expect(config['accessToken'], equals('EAAG...'));
      expect(config['templateName'], equals('payment_overdue_reminder'));
    });
  });
}
