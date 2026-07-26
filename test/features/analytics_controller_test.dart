import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/features/analytics/controllers/analytics_controller.dart';

void main() {
  group('formatCurrencyAmount Unit Tests', () {
    test('formats EUR currency with suffix', () {
      expect(formatCurrencyAmount(1250.50, 'EUR'), '1,250.50 EUR');
    });

    test('formats RON currency with suffix', () {
      expect(formatCurrencyAmount(5000.00, 'RON'), '5,000.00 RON');
    });

    test('formats USD currency with prefix', () {
      expect(formatCurrencyAmount(99.99, 'USD'), '\$99.99');
    });

    test('formats default currency fallback', () {
      expect(formatCurrencyAmount(100.00, 'GBP'), '100.00 GBP');
    });
  });

  group('AnalyticsSummary Formatting Tests', () {
    test('formattedExpectedRevenue joins multiple currencies with +', () {
      const summary = AnalyticsSummary(
        totalStudents: 10,
        expectedRevenueByCurrency: {
          'EUR': 1000.0,
          'RON': 2500.0,
        },
        revenueCollectedByCurrency: {
          'RON': 1500.0,
        },
        totalExpectedInRon: 7475.0,
        totalCollectedInRon: 1500.0,
        liveEurRate: 4.975,
      );

      expect(summary.formattedExpectedRevenue, '1,000.00 EUR + 2,500.00 RON');
      expect(summary.formattedCollectedRevenue, '1,500.00 RON');
    });

    test('returns 0.00 RON for empty expected revenue', () {
      const summary = AnalyticsSummary(
        totalStudents: 0,
        expectedRevenueByCurrency: {},
        revenueCollectedByCurrency: {},
        totalExpectedInRon: 0.0,
        totalCollectedInRon: 0.0,
        liveEurRate: 4.975,
      );

      expect(summary.formattedExpectedRevenue, '0.00 RON');
      expect(summary.formattedCollectedRevenue, '0.00 RON');
    });
  });
}
