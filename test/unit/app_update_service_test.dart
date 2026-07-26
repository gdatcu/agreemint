import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/services/app_update_service.dart';

void main() {
  group('AppUpdateService Version Comparison Unit Tests', () {
    test('isVersionHigher identifies higher patch version', () {
      expect(AppUpdateService.isVersionHigher('1.0.9', '1.0.8'), true);
      expect(AppUpdateService.isVersionHigher('1.0.8', '1.0.9'), false);
    });

    test('isVersionHigher identifies higher minor version', () {
      expect(AppUpdateService.isVersionHigher('1.1.0', '1.0.9'), true);
      expect(AppUpdateService.isVersionHigher('1.0.9', '1.1.0'), false);
    });

    test('isVersionHigher identifies higher major version', () {
      expect(AppUpdateService.isVersionHigher('2.0.0', '1.9.9'), true);
      expect(AppUpdateService.isVersionHigher('1.9.9', '2.0.0'), false);
    });

    test('isVersionHigher returns false for equal versions', () {
      expect(AppUpdateService.isVersionHigher('1.0.9', '1.0.9'), false);
    });
  });
}
