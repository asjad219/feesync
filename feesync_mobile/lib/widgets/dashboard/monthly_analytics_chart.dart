import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String selectedPeriod = 'monthly';

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    if (widget.data.isEmpty) {
      return _emptyState(isDark);
    }

    final maxValue = widget.data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final maxIndex = widget.data.indexWhere((e) => e.amount == maxValue);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.01),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Collections overview for the last 6 months',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Modern Toggle Pills
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerLow : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  ),
                ),
                child: Row(
                  children: [
                    _buildPeriodButton('W', 'weekly', isDark),
                    const SizedBox(width: 4),
                    _buildPeriodButton('M', 'monthly', isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Chart Wrapper
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
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.data.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            widget.data[index].month.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppColors.textTertiary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(widget.data.length, (index) {
                  final isPeak = index == maxIndex;
                  // Beautiful gradients for the bar chart
                  final peakGradient = LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  );
                  final defaultGradient = LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.35),
                      AppColors.primary.withOpacity(0.15)
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  );

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: widget.data[index].amount,
                        gradient: isPeak ? peakGradient : defaultGradient,
                        width: 32,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        borderSide: isPeak
                            ? BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1)
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

  Widget _buildPeriodButton(String label, String value, bool isDark) {
    final isSelected = selectedPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => selectedPeriod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.primaryContainer : Colors.white) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected 
                ? (isDark ? AppColors.onPrimaryContainer : AppColors.primary) 
                : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
          width: 1.5,
        ),
      ),
      child: const Center(
        child: Text('No analytical data available', style: TextStyle(color: AppColors.textTertiary)),
      ),
    );
  }
}
