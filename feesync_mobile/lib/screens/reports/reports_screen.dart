import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
    final classStatsAsync = ref.watch(classCollectionDataProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currencyCode = settingsAsync.value?.currency;
    final currencyFormatter = CurrencyFormatter.numberFormat(currencyCode, decimalDigits: 0);
    final currencySymbol = CurrencyFormatter.symbolFor(currencyCode);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text('Analytics', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        actions: [
          statsAsync.when(
            data: (stats) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                monthlyAsync.when(
                  data: (monthly) => IconButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.darkSurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text(
                            'Download Report',
                            style: GoogleFonts.manrope(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          content: Text(
                            'Do you want to download the Analytics report as an Excel (CSV) file?',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Download', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      final csvBuffer = StringBuffer();
                      csvBuffer.writeln('FeeSync Analytics Report');
                      csvBuffer.writeln('Last Updated,${DateFormat('yyyy-MM-dd HH:mm').format(stats.lastUpdated)}');
                      csvBuffer.writeln();
                      csvBuffer.writeln('Overview Metrics');
                      csvBuffer.writeln('Metric,Value');
                      csvBuffer.writeln('Total Students,${stats.totalStudents}');
                      csvBuffer.writeln('Total Revenue (Collected),${stats.totalFeesCollected}');
                      csvBuffer.writeln('${stats.pendingFees < 0 ? 'Advance Dues' : 'Due Amount'},${stats.pendingFees.abs()}');
                      csvBuffer.writeln('Collection Rate,${stats.collectionRate.toStringAsFixed(1)}%');
                      csvBuffer.writeln();
                      csvBuffer.writeln('Revenue Trend');
                      csvBuffer.writeln('Month,Amount');
                      for (final m in monthly) {
                        csvBuffer.writeln('${m.month},${m.amount}');
                      }
                      csvBuffer.writeln();
                      csvBuffer.writeln('Class Performance');
                      csvBuffer.writeln('Class,Collected,Pending/Advance');
                      final classStats = classStatsAsync.value ?? [];
                      for (final c in classStats) {
                        csvBuffer.writeln('${c.className},${c.collected},${c.pending}');
                      }
                      
                      final dir = await getApplicationDocumentsDirectory();
                      final fileName = 'feesync_analytics_${DateTime.now().millisecondsSinceEpoch}.csv';
                      final path = '${dir.path}/$fileName';
                      final file = File(path);
                      await file.writeAsString(csvBuffer.toString());

                      final params = SaveFileDialogParams(
                        sourceFilePath: path,
                        fileName: fileName,
                      );
                      
                      final savedPath = await FlutterFileDialog.saveFile(params: params);

                      if (savedPath != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Report downloaded successfully!',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.onSuccess),
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.table_view_rounded, color: AppColors.textPrimary),
                    tooltip: 'Export as XLS/CSV',
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
                IconButton(
                  onPressed: () {
                    final text = 'FeeSync Analytics Report\n'
                        'Last Updated: ${DateFormat('yyyy-MM-dd HH:mm').format(stats.lastUpdated)}\n\n'
                        '• Total Students: ${stats.totalStudents}\n'
                        '• Total Revenue (Collected): ${currencyFormatter.format(stats.totalFeesCollected)}\n'
                        '• ${stats.pendingFees < 0 ? 'Advance Dues' : 'Due Amount'}: ${currencyFormatter.format(stats.pendingFees.abs())}\n'
                        '• Collection Rate: ${stats.collectionRate.toStringAsFixed(1)}%\n\n'
                        'Generated from FeeSync app settings analytics.';
                    SharePlus.instance.share(
                      ShareParams(
                        text: text,
                        subject: 'FeeSync Analytics Report',
                      ),
                    );
                  },
                  icon: Icon(Icons.share_rounded, color: AppColors.textPrimary),
                  tooltip: 'Share Text Report',
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => monthlyAsync.when(
          data: (monthly) => classStatsAsync.when(
            data: (classStats) => _buildBody(context, stats, monthly, classStats, currencyFormatter, currencySymbol),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => const Center(child: Text('Error loading class stats')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => const Center(child: Text('Error loading charts')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => const Center(child: Text('Error loading stats')),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    dynamic stats,
    List<dynamic> monthly,
    List<dynamic> classStats,
    NumberFormat currencyFormatter,
    String currencySymbol,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: _SectionHeader(title: 'Overview', subtitle: 'Snapshot of your financial performance'),
              ),
              const _CycleFilterDropdown(),
            ],
          ),
          const SizedBox(height: 24),
          _KeyMetricsGrid(stats: stats, currencyFormatter: currencyFormatter),
          const SizedBox(height: 32),
          _RevenueChartCard(monthly: monthly),
          const SizedBox(height: 32),
          _StatusDistributionCard(stats: stats, currencySymbol: currencySymbol),
          const SizedBox(height: 32),
          _ClassPerformanceCard(classStats: classStats, currencyFormatter: currencyFormatter),
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
              label: stats.pendingFees < 0 ? 'ADVANCE' : 'DUE AMOUNT', 
              value: currencyFormatter.format(stats.pendingFees.abs()), 
              color: stats.pendingFees < 0 ? AppColors.success : AppColors.error,
              icon: stats.pendingFees < 0 ? Icons.account_balance_wallet_rounded : Icons.warning_amber_rounded,
              iconBgColor: stats.pendingFees < 0 ? AppColors.success : AppColors.error,
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
                      PieChartSectionData(color: AppColors.primary, value: stats.totalFeesCollected < 0 ? 0 : stats.totalFeesCollected, radius: 12, title: ''),
                      PieChartSectionData(color: AppColors.error.withValues(alpha: 0.2), value: stats.pendingFees < 0 ? 0 : stats.pendingFees, radius: 12, title: ''),
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
                    _LegendItem(
                      label: stats.pendingFees < 0 ? 'Advance' : 'Pending', 
                      value: '$currencySymbol${(stats.pendingFees.abs() / 1000).toStringAsFixed(1)}k', 
                      color: stats.pendingFees < 0 ? AppColors.success : AppColors.error,
                    ),
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

class _CycleFilterDropdown extends ConsumerWidget {
  const _CycleFilterDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCycle = ref.watch(selectedTimeCycleProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeCycle>(
          value: selectedCycle,
          dropdownColor: AppColors.darkSurface,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary, size: 18),
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          onChanged: (TimeCycle? newCycle) {
            if (newCycle != null) {
              ref.read(selectedTimeCycleProvider.notifier).state = newCycle;
            }
          },
          items: const [
            DropdownMenuItem(
              value: TimeCycle.monthly,
              child: Text('Monthly'),
            ),
            DropdownMenuItem(
              value: TimeCycle.quarterly,
              child: Text('Quarterly'),
            ),
            DropdownMenuItem(
              value: TimeCycle.yearly,
              child: Text('Yearly'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassPerformanceCard extends StatelessWidget {
  final List<dynamic> classStats;
  final NumberFormat currencyFormatter;

  const _ClassPerformanceCard({required this.classStats, required this.currencyFormatter});

  @override
  Widget build(BuildContext context) {
    if (classStats.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Class Performance', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: classStats.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
            ),
            itemBuilder: (context, index) {
              final stat = classStats[index];
              return Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.primaryContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        stat.className.isNotEmpty ? stat.className.substring(0, 1).toUpperCase() : '?', 
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stat.className, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('Paid: ${currencyFormatter.format(stat.collected)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                            const SizedBox(width: 16),
                            Text(
                              '${stat.pending < 0 ? 'Adv' : 'Pend'}: ${currencyFormatter.format(stat.pending.abs())}', 
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: stat.pending < 0 ? AppColors.success : AppColors.error)
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}