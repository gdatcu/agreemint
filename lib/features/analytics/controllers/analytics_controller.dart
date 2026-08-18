import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/frankfurter_service.dart';

part 'analytics_controller.g.dart';

/// Formats currency amounts cleanly with thousand separators.
String formatCurrencyAmount(double amount, String currency) {
  final parts = amount.toStringAsFixed(2).split('.');
  final integerPart = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
  final formattedNum = '$integerPart.${parts[1]}';

  switch (currency.toUpperCase()) {
    case 'EUR':
      return '$formattedNum EUR';
    case 'RON':
      return '$formattedNum RON';
    case 'USD':
      return '\$$formattedNum';
    default:
      return '$formattedNum $currency';
  }
}

class MonthlyRevenueData {
  final String monthLabel;
  final double collectedInRon;
  final double expectedInRon;
  final int newEnrollments;

  const MonthlyRevenueData({
    required this.monthLabel,
    required this.collectedInRon,
    required this.expectedInRon,
    required this.newEnrollments,
  });
}

class AnalyticsSummary {
  final int totalStudents;
  final Map<String, double> expectedRevenueByCurrency;
  final Map<String, double> revenueCollectedByCurrency;
  final double totalExpectedInRon;
  final double totalCollectedInRon;
  final double liveEurRate;
  final List<MonthlyRevenueData> monthlyBreakdown;

  const AnalyticsSummary({
    required this.totalStudents,
    required this.expectedRevenueByCurrency,
    required this.revenueCollectedByCurrency,
    required this.totalExpectedInRon,
    required this.totalCollectedInRon,
    required this.liveEurRate,
    this.monthlyBreakdown = const [],
  });

  /// Formatted string display for expected revenue per currency.
  String get formattedExpectedRevenue {
    if (expectedRevenueByCurrency.isEmpty) return '0.00 RON';
    final parts = expectedRevenueByCurrency.entries
        .map((e) => formatCurrencyAmount(e.value, e.key))
        .toList();
    return parts.join(' + ');
  }

  /// Formatted string display for collected revenue per currency.
  String get formattedCollectedRevenue {
    if (revenueCollectedByCurrency.isEmpty) return '0.00 RON';
    final parts = revenueCollectedByCurrency.entries
        .map((e) => formatCurrencyAmount(e.value, e.key))
        .toList();
    return parts.join(' + ');
  }

  /// Returns true if EUR is involved or multiple currencies are present.
  bool get hasMultipleCurrenciesOrEur {
    return expectedRevenueByCurrency.length > 1 ||
        expectedRevenueByCurrency.containsKey('EUR') ||
        revenueCollectedByCurrency.containsKey('EUR');
  }

  /// Collection progress ratio between 0.0 and 1.0.
  double get collectionProgress {
    if (totalExpectedInRon <= 0) return 0.0;
    return (totalCollectedInRon / totalExpectedInRon).clamp(0.0, 1.0);
  }

  /// Outstanding balance in RON equivalent.
  double get pendingBalanceInRon {
    final diff = totalExpectedInRon - totalCollectedInRon;
    return diff > 0 ? diff : 0.0;
  }
}

