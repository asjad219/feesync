import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/widgets/glass/glass_card.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final monthlyAsync = ref.watch(monthlyCollectionDataProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currencyCode = settingsAsync.value?.currency;
    final currencyFormatter = CurrencyFormatter.numberFormat(currencyCode, decimalDigits: 0);
    final currencySymbol = CurrencyFormatter.symbolFor(currencyCode);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text('Analytics', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => monthlyAsync.when(
          data: (monthly) => _buildBody(context, stats, monthly, currencyFormatter, currencySymbol),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading charts')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading stats')),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    dynamic stats,
    List<dynamic> monthly,
    NumberFormat currencyFormatter,
    String currencySymbol,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Overview', subtitle: 'Snapshot of your financial performance'),
          const SizedBox(height: 24),
          _KeyMetricsGrid(stats: stats, currencyFormatter: currencyFormatter),
          const SizedBox(height: 32),
          _RevenueChartCard(monthly: monthly),
          const SizedBox(height: 32),
          _StatusDistributionCard(stats: stats, currencySymbol: currencySymbol),
        ],
      ),
    );
  }
}

class _KeyMetricsGrid extends StatelessWidget {
  final dynamic stats;
  final NumberFormat currencyFormatter;
  const _KeyMetricsGrid({required this.stats, required this.currencyFormatter});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _MetricMiniCard(
              label: 'TOTAL REVENUE', 
              value: currencyFormatter.format(stats.totalFeesCollected), 
              color: AppColors.primary,
              icon: Icons.account_balance_wallet_rounded,
              iconBgColor: AppColors.primary,
            ),
            const SizedBox(width: 16),
            _MetricMiniCard(
              label: 'OUTSTANDING', 
              value: currencyFormatter.format(stats.pendingFees), 
              color: AppColors.error,
              icon: Icons.warning_amber_rounded,
              iconBgColor: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _MetricMiniCard(
              label: 'COLLECTION RATE', 
              value: '${stats.collectionRate.toStringAsFixed(1)}%', 
              color: AppColors.secondary,
              icon: Icons.analytics_rounded,
              iconBgColor: AppColors.secondary,
            ),
            const SizedBox(width: 16),
            _MetricMiniCard(
              label: 'STUDENTS', 
              value: '${stats.totalStudents}', 
              color: AppColors.tertiary,
              icon: Icons.group_rounded,
              iconBgColor: AppColors.tertiary,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final Color iconBgColor;

  const _MetricMiniCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label, 
                    style: GoogleFonts.inter(
                      fontSize: 9, 
                      fontWeight: FontWeight.w800, 
                      letterSpacing: 1.1, 
                      color: AppColors.textTertiary
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBgColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconBgColor, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value, 
              style: GoogleFonts.manrope(
                fontSize: 18, 
                fontWeight: FontWeight.w800, 
                color: AppColors.textPrimary
              )
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  final List<dynamic> monthly;
  const _RevenueChartCard({required this.monthly});

  @override
  Widget build(BuildContext context) {
    if (monthly.isEmpty) return const SizedBox.shrink();
    final maxValue = monthly.map((m) => m.amount as double).reduce((a, b) => a > b ? a : b);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue Trend', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        if (val < 0 || val >= monthly.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(monthly[val.toInt()].month.substring(0, 3).toUpperCase(), style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: monthly.asMap().entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [BarChartRodData(toY: e.value.amount, color: AppColors.primaryContainer, width: 24, borderRadius: BorderRadius.circular(6))],
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDistributionCard extends StatelessWidget {
  final dynamic stats;
  final String currencySymbol;
  const _StatusDistributionCard({required this.stats, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fee Status Distribution', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 35,
                    sections: [
                      PieChartSectionData(color: AppColors.primary, value: stats.totalFeesCollected, radius: 12, title: ''),
                      PieChartSectionData(color: AppColors.error.withValues(alpha: 0.2), value: stats.pendingFees, radius: 12, title: ''),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    _LegendItem(label: 'Paid', value: '$currencySymbol${(stats.totalFeesCollected / 1000).toStringAsFixed(1)}k', color: AppColors.primary),
                    const SizedBox(height: 12),
                    _LegendItem(label: 'Pending', value: '$currencySymbol${(stats.pendingFees / 1000).toStringAsFixed(1)}k', color: AppColors.error),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _LegendItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        ]),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textTertiary)),
      ],
    );
  }
}
