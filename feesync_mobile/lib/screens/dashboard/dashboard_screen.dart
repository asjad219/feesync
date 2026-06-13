import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/paywall_dialog.dart';
import '../../core/billing/feature_gate.dart';
import '../../models/dashboard_stats.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/subscription_provider.dart';
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

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final Color scaffoldBgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFC);
    final Color textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      extendBodyBehindAppBar: true,
      appBar: const _DashboardTopBar(),
      body: RefreshIndicator(
        onRefresh: () => _refreshAll(ref),
        color: primaryColor,
        backgroundColor: isDark ? const Color(0xFF12121F) : const Color(0xFFFFFFFF),
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
                  loading: () => _LoadingPlaceholder(height: 340, isDark: isDark),
                  error: (e, st) => _ErrorPlaceholder(message: 'Stats error', isDark: isDark),
                ),
                const SizedBox(height: 28),
                monthlyDataAsync.when(
                  data: (monthlyData) => MonthlyAnalyticsChart(
                    data: monthlyData,
                    currencyFormatter: currencyFormatter,
                  ),
                  loading: () => _LoadingPlaceholder(height: 320, isDark: isDark),
                  error: (e, st) => _ErrorPlaceholder(message: 'Analytics error', isDark: isDark),
                ),
                const SizedBox(height: 32),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textPrimaryColor,
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
                  loading: () => _LoadingPlaceholder(height: 220, isDark: isDark),
                  error: (e, st) => _ErrorPlaceholder(message: 'Transactions error', isDark: isDark),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final FeatureGate gate = ref.read(featureGateProvider).valueOrNull 
                ?? await ref.read(featureGateProvider.future);
            if (!gate.canAddStudent) {
              if (context.mounted) {
                await showPaywallDialog(
                  context,
                  ref,
                  trigger: PaywallTrigger.studentLimit,
                );
              }
              return;
            }
            if (context.mounted) {
              context.push('/students/add');
            }
          },
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
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final surfaceContainerColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: surfaceContainerColor.withValues(alpha: isDark ? 0.7 : 0.85),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
                      image: const DecorationImage(
                        image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDFatqCXii6QXM23ITxI_J4L-gdJ3kpvJv3DVnywZap9XQDhFpegBVGt_Sj_kClmsz_lg-7ld9TAuw-ynUMnTURqFRfYSBK5X86Qu7tT9zDN4XKNsxFubjQfu50sy9M_AAL57qfJKz2WL0TDKAhrkAUpkfbAJAfbaQe5uAcPOkbXgxXEjRC_iKVXAJ2hTohysOQA6Is60PVERp8yHLsNF4sjZmQ0YrvcZevc91XzzHhwknnfHTk1eUvO_jq-vhKTqWhWFNQd1yHXpMb'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final settings = ref.watch(settingsProvider).value;
                        final centerName = (settings?.centerName.trim().isNotEmpty ?? false)
                            ? settings!.centerName.trim()
                            : 'FeeSync';

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              centerName,
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimaryColor,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'ADMINISTRATOR',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: textTertiaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: () => context.go('/students'),
                      constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.search_rounded, color: textPrimaryColor, size: 20),
                    ),
                  ),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: () => context.push('/notifications'),
                          constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.notifications_none_rounded, color: textPrimaryColor, size: 20),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB4AB),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: surfaceContainerColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = 'Good evening';
    
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    }
    
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final userName = userProfile?.fullName.split(' ').first ?? 'Admin';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$greeting, $userName',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textPrimaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Text('👋', style: TextStyle(fontSize: 22)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          DateFormat('EEEE, MMMM d').format(now),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B),
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
    final bool isDark = AppColors.isDarkMode;
    final rate = stats.collectionRate;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final secondaryColor = isDark ? const Color(0xFFD0BCFF) : const Color(0xFF7C3AED);
    final primaryDarkColor = isDark ? const Color(0xFF2563EB) : const Color(0xFF1D4ED8);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [primaryColor, secondaryColor.withValues(alpha: 0.85)]
                  : [primaryDarkColor, primaryColor],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                bottom: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                right: 30,
                top: -60,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL COLLECTIONS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 1.5,
                        ),
                      ),
                      _buildGrowthBadge(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currencyFormatter.format(stats.totalFeesCollected),
                    style: GoogleFonts.outfit(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Collection Efficiency Rate',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${rate.toStringAsFixed(1)}% Collected',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: (rate / 100.0).clamp(0.0, 1.0),
                                strokeWidth: 4.5,
                                backgroundColor: Colors.white.withValues(alpha: 0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              const Icon(
                                Icons.percent_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: stats.pendingFees < 0 ? 'Advance Fees' : 'Pending Fees',
                value: currencyFormatter.format(stats.pendingFees.abs()),
                icon: stats.pendingFees < 0 ? Icons.account_balance_wallet_rounded : Icons.pending_actions_rounded,
                iconColor: stats.pendingFees < 0 ? const Color(0xFF10B981) : const Color(0xFFFFB4AB),
                iconBackgroundColor: stats.pendingFees < 0 ? const Color(0xFF064E3B) : const Color(0xFF93000A),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Active Students',
                value: stats.totalStudents.toString(),
                icon: Icons.group_rounded,
                iconColor: secondaryColor,
                iconBackgroundColor: const Color(0xFF571BC1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrowthBadge() {
    final isPositive = stats.isNewGrowth || stats.growthPercentage > 0;
    final isNegative = stats.growthPercentage < 0;
    final icon = stats.isNewGrowth || isPositive
        ? Icons.trending_up_rounded
        : isNegative
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;
    final label = stats.isNewGrowth
        ? 'NEW'
        : stats.growthPercentage == 0
            ? '0%'
            : '${isPositive ? '+' : '-'}${_formatPercentage(stats.growthPercentage.abs())}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPercentage(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

class _QuickActionsRow extends ConsumerWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = AppColors.isDarkMode;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final secondaryColor = isDark ? const Color(0xFFD0BCFF) : const Color(0xFF7C3AED);

    Future<void> onAddStudentTap() async {
      final FeatureGate gate = ref.read(featureGateProvider).valueOrNull 
          ?? await ref.read(featureGateProvider.future);
      if (!gate.canAddStudent) {
        if (context.mounted) {
          await showPaywallDialog(
            context,
            ref,
            trigger: PaywallTrigger.studentLimit,
          );
        }
        return;
      }
      if (context.mounted) {
        context.push('/students/add');
      }
    }

    return Row(
      children: [
        _QuickAction(
          label: 'Batches',
          icon: Icons.layers_rounded,
          onTap: () => context.go('/batches'),
          actionColor: primaryColor,
        ),
        const SizedBox(width: 12),
        _QuickAction(
          label: 'Add Student',
          icon: Icons.person_add_rounded,
          onTap: onAddStudentTap,
          actionColor: secondaryColor,
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
    final surfaceColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 104,
          decoration: BoxDecoration(
            color: surfaceColor.withValues(alpha: isDark ? 0.75 : 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.02),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: actionColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: actionColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textPrimaryColor,
                  letterSpacing: -0.1,
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
  final bool isDark;
  const _LoadingPlaceholder({required this.height, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ErrorPlaceholder({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(child: Text(message, style: const TextStyle(color: Color(0xFFDC2626)))),
    );
  }
}