@riverpod
class AnalyticsSummaryController extends _$AnalyticsSummaryController {
  @override
  Future<AnalyticsSummary> build() async {
    try {
      final client = Supabase.instance.client;

      // Fetch live EUR exchange rate from Frankfurter API
      final liveEurRate = await FrankfurterService.getEurToRonRate();

      // 1 & 2. Fetch Active Enrollments, Program Total Price & Currency, and Contract Status
      final enrollmentsResponse = await client
          .from('enrollments')
          .select('id, enrolled_at, created_at, programs(total_price, currency), contracts(status)');

      int totalStudents = 0;
      final Map<String, double> expectedRevenueByCurrency = {};
      final Map<String, int> monthlyEnrollmentsMap = {};
      final Map<String, double> monthlyExpectedMap = {};

      for (final row in enrollmentsResponse as List<dynamic>) {
        final contractRaw = row['contracts'];
        Map<String, dynamic>? contractJson;
        if (contractRaw is Map<String, dynamic>) {
          contractJson = contractRaw;
        } else if (contractRaw is List && contractRaw.isNotEmpty) {
          contractJson = contractRaw.first as Map<String, dynamic>?;
        }

        final contractStatus = contractJson?['status'] as String?;
        if (contractStatus == 'Refunded' ||
            contractStatus == 'Cancelled' ||
            contractStatus == 'Retired' ||
            contractStatus == 'Withdrawn' ||
            contractStatus == 'Archived') {
          continue;
        }

        totalStudents++;

        // Track enrollment month
        final dateStr = (row['enrolled_at'] as String?) ?? (row['created_at'] as String?);
        if (dateStr != null && dateStr.length >= 7) {
          final monthKey = dateStr.substring(0, 7); // e.g. "2026-08"
          monthlyEnrollmentsMap[monthKey] = (monthlyEnrollmentsMap[monthKey] ?? 0) + 1;
        }

        final programRaw = row['programs'];
        Map<String, dynamic>? programJson;
        if (programRaw is Map<String, dynamic>) {
          programJson = programRaw;
        } else if (programRaw is List && programRaw.isNotEmpty) {
          programJson = programRaw.first as Map<String, dynamic>?;
        }

        if (programJson != null) {
          final price = (programJson['total_price'] as num?)?.toDouble() ?? 0.0;
          final currency =
              (programJson['currency'] as String? ?? 'RON').toUpperCase();
          expectedRevenueByCurrency[currency] =
              (expectedRevenueByCurrency[currency] ?? 0.0) + price;

          final priceInRon = currency == 'EUR' ? price * liveEurRate : price;
          if (dateStr != null && dateStr.length >= 7) {
            final monthKey = dateStr.substring(0, 7);
            monthlyExpectedMap[monthKey] = (monthlyExpectedMap[monthKey] ?? 0.0) + priceInRon;
          }
        }
      }

      // 3. Fetch Revenue Collected per currency from payments -> enrollments -> programs (excluding refunded/retired)
      final paymentsResponse = await client
          .from('payments')
          .select(
              'amount_paid, paid_at, due_date, status, enrollments(programs(currency), contracts(status))')
          .or('status.eq.Paid,status.eq.Partial');

      final Map<String, double> revenueCollectedByCurrency = {};
      final Map<String, double> monthlyCollectedMap = {};

      for (final row in paymentsResponse as List<dynamic>) {
        final enrollmentRaw = row['enrollments'];
        Map<String, dynamic>? enrollmentJson;
        if (enrollmentRaw is Map<String, dynamic>) {
          enrollmentJson = enrollmentRaw;
        } else if (enrollmentRaw is List && enrollmentRaw.isNotEmpty) {
          enrollmentJson = enrollmentRaw.first as Map<String, dynamic>?;
        }

        if (enrollmentJson != null) {
          final contractRaw = enrollmentJson['contracts'];
          Map<String, dynamic>? contractJson;
          if (contractRaw is Map<String, dynamic>) {
            contractJson = contractRaw;
          } else if (contractRaw is List && contractRaw.isNotEmpty) {
            contractJson = contractRaw.first as Map<String, dynamic>?;
          }

          final contractStatus = contractJson?['status'] as String?;
          if (contractStatus == 'Refunded' ||
              contractStatus == 'Cancelled' ||
              contractStatus == 'Retired' ||
              contractStatus == 'Withdrawn' ||
              contractStatus == 'Archived') {
            continue;
          }

          String currency = 'RON';
          final programRaw = enrollmentJson['programs'];
          Map<String, dynamic>? programJson;
          if (programRaw is Map<String, dynamic>) {
            programJson = programRaw;
          } else if (programRaw is List && programRaw.isNotEmpty) {
            programJson = programRaw.first as Map<String, dynamic>?;
          }

          if (programJson != null && programJson['currency'] != null) {
            currency = (programJson['currency'] as String).toUpperCase();
          }

          final amount = (row['amount_paid'] as num?)?.toDouble() ?? 0.0;
          revenueCollectedByCurrency[currency] =
              (revenueCollectedByCurrency[currency] ?? 0.0) + amount;

          final amountInRon = currency == 'EUR' ? amount * liveEurRate : amount;
          final payDateStr = (row['paid_at'] as String?) ?? (row['due_date'] as String?);
          if (payDateStr != null && payDateStr.length >= 7) {
            final monthKey = payDateStr.substring(0, 7);
            monthlyCollectedMap[monthKey] = (monthlyCollectedMap[monthKey] ?? 0.0) + amountInRon;
          }
        }
      }

      // 4. Calculate total expected & collected in RON equivalent
      double totalExpectedInRon = 0.0;
      expectedRevenueByCurrency.forEach((curr, amount) {
        if (curr == 'EUR') {
          totalExpectedInRon += amount * liveEurRate;
        } else {
          totalExpectedInRon += amount;
        }
      });

      double totalCollectedInRon = 0.0;
      revenueCollectedByCurrency.forEach((curr, amount) {
        if (curr == 'EUR') {
          totalCollectedInRon += amount * liveEurRate;
        } else {
          totalCollectedInRon += amount;
        }
      });

      // 5. Generate 6-month breakdown list
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final now = DateTime.now();
      final List<MonthlyRevenueData> monthlyBreakdown = [];

      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        final yearStr = d.year.toString();
        final mNumStr = d.month.toString().padLeft(2, '0');
        final monthKey = '$yearStr-$mNumStr';
        final monthLabel = '${monthNames[d.month - 1]} ${d.year.toString().substring(2)}';

        monthlyBreakdown.add(MonthlyRevenueData(
          monthLabel: monthLabel,
          collectedInRon: monthlyCollectedMap[monthKey] ?? 0.0,
          expectedInRon: monthlyExpectedMap[monthKey] ?? 0.0,
          newEnrollments: monthlyEnrollmentsMap[monthKey] ?? 0,
        ));
      }

      return AnalyticsSummary(
        totalStudents: totalStudents,
        expectedRevenueByCurrency: expectedRevenueByCurrency,
        revenueCollectedByCurrency: revenueCollectedByCurrency,
        totalExpectedInRon: totalExpectedInRon,
        totalCollectedInRon: totalCollectedInRon,
        liveEurRate: liveEurRate,
        monthlyBreakdown: monthlyBreakdown,
      );
    } catch (e) {
      throw Exception('Failed to calculate analytics metrics: $e');
    }
  }
}
