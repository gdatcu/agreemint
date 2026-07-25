import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'analytics_controller.g.dart';

class AnalyticsSummary {
  final int totalStudents;
  final double expectedRevenue;
  final double revenueCollected;

  const AnalyticsSummary({
    required this.totalStudents,
    required this.expectedRevenue,
    required this.revenueCollected,
  });
}

@riverpod
class AnalyticsSummaryController extends _$AnalyticsSummaryController {
  @override
  Future<AnalyticsSummary> build() async {
    try {
      final client = Supabase.instance.client;

      // 1. Fetch Total Students (Count rows in 'students')
      final studentsResponse = await client.from('students').select('id');
      final totalStudents = (studentsResponse as List<dynamic>).length;

      // 2. Fetch Expected Revenue (Sum of 'total_price' from joined 'programs' in 'enrollments')
      final enrollmentsResponse =
          await client.from('enrollments').select('programs(total_price)');
      double expectedRevenue = 0.0;
      for (final row in enrollmentsResponse as List<dynamic>) {
        final program = row['programs'] as Map<String, dynamic>?;
        if (program != null) {
          expectedRevenue +=
              (program['total_price'] as num?)?.toDouble() ?? 0.0;
        }
      }

      // 3. Fetch Revenue Collected (Sum of 'amount_paid' in 'payments' where status is Paid or Partial)
      final paymentsResponse = await client
          .from('payments')
          .select('amount_paid')
          .or('status.eq.Paid,status.eq.Partial');
      double revenueCollected = 0.0;
      for (final row in paymentsResponse as List<dynamic>) {
        revenueCollected += (row['amount_paid'] as num?)?.toDouble() ?? 0.0;
      }

      return AnalyticsSummary(
        totalStudents: totalStudents,
        expectedRevenue: expectedRevenue,
        revenueCollected: revenueCollected,
      );
    } catch (e) {
      throw Exception('Failed to calculate analytics metrics: $e');
    }
  }
}
