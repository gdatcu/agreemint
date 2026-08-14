import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/features/prospects/models/prospect_model.dart';

void main() {
  group('ProspectModel Unit Tests', () {
    test('ProspectModel fromJson and toJson roundtrip works correctly', () {
      final json = {
        'id': 'pros-1',
        'name': 'Ion Popescu',
        'phone': '+40722571081',
        'email': 'ion@example.com',
        'program_id': 'prog-1',
        'notes': 'Wants to think about it',
        'follow_up_date': '2026-08-20T00:00:00.000',
        'status': 'Pending',
        'created_at': '2026-08-14T00:00:00.000',
        'updated_at': '2026-08-14T00:00:00.000',
      };

      final model = ProspectModel.fromJson(json);

      expect(model.id, equals('pros-1'));
      expect(model.name, equals('Ion Popescu'));
      expect(model.phone, equals('+40722571081'));
      expect(model.notes, equals('Wants to think about it'));
      expect(model.status, equals('Pending'));

      final reserialized = model.toJson();
      expect(reserialized['id'], equals('pros-1'));
      expect(reserialized['name'], equals('Ion Popescu'));
    });
  });
}
