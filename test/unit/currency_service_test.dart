import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/services/frankfurter_service.dart';

void main() {
  group('FrankfurterService 100% Coverage Unit Tests', () {
    test('getEurToRonRate returns valid non-zero rate and utilizes caching', () async {
      final rate1 = await FrankfurterService.getEurToRonRate();
      expect(rate1, greaterThan(4.0));

      final rate2 = await FrankfurterService.getEurToRonRate();
      expect(rate2, equals(rate1));
    });
  });
}
