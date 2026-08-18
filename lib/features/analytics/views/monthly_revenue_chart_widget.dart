import 'package:flutter/material.dart';
import '../controllers/analytics_controller.dart';

class MonthlyRevenueChartWidget extends StatefulWidget {
  final List<MonthlyRevenueData> monthlyData;

  const MonthlyRevenueChartWidget({
    super.key,
    required this.monthlyData,
  });

  @override
  State<MonthlyRevenueChartWidget> createState() =>
      _MonthlyRevenueChartWidgetState();
}

class _MonthlyRevenueChartWidgetState
    extends State<MonthlyRevenueChartWidget> {
  int _selectedViewIndex = 0; // 0 = Revenue (RON), 1 = Student Growth
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    double maxVal = 1.0;
    if (_selectedViewIndex == 0) {
      for (final m in widget.monthlyData) {
        if (m.collectedInRon > maxVal) maxVal = m.collectedInRon;
        if (m.expectedInRon > maxVal) maxVal = m.expectedInRon;
      }
    } else {
      for (final m in widget.monthlyData) {
        if (m.newEnrollments.toDouble() > maxVal) {
          maxVal = m.newEnrollments.toDouble();
        }
      }
    }

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
            // Header Title & View Toggle Buttons
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedViewIndex == 0
                            ? 'Monthly Revenue Trend'
                            : 'Student Enrollment Growth',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedViewIndex == 0
                            ? '6-Month Revenue Collected vs Expected (RON)'
                            : '6-Month New Student Enrollments',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ),

                // View Toggle Segment
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      icon: Icon(Icons.bar_chart_rounded, size: 16),
                      label: Text('Revenue', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      icon: Icon(Icons.show_chart_rounded, size: 16),
                      label: Text('Growth', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {_selectedViewIndex},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _selectedViewIndex = newSelection.first;
                      _hoveredIndex = null;
                    });
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Legend Header
            if (_selectedViewIndex == 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildLegendItem(
                    color: Colors.teal,
                    label: 'Collected',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 14),
                  _buildLegendItem(
                    color: Colors.amber.shade800,
                    label: 'Expected',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Selected Month Detail Banner (Tooltip)
            if (_hoveredIndex != null &&
                _hoveredIndex! < widget.monthlyData.length) ...[
              Builder(
                builder: (context) {
                  final data = widget.monthlyData[_hoveredIndex!];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(isDark ? 30 : 15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: primaryColor.withAlpha(80), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedViewIndex == 0
                                ? '${data.monthLabel}: ${formatCurrencyAmount(data.collectedInRon, 'RON')} Collected / ${formatCurrencyAmount(data.expectedInRon, 'RON')} Expected'
                                : '${data.monthLabel}: ${data.newEnrollments} New Enrollments',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            // Responsive Bar Chart Body
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(widget.monthlyData.length, (index) {
                  final item = widget.monthlyData[index];
                  final isHovered = _hoveredIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _hoveredIndex = _hoveredIndex == index ? null : index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Chart Bars
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: _selectedViewIndex == 0
                                    ? _buildDualBars(
                                        item, maxVal, isHovered, isDark)
                                    : _buildSingleBar(
                                        item.newEnrollments.toDouble(),
                                        maxVal,
                                        isHovered,
                                        Colors.indigo,
                                        isDark),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Month Label
                            Text(
                              item.monthLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isHovered
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isHovered
                                    ? primaryColor
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDualBars(MonthlyRevenueData data, double maxVal, bool isHovered, bool isDark) {
    final collectedHeightRatio = (data.collectedInRon / maxVal).clamp(0.05, 1.0);
    final expectedHeightRatio = (data.expectedInRon / maxVal).clamp(0.05, 1.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Collected Bar (Teal)
        Flexible(
          child: FractionallySizedBox(
            heightFactor: collectedHeightRatio,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isHovered ? Colors.teal.shade400 : Colors.teal,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: Colors.teal.withAlpha(120),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 3),

        // Expected Bar (Amber)
        Flexible(
          child: FractionallySizedBox(
            heightFactor: expectedHeightRatio,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isHovered ? Colors.amber.shade700 : Colors.amber.shade800,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: Colors.amber.withAlpha(120),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleBar(double val, double maxVal, bool isHovered, Color barColor, bool isDark) {
    final heightRatio = (val / maxVal).clamp(0.05, 1.0);

    return FractionallySizedBox(
      heightFactor: heightRatio,
      widthFactor: 0.6,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isHovered ? barColor.withAlpha(220) : barColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: barColor.withAlpha(120),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
