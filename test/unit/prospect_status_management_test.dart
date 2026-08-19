import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/features/prospects/models/prospect_model.dart';

void main() {
  group('ProspectStatusManagement Unit Tests', () {
    test('ProspectModel copyWith updates status, followUpDate, and notes cleanly', () {
      final initial = ProspectModel(
        id: 'p1',
        name: 'Ion Popescu',
        phone: '+40722111222',
        email: 'ion@example.com',
        followUpDate: DateTime(2026, 8, 15),
        status: 'Pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(initial.status, equals('Pending'));

      final updated = initial.copyWith(
        status: 'Contacted',
        notes: 'Called, agreed for next cohort',
        followUpDate: DateTime(2026, 8, 22),
      );

      expect(updated.status, equals('Contacted'));
      expect(updated.notes, equals('Called, agreed for next cohort'));
      expect(updated.followUpDate, equals(DateTime(2026, 8, 22)));
    });

    test('ProspectModel parses Contacted and Lost status from JSON', () {
      final jsonContacted = {
        'id': 'p2',
        'name': 'Maria Popa',
        'follow_up_date': '2026-08-25T10:00:00.000Z',
        'status': 'Contacted',
      };

      final jsonLost = {
        'id': 'p3',
        'name': 'Andrei Ionescu',
        'follow_up_date': '2026-08-10T10:00:00.000Z',
        'status': 'Lost',
      };

      final p2 = ProspectModel.fromJson(jsonContacted);
      final p3 = ProspectModel.fromJson(jsonLost);

      expect(p2.status, equals('Contacted'));
      expect(p3.status, equals('Lost'));
    });
  });
}
