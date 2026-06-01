import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/dashboard_stats.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/dashboard/monthly_analytics_chart.dart';
import '../../widgets/dashboard/recent_transactions_widget.dart';
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
    final settingsAsync = ref.watch(settingsProvider);
    final currencyCode = settingsAsync.value?.currency;
    final currencyFormatter = CurrencyFormatter.numberFormat(currencyCode, decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      extendBodyBehindAppBar: true,
      appBar: const _DashboardTopBar(),
      body: RefreshIndicator(
        onRefresh: () => _refreshAll(ref),
        color: AppColors.primary,
        backgroundColor: AppColors.darkSurface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 128, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _GreetingHeader(),
                const SizedBox(height: 28),
                statsAsync.when(
                  data: (stats) => _BentoStatsGrid(stats: stats, currencyFormatter: currencyFormatter),
                  loading: () => const _LoadingPlaceholder(height: 340),
                  error: (e, st) => const _ErrorPlaceholder(message: 'Stats error'),
                ),
                const SizedBox(height: 28),
                monthlyDataAsync.when(
                  data: (monthlyData) => MonthlyAnalyticsChart(data: monthlyData),
                  loading: () => const _LoadingPlaceholder(height: 320),
                  error: (e, st) => const _ErrorPlaceholder(message: 'Analytics error'),
                ),
                const SizedBox(height: 32),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),
                const _QuickActionsRow(),
                const SizedBox(height: 32),
                recentTransactionsAsync.when(
                  data: (transactions) => RecentTransactionsWidget(
                    transactions: transactions,
                    currencyFormatter: currencyFormatter,
                    onViewAll: () => context.go('/payments'),
                  ),
                  loading: () => const _LoadingPlaceholder(height: 220),
                  error: (e, st) => const _ErrorPlaceholder(message: 'Transactions error'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/students/add'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
        ),
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _DashboardTopBar();

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    return Consumer(
      builder: (context, ref, _) {
        final settings = ref.watch(settingsProvider).value;
        final centerName = (settings?.centerName.trim().isNotEmpty ?? false)
            ? settings!.centerName.trim()
            : 'FeeSync';

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.01),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
                      image: const DecorationImage(
                        image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDFatqCXii6QXM23ITxI_J4L-gdJ3kpvJv3DVnywZap9XQDhFpegBVGt_Sj_kClmsz_lg-7ld9TAuw-ynUMnTURqFRfYSBK5X86Qu7tT9zDN4XKNsxFubjQfu50sy9M_AAL57qfJKz2WL0TDKAhrkAUpkfbAJAfbaQe5uAcPOkbXgxXEjRC_iKVXAJ2hTohysOQA6Is60PVERp8yHLsNF4sjZmQ0YrvcZevc91XzzHhwknnfHTk1eUvO_jq-vhKTqWhWFNQd1yHXpMb'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          centerName,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ADMINISTRATOR',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 24),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () => context.push('/notifications'),
                        icon: Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 24),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = 'Good evening';
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    }
    final dateFormatted = DateFormat('EEEE, MMMM d').format(now);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, Admin 👋',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateFormatted,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _BentoStatsGrid extends StatelessWidget {
  final DashboardStats stats;
  final NumberFormat currencyFormatter;

  const _BentoStatsGrid({required this.stats, required this.currencyFormatter});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Collected',
                value: currencyFormatter.format(stats.totalFeesCollected),
                icon: Icons.account_balance_wallet_rounded,
                showTrend: true,
                trendPercent: 12.5,
                trendUp: true,
                iconColor: AppColors.primary,
                iconBackgroundColor: AppColors.primaryContainer,
                isGradient: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _CollectionRateGaugeCard(rate: stats.collectionRate),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Pending Fees',
                value: currencyFormatter.format(stats.pendingFees),
                icon: Icons.pending_actions_rounded,
                iconColor: AppColors.error,
                iconBackgroundColor: AppColors.errorContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Active Students',
                value: stats.totalStudents.toString(),
                icon: Icons.group_rounded,
                iconColor: AppColors.secondary,
                iconBackgroundColor: AppColors.secondaryContainer,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CollectionRateGaugeCard extends StatelessWidget {
  final double rate;

  const _CollectionRateGaugeCard({required this.rate});

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.01),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collection Rate',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
              Icon(Icons.percent_rounded, size: 14, color: AppColors.primary),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: rate / 100.0,
                      strokeWidth: 5,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    Icon(
                      Icons.trending_up_rounded,
                      size: 16,
                      color: AppColors.primary,
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

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          label: 'Batches',
          icon: Icons.layers_rounded,
          onTap: () => context.go('/batches'),
          actionColor: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _QuickAction(
          label: 'Add Student',
          icon: Icons.person_add_rounded,
          onTap: () => context.push('/students/add'),
          actionColor: AppColors.secondary,
        ),
        const SizedBox(width: 12),
        _QuickAction(
          label: 'Record Pay',
          icon: Icons.payments_rounded,
          onTap: () => context.push('/payments/record'),
          actionColor: const Color(0xFF10B981),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color actionColor;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.darkCard.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: actionColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final double height;
  const _LoadingPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(28)),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final String message;
  const _ErrorPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.errorContainer.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(28)),
      child: Center(child: Text(message, style: TextStyle(color: AppColors.error))),
    );
  }
}
