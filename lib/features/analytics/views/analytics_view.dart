import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/analytics_controller.dart';
import 'monthly_revenue_chart_widget.dart';

import '../../../core/services/accounting_export_service.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => const _AccountingExportDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(analyticsSummaryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: 'Export Accounting CSV (ANAF)',
            onPressed: () => _showExportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Business & Contract Settings',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Metrics',
            onPressed: () =>
                ref.refresh(analyticsSummaryControllerProvider.future),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(analyticsSummaryControllerProvider.future),
        child: analyticsState.when(
          data: (summary) {
            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // 1. Total Enrolled Students Card
                _buildMetricCard(
                  context,
                  title: 'Total Enrolled Students',
                  value: '${summary.totalStudents}',
                  subtitle: 'Active enrollments across all program cohorts',
                  icon: Icons.people_alt_rounded,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 16),

                // 2. Expected Revenue Card
                _buildMetricCard(
                  context,
                  title: 'Total Expected Revenue',
                  value: summary.formattedExpectedRevenue,
                  subtitle: summary.hasMultipleCurrenciesOrEur
                      ? '~${formatCurrencyAmount(summary.totalExpectedInRon, 'RON')} estimated total'
                      : null,
                  icon: Icons.trending_up_rounded,
                  color: Colors.amber.shade800,
                ),
                const SizedBox(height: 16),

                // 3. Collected Revenue Card
                _buildMetricCard(
                  context,
                  title: 'Total Revenue Collected',
                  value: summary.formattedCollectedRevenue,
                  subtitle: summary.hasMultipleCurrenciesOrEur
                      ? '~${formatCurrencyAmount(summary.totalCollectedInRon, 'RON')} estimated collected'
                      : null,
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.teal,
                ),
                const SizedBox(height: 16),

                // 4. Collection Progress Card
                _buildCollectionProgressCard(context, summary),
                const SizedBox(height: 16),

                // 5. Monthly Revenue & Student Growth Chart
                if (summary.monthlyBreakdown.isNotEmpty) ...[
                  MonthlyRevenueChartWidget(monthlyData: summary.monthlyBreakdown),
                  const SizedBox(height: 16),
                ],

                // 6. Exchange Rate Banner if EUR is present
                if (summary.hasMultipleCurrenciesOrEur) ...[
                  _buildExchangeRateBanner(context, summary.liveEurRate),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(32),
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Failed to load analytics',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () =>
                        ref.invalidate(analyticsSummaryControllerProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionProgressCard(
    BuildContext context,
    AnalyticsSummary summary,
  ) {
    final percent = (summary.collectionProgress * 100).toStringAsFixed(1);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pie_chart_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Collection Rate',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: summary.collectionProgress,
                minHeight: 10,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  summary.collectionProgress >= 0.8
                      ? Colors.green
                      : summary.collectionProgress >= 0.5
                          ? Colors.amber.shade800
                          : Colors.deepOrange,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Outstanding Balance:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  formatCurrencyAmount(summary.pendingBalanceInRon, 'RON'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: summary.pendingBalanceInRon > 0
                            ? Colors.deepOrange
                            : Colors.green,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeRateBanner(BuildContext context, double rate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.currency_exchange, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Live Frankfurter Rate: 1 EUR = ${rate.toStringAsFixed(4)} RON',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountingExportDialog extends StatefulWidget {
  const _AccountingExportDialog();

  @override
  State<_AccountingExportDialog> createState() =>
      __AccountingExportDialogState();
}

class __AccountingExportDialogState extends State<_AccountingExportDialog> {
  String _selectedRange = 'All Time';
  bool _isExporting = false;

  void _handleExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      DateTime? start;
      DateTime? end;
      final now = DateTime.now();

      if (_selectedRange == 'Current Month') {
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else if (_selectedRange == 'Last Month') {
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
      } else if (_selectedRange == 'Year to Date') {
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
      }

      final records = await AccountingExportService.fetchAccountingRecords(
        startDate: start,
        endDate: end,
      );

      if (mounted) {
        Navigator.of(context).pop();

        if (records.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No paid accounting records found for selected period.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final filename =
            'Agreemint_Accounting_${_selectedRange.replaceAll(' ', '_')}_${now.year}-${now.month.toString().padLeft(2, '0')}.csv';

        await AccountingExportService.exportAndShareCsv(records, filename: filename);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Exported ${records.length} accounting records ($_selectedRange) successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.table_chart_outlined, color: Colors.teal),
          SizedBox(width: 10),
          Text('Export Accounting CSV'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export paid installment receipts, client CUI/CIF, and SOLO invoice numbers formatted for Romanian tax & ANAF filing (UTF-8 BOM).',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Period:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedRange,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'All Time', child: Text('All Time')),
              DropdownMenuItem(value: 'Current Month', child: Text('Current Month')),
              DropdownMenuItem(value: 'Last Month', child: Text('Last Month')),
              DropdownMenuItem(value: 'Year to Date', child: Text('Year to Date')),
            ],
            onChanged: _isExporting
                ? null
                : (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRange = val;
                      });
                    }
                  },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.download_rounded, size: 18),
          label: Text(_isExporting ? 'Exporting...' : 'Export CSV'),
          onPressed: _isExporting ? null : _handleExport,
        ),
      ],
    );
  }
}
