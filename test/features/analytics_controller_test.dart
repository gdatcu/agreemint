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

  group('AnalyticsSummary Comprehensive Unit Tests', () {
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
      expect(summary.hasMultipleCurrenciesOrEur, isTrue);
      expect(summary.collectionProgress, closeTo(0.20, 0.01));
      expect(summary.pendingBalanceInRon, equals(5975.0));
    });

    test('returns 0.00 RON for empty expected revenue and zero progress', () {
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
      expect(summary.hasMultipleCurrenciesOrEur, isFalse);
      expect(summary.collectionProgress, equals(0.0));
      expect(summary.pendingBalanceInRon, equals(0.0));
    });

    test('pendingBalanceInRon returns 0 when collected exceeds expected', () {
      const summary = AnalyticsSummary(
        totalStudents: 5,
        expectedRevenueByCurrency: {'RON': 1000.0},
        revenueCollectedByCurrency: {'RON': 1200.0},
        totalExpectedInRon: 1000.0,
        totalCollectedInRon: 1200.0,
        liveEurRate: 4.975,
      );

      expect(summary.collectionProgress, equals(1.0));
      expect(summary.pendingBalanceInRon, equals(0.0));
    });

    test('MonthlyRevenueData initializes correctly with monthlyBreakdown', () {
      const item = MonthlyRevenueData(
        monthLabel: 'Aug 26',
        collectedInRon: 5500.0,
        expectedInRon: 19000.0,
        newEnrollments: 19,
      );

      const summary = AnalyticsSummary(
        totalStudents: 19,
        expectedRevenueByCurrency: {'RON': 19000.0},
        revenueCollectedByCurrency: {'RON': 5500.0},
        totalExpectedInRon: 19000.0,
        totalCollectedInRon: 5500.0,
        liveEurRate: 4.975,
        monthlyBreakdown: [item],
      );

      expect(summary.monthlyBreakdown.length, 1);
      expect(summary.monthlyBreakdown.first.monthLabel, 'Aug 26');
      expect(summary.monthlyBreakdown.first.collectedInRon, 5500.0);
      expect(summary.monthlyBreakdown.first.newEnrollments, 19);
    });
  });
}
