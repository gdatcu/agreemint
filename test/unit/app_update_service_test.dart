import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/services/app_update_service.dart';

void main() {
  group('AppUpdateService Version Comparison & Model Unit Tests', () {
    test('AppUpdateInfo instantiates correctly', () {
      final info = AppUpdateInfo(
        latestVersion: 'v1.1.0',
        releaseNotes: 'New features added',
        apkDownloadUrl: 'https://github.com/gdatcu/agreemint/releases/download/v1.1.0/app-release.apk',
        releaseUrl: 'https://github.com/gdatcu/agreemint/releases/tag/v1.1.0',
        hasUpdate: true,
        currentVersion: '1.0.10',
      );

      expect(info.latestVersion, 'v1.1.0');
      expect(info.releaseNotes, 'New features added');
      expect(info.hasUpdate, isTrue);
      expect(info.currentVersion, '1.0.10');
    });

    test('isVersionHigher identifies higher patch version', () {
      expect(AppUpdateService.isVersionHigher('1.0.11', '1.0.10'), isTrue);
    });

    test('isVersionHigher identifies higher minor version', () {
      expect(AppUpdateService.isVersionHigher('1.1.0', '1.0.10'), isTrue);
    });

    test('isVersionHigher identifies higher major version', () {
      expect(AppUpdateService.isVersionHigher('2.0.0', '1.0.10'), isTrue);
    });

    test('isVersionHigher returns false for equal versions', () {
      expect(AppUpdateService.isVersionHigher('1.0.10', '1.0.10'), isFalse);
    });

    test('isVersionHigher returns false for lower versions', () {
      expect(AppUpdateService.isVersionHigher('1.0.9', '1.0.10'), isFalse);
    });
  });
}
