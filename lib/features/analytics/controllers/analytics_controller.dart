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

class AnalyticsSummary {
  final int totalStudents;
  final Map<String, double> expectedRevenueByCurrency;
  final Map<String, double> revenueCollectedByCurrency;
  final double totalExpectedInRon;
  final double totalCollectedInRon;
  final double liveEurRate;

  const AnalyticsSummary({
    required this.totalStudents,
    required this.expectedRevenueByCurrency,
    required this.revenueCollectedByCurrency,
    required this.totalExpectedInRon,
    required this.totalCollectedInRon,
    required this.liveEurRate,
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

      // 1. Fetch Total Enrolled Students
      final studentsResponse = await client.from('students').select('id');
      final totalStudents = (studentsResponse as List<dynamic>).length;

      // 2. Fetch Expected Revenue per currency from enrollments -> programs (excluding refunded/cancelled contracts)
      final enrollmentsResponse = await client
          .from('enrollments')
          .select('programs(total_price, currency), contracts(status)');

      final Map<String, double> expectedRevenueByCurrency = {};
      for (final row in enrollmentsResponse as List<dynamic>) {
        final contractRaw = row['contracts'];
        Map<String, dynamic>? contractJson;
        if (contractRaw is Map<String, dynamic>) {
          contractJson = contractRaw;
        } else if (contractRaw is List && contractRaw.isNotEmpty) {
          contractJson = contractRaw.first as Map<String, dynamic>?;
        }

        final contractStatus = contractJson?['status'] as String?;
        if (contractStatus == 'Refunded' || contractStatus == 'Cancelled') {
          continue;
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
        }
      }

      // 3. Fetch Revenue Collected per currency from payments -> enrollments -> programs
      final paymentsResponse = await client
          .from('payments')
          .select('amount_paid, status, enrollments(programs(currency))')
          .or('status.eq.Paid,status.eq.Partial');

      final Map<String, double> revenueCollectedByCurrency = {};
      for (final row in paymentsResponse as List<dynamic>) {
        final amount = (row['amount_paid'] as num?)?.toDouble() ?? 0.0;
        
        String currency = 'RON';
        final enrollmentRaw = row['enrollments'];
        Map<String, dynamic>? enrollmentJson;
        if (enrollmentRaw is Map<String, dynamic>) {
          enrollmentJson = enrollmentRaw;
        } else if (enrollmentRaw is List && enrollmentRaw.isNotEmpty) {
          enrollmentJson = enrollmentRaw.first as Map<String, dynamic>?;
        }

        if (enrollmentJson != null) {
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
        }

        revenueCollectedByCurrency[currency] =
            (revenueCollectedByCurrency[currency] ?? 0.0) + amount;
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

      return AnalyticsSummary(
        totalStudents: totalStudents,
        expectedRevenueByCurrency: expectedRevenueByCurrency,
        revenueCollectedByCurrency: revenueCollectedByCurrency,
        totalExpectedInRon: totalExpectedInRon,
        totalCollectedInRon: totalCollectedInRon,
        liveEurRate: liveEurRate,
      );
    } catch (e) {
      throw Exception('Failed to calculate analytics metrics: $e');
    }
  }
}
