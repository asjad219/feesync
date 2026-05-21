import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_stats.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/dashboard/monthly_analytics_chart.dart';
import '../../widgets/dashboard/recent_transactions_widget.dart';
import '../../widgets/dashboard/revenue_trend_chart.dart';
import '../../widgets/dashboard/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refreshAll(WidgetRef ref) async {
    await Future.wait([
      ref.refresh(dashboardStatsProvider.future),
      ref.refresh(monthlyCollectionDataProvider.future),
      ref.refresh(recentTransactionsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final monthlyDataAsync = ref.watch(monthlyCollectionDataProvider);
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: _DashboardTopBar(
          onRefresh: () => _refreshAll(ref),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshAll(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _GreetingHeader(),
                const SizedBox(height: 20),
                statsAsync.when(
                  data: (stats) => _StatsGrid(stats: stats),
                  loading: () => const _LoadingCard(height: 160),
                  error: (e, st) => _ErrorCard(message: 'Failed to load stats'),
                ),
                const SizedBox(height: 20),
                monthlyDataAsync.when(
                  data: (monthlyData) => RevenueTrendChart(
                    data: monthlyData,
                    title: 'Revenue Trend',
                  ),
                  loading: () => const _LoadingCard(height: 240),
                  error: (e, st) =>
                      _ErrorCard(message: 'Failed to load trend data'),
                ),
                const SizedBox(height: 20),
                monthlyDataAsync.when(
                  data: (monthlyData) => MonthlyAnalyticsChart(
                    data: monthlyData,
                    title: 'Monthly Revenue Analytics',
                  ),
                  loading: () => const _LoadingCard(height: 280),
                  error: (e, st) => _ErrorCard(message: 'Failed to load analytics'),
                ),
                const SizedBox(height: 20),
                _QuickActionsRow(
                  onAddStudent: () => context.go('/students'),
                  onRecordPayment: () => context.go('/payments'),
                  onSendReminder: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reminder workflow coming soon.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                recentTransactionsAsync.when(
                  data: (transactions) => RecentTransactionsWidget(
                    transactions: transactions,
                    onViewAll: () => context.go('/payments'),
                  ),
                  loading: () => const _LoadingCard(height: 220),
                  error: (e, st) =>
                      _ErrorCard(message: 'Failed to load transactions'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  final VoidCallback onRefresh;

  const _DashboardTopBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDFatqCXii6QXM23ITxI_J4L-gdJ3kpvJv3DVnywZap9XQDhFpegBVGt_Sj_kClmsz_lg-7ld9TAuw-ynUMnTURqFRfYSBK5X86Qu7tT9zDN4XKNsxFubjQfu50sy9M_AAL57qfJKz2WL0TDKAhrkAUpkfbAJAfbaQe5uAcPOkbXgxXEjRC_iKVXAJ2hTohysOQA6Is60PVERp8yHLsNF4sjZmQ0YrvcZevc91XzzHhwknnfHTk1eUvO_jq-vhKTqWhWFNQd1yHXpMb',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: AppColors.textHint);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'FeeSync',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'ADMINISTRATOR',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.0,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search),
                color: AppColors.textSecondary,
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.textSecondary,
              ),
              Stack(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined),
                    color: AppColors.textSecondary,
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormatted = DateFormat('EEEE, MMMM d, yyyy').format(now);
    final greeting = _timeBasedGreeting(now.hour);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateFormatted,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      name: 'INR',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Column(
      children: [
        _buildRow(
          StatCard(
            title: 'Total Collected',
            value: currencyFormatter.format(stats.totalFeesCollected),
            suffix: 'This month',
            icon: Icons.account_balance_wallet,
            showTrend: true,
            trendPercent: stats.collectionRate,
            trendUp: stats.collectionRate >= 0,
          ),
          StatCard(
            title: 'Pending Fees',
            value: currencyFormatter.format(stats.pendingFees),
            icon: Icons.pending_actions,
            iconBackgroundColor: AppColors.pending.withValues(alpha: 0.12),
            iconColor: AppColors.pending,
          ),
        ),
        const SizedBox(height: 12),
        _buildRow(
          StatCard(
            title: 'Active Students',
            value: stats.totalStudents.toString(),
            icon: Icons.group,
            iconBackgroundColor: AppColors.primary.withValues(alpha: 0.18),
            iconColor: AppColors.primaryLight,
          ),
          StatCard(
            title: 'Collection Rate',
            value: '${stats.collectionRate.toStringAsFixed(1)}%',
            icon: Icons.insights,
            iconBackgroundColor: AppColors.paid.withValues(alpha: 0.12),
            iconColor: AppColors.paid,
          ),
        ),
      ],
    );
  }

  Widget _buildRow(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onAddStudent;
  final VoidCallback onRecordPayment;
  final VoidCallback onSendReminder;

  const _QuickActionsRow({
    required this.onAddStudent,
    required this.onRecordPayment,
    required this.onSendReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                label: 'Add Student',
                icon: Icons.person_add_alt_1,
                color: AppColors.primary,
                onTap: () => context.push('/students/add'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                label: 'Record Payment',
                icon: Icons.payments,
                color: AppColors.paid,
                onTap: () => context.push('/payments/record'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                label: 'Fees',
                icon: Icons.summarize_outlined,
                color: AppColors.pending,
                onTap: () => context.go('/fees'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _timeBasedGreeting(int hour) {
  if (hour < 12) {
    return 'Good morning';
  }

  if (hour < 18) {
    return 'Good afternoon';
  }

  return 'Good evening';
}

class _LoadingCard extends StatelessWidget {
  final double height;

  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.overdue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.overdue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.overdue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.overdue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
