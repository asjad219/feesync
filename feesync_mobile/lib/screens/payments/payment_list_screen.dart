import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/payment_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/payment.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../core/widgets/glass/glass_card.dart';
import '../../core/widgets/offline_widgets.dart';
import '../../core/widgets/permission_guard.dart';

class PaymentListScreen extends ConsumerStatefulWidget {
  final String? studentId;
  const PaymentListScreen({super.key, this.studentId});

  @override
  ConsumerState<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends ConsumerState<PaymentListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    ref.read(paymentNotifierProvider.notifier).loadPayments();
    ref.invalidate(todayCollectionProvider);
    ref.invalidate(monthCollectionProvider);
    if (widget.studentId != null) {
      ref.invalidate(studentPaymentsProvider(widget.studentId!));
    }
  }

  @override
    Widget build(BuildContext context) {
      final paymentsAsync = widget.studentId != null 
          ? ref.watch(studentPaymentsProvider(widget.studentId!))
          : ref.watch(filteredPaymentsProvider);

      // Apply local filtering for student specific view
      final filteredAsync = widget.studentId != null
          ? paymentsAsync.whenData((payments) {
              final search = ref.watch(paymentSearchProvider).toLowerCase();
              final statusFilter = ref.watch(paymentStatusFilterProvider);
              
              return payments.where((payment) {
                final matchesSearch = search.isEmpty ||
                    (payment.receiptNumber?.toLowerCase().contains(search) ?? false) ||
                    (payment.transactionId?.toLowerCase().contains(search) ?? false);
                
                final matchesStatus = statusFilter == null || payment.status == statusFilter;

                return matchesSearch && matchesStatus;
              }).toList();
            })
          : paymentsAsync;

      return PermissionGuard(
        permission: 'view_payments',
        child: Scaffold(
          backgroundColor: AppColors.darkBg,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(),
              if (widget.studentId == null) _buildStatsSection(),
              _buildFiltersSection(),
              _buildPaymentsList(filteredAsync),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
          floatingActionButton: _buildFAB(),
        ),
      );
    }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      title: Text(
        widget.studentId != null ? 'Payment History' : 'Payments',
        style: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.6,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _refreshData,
          icon: Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildStatsSection() {
    final todayAsync = ref.watch(todayCollectionProvider);
    final monthAsync = ref.watch(monthCollectionProvider);
    final currencyCode = ref.watch(settingsProvider).value?.currency;
    final compactCurrency = CurrencyFormatter.compactNumberFormat(currencyCode, decimalDigits: 1);
    final currencySymbol = CurrencyFormatter.symbolFor(currencyCode);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'TODAY',
                asyncValue: todayAsync,
                color: AppColors.primary,
                icon: Icons.today_rounded,
                compactCurrencyFormatter: compactCurrency,
                currencySymbol: currencySymbol,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'THIS MONTH',
                asyncValue: monthAsync,
                color: const Color(0xFF8B5CF6), // Violet-ish
                icon: Icons.calendar_month_rounded,
                compactCurrencyFormatter: compactCurrency,
                currencySymbol: currencySymbol,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    final currentStatus = ref.watch(paymentStatusFilterProvider);
    final bool isDark = AppColors.isDarkMode;
    final Color surfaceColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
    final Color textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: surfaceColor.withValues(alpha: isDark ? 0.75 : 0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                  width: 1.0,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textPrimaryColor, fontSize: 14),
                onChanged: (value) => ref.read(paymentSearchProvider.notifier).state = value,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintText: 'Search payments...',
                  prefixIcon: Icon(Icons.search_rounded, color: textTertiaryColor, size: 18),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  hintStyle: TextStyle(color: textTertiaryColor.withValues(alpha: 0.5), fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  FilterChipButton(
                    label: 'All',
                    isSelected: currentStatus == null,
                    onTap: () => ref.read(paymentStatusFilterProvider.notifier).state = null,
                  ),
                  const SizedBox(width: 8),
                  FilterChipButton(
                    label: 'Completed',
                    isSelected: currentStatus == PaymentStatus.completed,
                    onTap: () => ref.read(paymentStatusFilterProvider.notifier).state = PaymentStatus.completed,
                  ),
                  const SizedBox(width: 8),
                  FilterChipButton(
                    label: 'Pending',
                    isSelected: currentStatus == PaymentStatus.pending,
                    onTap: () => ref.read(paymentStatusFilterProvider.notifier).state = PaymentStatus.pending,
                  ),
                  const SizedBox(width: 8),
                  FilterChipButton(
                    label: 'Cancelled',
                    isSelected: currentStatus == PaymentStatus.cancelled,
                    onTap: () => ref.read(paymentStatusFilterProvider.notifier).state = PaymentStatus.cancelled,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsList(AsyncValue<List<Payment>> paymentsAsync) {
    final currency = CurrencyFormatter.numberFormat(ref.watch(settingsProvider).value?.currency, decimalDigits: 0);

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return SliverFillRemaining(
            child: _EmptyPaymentsState(isFiltered: _searchController.text.isNotEmpty || ref.read(paymentStatusFilterProvider) != null),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final payment = payments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PaymentTransactionCard(payment: payment, currencyFormatter: currency),
                );
              },
              childCount: payments.length,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: ShimmerList(itemCount: 5, itemHeight: 106),
        ),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(
          child: Text('No payments available', style: TextStyle(color: AppColors.textTertiary)),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => context.push('/payments/record'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_card_rounded, size: 28, color: Colors.white),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final AsyncValue<Map<String, dynamic>> asyncValue;
  final Color color;
  final IconData icon;
  final NumberFormat compactCurrencyFormatter;
  final String currencySymbol;

  const _StatCard({
    required this.label,
    required this.asyncValue,
    required this.color,
    required this.icon,
    required this.compactCurrencyFormatter,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final cardColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    final cardBg = isDark
        ? LinearGradient(
            colors: [color.withValues(alpha: 0.04), cardColor.withValues(alpha: 0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [color.withValues(alpha: 0.02), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final border = Border.all(
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
      width: 1.5,
    );

    final shadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ];

    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: border,
        boxShadow: shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark 
                      ? color.withValues(alpha: 0.12)
                      : color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textTertiaryColor,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          asyncValue.when(
            data: (data) => Text(
              compactCurrencyFormatter.format(data['total'] ?? 0),
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: textPrimaryColor,
                letterSpacing: -0.5,
              ),
            ),
            loading: () => SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
            ),
            error: (_, _) => Text(
              '${currencySymbol}0', 
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: textPrimaryColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTransactionCard extends StatelessWidget {
  final Payment payment;
  final NumberFormat currencyFormatter;
  const _PaymentTransactionCard({required this.payment, required this.currencyFormatter});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(payment.paymentDate);
    
    Color statusColor;
    switch (payment.status) {
      case PaymentStatus.completed:
        statusColor = const Color(0xFF10B981); // Green
        break;
      case PaymentStatus.pending:
        statusColor = const Color(0xFFF59E0B); // Orange
        break;
      case PaymentStatus.cancelled:
      case PaymentStatus.refunded:
        statusColor = const Color(0xFFEF4444); // Red
        break;
    }

    IconData methodIcon;
    switch (payment.paymentMethod) {
      case PaymentMethod.cash:
        methodIcon = Icons.payments_rounded;
        break;
      case PaymentMethod.bankTransfer:
        methodIcon = Icons.account_balance_rounded;
        break;
      case PaymentMethod.mobileMoney:
        methodIcon = Icons.phone_android_rounded;
        break;
      case PaymentMethod.card:
        methodIcon = Icons.credit_card_rounded;
        break;
      default:
        methodIcon = Icons.receipt_long_rounded;
    }

    return GlassCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (payment.studentId.isNotEmpty) {
              context.push('/students/${payment.studentId}');
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(methodIcon, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.student?.fullName ?? 'Unknown Student',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${payment.student?.studentClass ?? '--'} • ID: ${payment.student?.admissionNumber ?? '--'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              payment.status.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          if (payment.isOffline) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.cloud_upload_outlined, size: 14, color: AppColors.textTertiary),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormatter.format(payment.amount),
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPaymentMethod(payment.paymentMethod),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bankTransfer:
        return 'BANK TRANSFER';
      case PaymentMethod.mobileMoney:
        return 'MOBILE MONEY';
      default:
        return method.name.toUpperCase();
    }
  }
}

class _EmptyPaymentsState extends StatelessWidget {
  final bool isFiltered;
  const _EmptyPaymentsState({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.isDarkMode 
                  ? AppColors.surfaceContainer.withValues(alpha: 0.5) 
                  : Colors.black.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFiltered ? Icons.search_off_rounded : Icons.history_rounded,
              size: 64,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered ? 'No matches found' : 'No transactions yet',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered 
              ? 'Try adjusting your search or filters'
              : 'Your payment history will appear here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}