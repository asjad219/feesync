import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_stats.dart';

class MonthlyAnalyticsChart extends StatefulWidget {
  final List<MonthlyStat> data;
  final List<MonthlyStat>? weeklyData;
  final String title;
  final NumberFormat? currencyFormatter;

  const MonthlyAnalyticsChart({
    super.key,
    required this.data,
    this.weeklyData,
    this.title = 'Monthly Revenue Analytics',
    this.currencyFormatter,
  });

  @override
  State<MonthlyAnalyticsChart> createState() => _MonthlyAnalyticsChartState();
}

class _MonthlyAnalyticsChartState extends State<MonthlyAnalyticsChart> {
  String selectedPeriod = 'monthly';

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final activeData = selectedPeriod == 'weekly' && widget.weeklyData != null
        ? widget.weeklyData!
        : widget.data;

    if (activeData.isEmpty) {
      return _emptyState(isDark);
    }

    final maxValue = activeData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final maxIndex = activeData.indexWhere((e) => e.amount == maxValue);
    final formatter = widget.currencyFormatter ?? NumberFormat.compact();

    // Redefined dynamic colors for chart
    final Color cardColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
    final Color textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final Color textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);
    final Color textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final Color primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final Color secondaryColor = isDark ? const Color(0xFFD0BCFF) : const Color(0xFF7C3AED);
    final Color surfaceContainerLowColor = isDark ? const Color(0xFF1A1A28) : const Color(0xFFF8FAFC);
    final Color surfaceContainerHighColor = isDark ? const Color(0xFF292937) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: isDark ? 0.75 : 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.01),
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
                        color: textPrimaryColor,
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
                        color: textTertiaryColor,
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
                  color: isDark ? surfaceContainerLowColor : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
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
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: surfaceContainerHighColor.withValues(alpha: 0.95),
                    tooltipBorder: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      width: 1,
                    ),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final amount = activeData[groupIndex].amount;
                      return BarTooltipItem(
                        '${activeData[groupIndex].month.toUpperCase()}\n',
                        GoogleFonts.inter(
                          color: textSecondaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: formatter.format(amount),
                            style: GoogleFonts.outfit(
                              color: textPrimaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 0 ? maxValue / 4 : 1000,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
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
                        if (index < 0 || index >= activeData.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            activeData[index].month.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: textTertiaryColor,
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
                barGroups: List.generate(activeData.length, (index) {
                  final isPeak = index == maxIndex;
                  // Beautiful gradients for the bar chart
                  final peakGradient = LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  );
                  final defaultGradient = LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.35),
                      primaryColor.withValues(alpha: 0.15)
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  );

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: activeData[index].amount,
                        gradient: isPeak ? peakGradient : defaultGradient,
                        width: 32,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        borderSide: isPeak
                            ? BorderSide(color: primaryColor.withValues(alpha: 0.3), width: 1)
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
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final primaryContainerColor = isDark ? const Color(0xFF2563EB) : const Color(0xFFDBEAFE);
    final onPrimaryContainerColor = isDark ? const Color(0xFFEEEFFF) : const Color(0xFF1E40AF);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: () => setState(() => selectedPeriod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? primaryContainerColor : Colors.white) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                ? (isDark ? onPrimaryContainerColor : primaryColor) 
                : textTertiaryColor,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    final Color cardColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
    final Color textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: isDark ? 0.75 : 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text('No analytical data available', style: TextStyle(color: textTertiaryColor)),
      ),
    );
  }
}
