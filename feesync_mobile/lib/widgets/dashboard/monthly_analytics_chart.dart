import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_stats.dart';

class MonthlyAnalyticsChart extends StatefulWidget {
  final List<MonthlyStat> data;
  final String title;

  const MonthlyAnalyticsChart({
    super.key,
    required this.data,
    this.title = 'Monthly Revenue Analytics',
  });

  @override
  State<MonthlyAnalyticsChart> createState() => _MonthlyAnalyticsChartState();
}

class _MonthlyAnalyticsChartState extends State<MonthlyAnalyticsChart> {
  String selectedPeriod = 'monthly'; // monthly, weekly

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _emptyState();
    }

    // Find max value for scaling
    final maxValue = widget.data.isEmpty
        ? 0.0
        : widget.data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    final maxIndex = widget.data.indexWhere((e) => e.amount == maxValue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Performance comparison over the last 6 months',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              _buildPeriodButton('Weekly', 'weekly'),
              const SizedBox(width: 8),
              _buildPeriodButton('Monthly', 'monthly'),
            ],
          ),
          const SizedBox(height: 20),

          // Bar Chart
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 0 ? maxValue / 4 : 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.darkBorder.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.data.length) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            widget.data[index].month.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        );
                      },
                      reservedSize: 35,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'INR ${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 9,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: List.generate(widget.data.length, (index) {
                  final isPeak = index == maxIndex;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: widget.data[index].amount,
                        color: isPeak
                            ? AppColors.primaryLight
                            : AppColors.darkSurface,
                        width: 18,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        borderSide: isPeak
                            ? BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                width: 2,
                              )
                            : BorderSide.none,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = selectedPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => selectedPeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: AppColors.darkBorder.withValues(alpha: 0.6),
                  width: 1,
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkBorder,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          'No data available',
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
