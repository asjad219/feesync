import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_stats.dart';

class RevenueTrendChart extends StatelessWidget {
  final List<MonthlyStat> data;
  final String title;

  const RevenueTrendChart({
    super.key,
    required this.data,
    this.title = 'Revenue Trend',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _emptyState();
    final maxValue = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
                child: Text('6 months', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final i = val.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(data[i].month.substring(0, 3).toUpperCase(), style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0)])),
                    dotData: FlDotData(show: true, getDotPainter: (_, _, _, _) => FlDotCirclePainter(radius: 4, color: AppColors.primary, strokeWidth: 2, strokeColor: AppColors.darkBg)),
                  ),
                ],
                minY: 0,
                maxY: maxValue * 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(24)),
      child: Center(child: Text('No analytical trend available', style: TextStyle(color: AppColors.textTertiary))),
    );
  }
}