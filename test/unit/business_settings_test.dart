import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/features/settings/models/business_settings_model.dart';

void main() {
  group('BusinessSettingsModel Unit Tests', () {
    test('Default constructor provides valid PFA fallback values', () {
      const model = BusinessSettingsModel();

      expect(model.companyName,
          contains('DATCU GEORGE-CRISTIAN PERSOANA FIZICĂ AUTORIZATĂ'));
      expect(model.cuiCif, equals('53430793'));
      expect(model.regCom, equals('F2026003426005'));
      expect(model.iban, equals('RO54ROIN4021Q3YWTH1KTUTH'));
      expect(model.bankName, equals('Salt Bank'));
      expect(model.mentorSignatureBytes, isNull);
    });

    test('toJson and fromJson roundtrip correctly', () {
      final original = const BusinessSettingsModel(
        companyName: 'Custom Tech SRL',
        cuiCif: 'RO12345678',
        regCom: 'J40/123/2026',
        iban: 'RO99TEST1234567890123456',
        bankName: 'ING Bank',
        mentorSignatureBase64: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );

      final json = original.toJson();
      final restored = BusinessSettingsModel.fromJson(json);

      expect(restored.companyName, equals('Custom Tech SRL'));
      expect(restored.cuiCif, equals('RO12345678'));
      expect(restored.regCom, equals('J40/123/2026'));
      expect(restored.iban, equals('RO99TEST1234567890123456'));
      expect(restored.bankName, equals('ING Bank'));
      expect(restored.mentorSignatureBytes, isNotNull);
      expect(restored.mentorSignatureBytes!.length, greaterThan(0));
    });

    test('copyWith modifies targeted fields cleanly', () {
      const initial = BusinessSettingsModel();
      final updated = initial.copyWith(
        companyName: 'Updated Mentorship PFA',
        iban: 'RO88NEWIBAN12345',
      );

      expect(updated.companyName, equals('Updated Mentorship PFA'));
      expect(updated.iban, equals('RO88NEWIBAN12345'));
      expect(updated.cuiCif, equals(initial.cuiCif));
    });
  });
}
