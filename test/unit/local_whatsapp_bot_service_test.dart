import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/services/local_whatsapp_bot_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalWhatsAppBotService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveServerUrl and getServerUrl roundtrip correctly', () async {
      await LocalWhatsAppBotService.saveServerUrl('http://localhost:3000');
      final url = await LocalWhatsAppBotService.getServerUrl();
      expect(url, equals('http://localhost:3000'));
    });

    test('checkStatus returns UNREACHABLE when no server is running', () async {
      final status = await LocalWhatsAppBotService.checkStatus();
      expect(status['status'], equals('UNREACHABLE'));
      expect(status['authenticated'], isFalse);
    });
  });
}
