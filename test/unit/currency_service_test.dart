import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/services/frankfurter_service.dart';

void main() {
  group('FrankfurterService Unit Tests', () {
    test('getEurToRonRate returns a valid non-zero rate', () async {
      final rate = await FrankfurterService.getEurToRonRate();
      expect(rate, isNotNull);
      expect(rate, greaterThan(4.0));
      expect(rate, lessThan(6.0));
    });
  });
}
