import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../models/subscription.dart';
import '../../../providers/subscription_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAnnual = false;
  int _selectedComparePlanIndex = 1; // Default to Starter (index 1)
  bool _showDetailedMatrix = false;
  bool _initializedPlanIndex = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(subscriptionScreenDataProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError(err),
        data: (data) {
          if (!_initializedPlanIndex) {
            final tier = data.subscription.effectivePlan;
            _selectedComparePlanIndex = _getCurrentPlanIndex(tier);
            _initializedPlanIndex = true;
          }
          return _buildContent(data);
        },
      ),
    );
  }

  int _getCurrentPlanIndex(String tier) {
    switch (tier) {
      case 'starter':
        return 1;
      case 'growth':
        return 2;
      default:
        return 0;
    }
  }

  // ─── Error state ──────────────────────────────────────────────────────────

  Widget _buildError(Object err) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(null),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Could not load subscription info',
                  style: GoogleFonts.manrope(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(subscriptionScreenDataProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Main content ─────────────────────────────────────────────────────────

  Widget _buildContent(SubscriptionScreenData data) {
    final sub = data.subscription;
    return CustomScrollView(
      slivers: [
        _buildAppBar(sub),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildCurrentPlanCard(sub, data),
                const SizedBox(height: 24),
                _buildUsageLimitsCard(sub, data),
                const SizedBox(height: 24),
                _buildBillingToggle(),
                const SizedBox(height: 16),
                _buildPlanComparison(sub),
                const SizedBox(height: 28),
                _buildReferralCard(),
                const SizedBox(height: 28),
                _buildFaqSection(),
                const SizedBox(height: 28),
                _buildPolicyFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── App bar ──────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(Subscription? sub) {
    return SliverAppBar(
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Subscription & Plan',
        style: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        if (sub != null)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: _planGradient(sub.effectivePlan),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sub.planLabel.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Current plan card ────────────────────────────────────────────────────

  Widget _buildCurrentPlanCard(Subscription sub, SubscriptionScreenData data) {
    final expiryText = sub.validUntil != null && !sub.isFree
        ? 'Renews ${DateFormat('d MMM yyyy').format(sub.validUntil!)}'
        : sub.isFree
            ? 'No expiry — upgrade anytime'
            : 'Expired';

    final daysLeft = sub.daysRemaining;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      gradientColors: [
        _planColor(sub.effectivePlan).withValues(alpha: 0.15),
        Colors.transparent,
      ],
      borderColor: _planColor(sub.effectivePlan).withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: _planGradient(sub.effectivePlan),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _planIcon(sub.effectivePlan),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sub.planLabel} Plan',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expiryText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: sub.isActive
                            ? AppColors.textTertiary
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              if (sub.monthlyPriceInr > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${sub.monthlyPriceInr}',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _planColor(sub.effectivePlan),
                      ),
                    ),
                    Text(
                      '/month',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (daysLeft != null && daysLeft <= 14) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (daysLeft <= 7 ? AppColors.error : AppColors.pending)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (daysLeft <= 7 ? AppColors.error : AppColors.pending)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: daysLeft <= 7 ? AppColors.error : AppColors.pending,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    daysLeft == 0
                        ? 'Expires today — renew now!'
                        : '$daysLeft days left — renew to avoid service interruption',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          daysLeft <= 7 ? AppColors.error : AppColors.pending,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (!sub.isGrowth)
            SizedBox(
              width: double.infinity,
              child: _GradientButton(
                label: sub.isFree ? 'Upgrade to Starter' : 'Upgrade to Growth',
                gradient: _planGradient('growth'),
                onTap: () => _showUpgradeSheet(sub),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'You\'re on the highest plan',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Usage limits card ────────────────────────────────────────────────────

  Widget _buildUsageLimitsCard(Subscription sub, SubscriptionScreenData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Usage & Limits'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildUsageRow(
                icon: Icons.people_alt_rounded,
                iconColor: AppColors.primary,
                label: 'Active Students',
                used: data.activeStudentCount,
                max: sub.currentMaxStudents,
                ratio: data.studentUsageRatio,
                isNearLimit: data.isNearLimit,
                isAtLimit: data.isAtLimit,
                limitName: 'student',
              ),
              const SizedBox(height: 16),

              Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 16),

              _buildUsageRow(
                icon: Icons.class_rounded,
                iconColor: const Color(0xFF8B5CF6),
                label: 'Active Batches',
                used: data.activeBatchCount,
                max: sub.currentMaxBatches,
                ratio: data.batchUsageRatio,
                isNearLimit: data.batchUsageRatio >= 0.8,
                isAtLimit: data.isAtBatchLimit,
                limitName: 'batch',
              ),
              const SizedBox(height: 16),

              Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 16),

              _buildUsageRow(
                icon: Icons.admin_panel_settings_rounded,
                iconColor: const Color(0xFFF59E0B),
                label: 'Active Staff',
                used: data.activeStaffCount,
                max: sub.maxStaff,
                ratio: data.staffUsageRatio,
                isNearLimit: data.isNearStaffLimit,
                isAtLimit: data.isAtStaffLimit,
                limitName: 'staff',
              ),
              const SizedBox(height: 16),

              Divider(color: AppColors.outline.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 16),

              _buildUsageRow(
                icon: Icons.chat_rounded,
                iconColor: const Color(0xFF25D366),
                label: 'WhatsApp Receipts/mo',
                used: data.waReceiptsUsed,
                max: sub.currentWaReceiptsLimit,
                ratio: data.waReceiptsUsageRatio,
                isNearLimit: data.isNearWaReceiptsLimit,
                isAtLimit: data.isAtWaReceiptsLimit,
                limitName: 'WhatsApp receipts',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsageRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int used,
    required int max,
    double? ratio,
    bool isNearLimit = false,
    bool isAtLimit = false,
    String? suffix,
    bool isSimpleLabel = false,
    String limitName = 'limit',
  }) {
    final isUnlimited = max <= 0;
    final progressColor = isAtLimit
        ? AppColors.error
        : isNearLimit
            ? AppColors.pending
            : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              suffix ??
                  (isUnlimited
                      ? 'Unlimited'
                      : '$used / $max'),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isAtLimit
                    ? AppColors.error
                    : isNearLimit
                        ? AppColors.pending
                        : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (!isSimpleLabel && ratio != null && !isUnlimited) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.outline.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          if (isNearLimit)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                isAtLimit
                    ? '⚠️ ${limitName[0].toUpperCase()}${limitName.substring(1)} limit reached — upgrade to add more'
                    : '⚠️ Approaching $limitName limit — consider upgrading',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: progressColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ],
    );
  }




  Widget _buildBillingToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Monthly',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: !_isAnnual
                ? AppColors.textPrimary
                : AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => setState(() => _isAnnual = !_isAnnual),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: _isAnnual ? AppGradients.primary : null,
              color: _isAnnual ? null : AppColors.outline.withValues(alpha: 0.3),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment:
                  _isAnnual ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            Text(
              'Annual',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isAnnual
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 6),
            if (_isAnnual)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '2 months FREE',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ─── Plan comparison ──────────────────────────────────────────────────────

  Widget _buildComparePlanPills() {
    final tiers = ['free', 'starter', 'growth'];
    final labels = ['Free', 'Starter', 'Growth'];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: List.generate(3, (index) {
          final isSelected = _selectedComparePlanIndex == index;
          final tier = tiers[index];
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedComparePlanIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: isSelected ? _planGradient(tier) : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _planColor(tier).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildComparePlanCard(Subscription currentSub) {
    final plans = SubscriptionPlan.all;
    final plan = plans[_selectedComparePlanIndex];
    final tier = plan.tier;
    
    final isCurrent = tier == currentSub.effectivePlan;
    final price = _isAnnual ? plan.annualPrice : plan.monthlyPrice;
        
    final themeColor = _planColor(tier);
    
    final List<String> highlights;
    switch (tier) {
      case 'growth':
        highlights = [
          'Unlimited student capacity',
          'Unlimited batches & groups',
          'Full AI intelligence suite (all 9 features)',
          'Razorpay Auto-Debit collection support',
          'WhatsApp call & chat official support',
          'Scheduled automated PDF email reports',
          'Up to 500 fallback transactional SMS/mo',
        ];
        break;
      case 'starter':
        highlights = [
          'Up to 200 active students (10x Free limit)',
          'Up to 10 batches / classes',
          'Unlimited automated WhatsApp receipts',
          'Full reports collection access (14 reports)',
          'AI assistance (3 smart features)',
          'Razorpay standard payment links',
          'Export all reports & student lists to CSV',
        ];
        break;
      default:
        highlights = [
          'Up to 20 active students',
          '1 Batch limit',
          '200 WhatsApp Receipts per month',
          '50 WhatsApp Reminders per month',
          'Basic Reports access (5 types)',
        ];
        break;
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderColor: themeColor.withValues(alpha: 0.35),
      gradientColors: [
        themeColor.withValues(alpha: 0.08),
        themeColor.withValues(alpha: 0.02),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _planGradient(tier),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(
                  _planIcon(tier),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.name,
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: themeColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Active',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: themeColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tier == 'growth'
                          ? 'Ultimate plan for scaling coaching centers'
                          : tier == 'starter'
                              ? 'Best value for growing coaching hubs'
                              : 'Kickstart your school management',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price == 0 ? 'Free' : '₹$price',
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (price > 0) ...[
                const SizedBox(width: 6),
                Text(
                  _isAnnual ? '/year' : '/month',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          if (price > 0 && _isAnnual) ...[
            const SizedBox(height: 4),
            Text(
              'Billed annually (Includes 2 months free!)',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Divider(
            color: AppColors.outline.withValues(alpha: 0.1),
            height: 1,
          ),
          const SizedBox(height: 20),
          ...highlights.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: themeColor == AppColors.textTertiary
                            ? AppColors.primary
                            : themeColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.outline.withValues(alpha: 0.1)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Your Active Plan',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : _selectedComparePlanIndex == 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.outline.withValues(alpha: 0.3)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Downgrade details on web portal',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      )
                    : _GradientButton(
                        label: _selectedComparePlanIndex == 1
                            ? 'Upgrade to Starter'
                            : 'Upgrade to Growth',
                        gradient: _planGradient(tier),
                        onTap: () => _showUpgradeSheet(currentSub),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanComparison(Subscription currentSub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Compare Plans'),
        const SizedBox(height: 12),
        _buildComparePlanPills(),
        const SizedBox(height: 16),
        _buildComparePlanCard(currentSub),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _showDetailedMatrix = !_showDetailedMatrix),
            icon: Icon(
              _showDetailedMatrix
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
            ),
            label: Text(
              _showDetailedMatrix
                  ? 'Hide Detailed Comparison Matrix'
                  : 'View Detailed Comparison Matrix',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        if (_showDetailedMatrix) ...[
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicWidth(
                child: Column(
                  children: [
                    _buildPlanHeaderRow(currentSub),
                    const SizedBox(height: 12),
                    ..._comparisonRows.asMap().entries.map(
                      (entry) => _buildComparisonRow(entry.value, currentSub, entry.key),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlanHeaderRow(Subscription currentSub) {
    final plans = SubscriptionPlan.all;

    return Row(
      children: [
        _comparisonLabelCell(''),
        ...plans.map(
          (plan) {
            final isCurrent = plan.tier == currentSub.effectivePlan;
            final price = _isAnnual ? plan.annualPrice : plan.monthlyPrice;
            final priceLabel = price == 0
                ? 'Free'
                : '₹$price/${_isAnnual ? 'yr' : 'mo'}';

            return Container(
              width: 100,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                gradient: isCurrent ? _planGradient(plan.tier) : null,
                color: isCurrent ? null : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: isCurrent
                    ? null
                    : Border.all(
                        color: AppColors.outline.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Icon(
                    _planIcon(plan.tier),
                    color:
                        isCurrent ? Colors.white : _planColor(plan.tier),
                    size: 18,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.name,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isCurrent
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    priceLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCurrent
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textTertiary,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Current',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildComparisonRow(
      _ComparisonRow row, Subscription currentSub, int index) {
    final isAlternate = index % 2 == 1;
    return Container(
      decoration: BoxDecoration(
        color: isAlternate
            ? AppColors.surfaceContainerLow.withValues(alpha: 0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _comparisonLabelCell(row.label),
          ...SubscriptionPlan.all.map(
            (plan) {
              final isCurrent = plan.tier == currentSub.effectivePlan;
              final value = row.getValue(plan);
              return _comparisonValueCell(value, isCurrent);
            },
          ),
        ],
      ),
    );
  }

  Widget _comparisonLabelCell(String label) {
    return SizedBox(
      width: 130,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _comparisonValueCell(String value, bool isCurrent) {
    final isCheck = value == '✓';
    final isCross = value == '✗';
    return SizedBox(
      width: 108,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Center(
          child: isCheck
              ? Icon(Icons.check_circle_rounded,
                  color: isCurrent
                      ? AppColors.primary
                      : AppColors.success,
                  size: 18)
              : isCross
                  ? Icon(Icons.cancel_rounded,
                      color: AppColors.outline.withValues(alpha: 0.3), size: 16)
                  : Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
        ),
      ),
    );
  }

  // ─── Referral card ────────────────────────────────────────────────────────

  Widget _buildReferralCard() {
    const referralCode = 'FEESYNC100'; // Replace with dynamic code from user profile
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.35),
      gradientColors: [
        const Color(0xFFF59E0B).withValues(alpha: 0.08),
        Colors.transparent,
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                'Refer & Earn',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Invite other coaching centers to FeeSync and both of you get ₹100 off your next month.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    referralCode,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF59E0B),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: referralCode));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Referral code copied!',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSuccess)),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.copy_rounded,
                      color: Color(0xFFF59E0B), size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── FAQ section ──────────────────────────────────────────────────────────

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Frequently Asked Questions'),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: _faqItems.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    title: Text(
                      item.question,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    iconColor: AppColors.primary,
                    collapsedIconColor: AppColors.textTertiary,
                    children: [
                      Text(
                        item.answer,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                  if (i < _faqItems.length - 1)
                    Divider(
                      color: AppColors.outline.withValues(alpha: 0.1),
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Policy footer ────────────────────────────────────────────────────────

  Widget _buildPolicyFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Payment integration coming soon. Prices are in INR and include applicable taxes.',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textTertiary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            GestureDetector(
              onTap: () => context.push('/settings/policy?type=terms'),
              child: Text(
                'Terms of Service',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/settings/policy?type=privacy'),
              child: Text(
                'Privacy Policy',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/settings/policy?type=refund'),
              child: Text(
                'Refund Policy',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Upgrade bottom sheet ─────────────────────────────────────────────────

  void _showUpgradeSheet(Subscription currentSub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UpgradeSheet(
        currentSub: currentSub,
        isAnnual: _isAnnual,
        onToggle: () => setState(() => _isAnnual = !_isAnnual),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  LinearGradient _planGradient(String tier) {
    switch (tier) {
      case 'starter':
        return const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
        );
      case 'growth':
        return const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF475569), Color(0xFF64748B)],
        );
    }
  }

  Color _planColor(String tier) {
    switch (tier) {
      case 'starter':
        return const Color(0xFF2563EB);
      case 'growth':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.textTertiary;
    }
  }

  IconData _planIcon(String tier) {
    switch (tier) {
      case 'starter':
        return Icons.bolt_rounded;
      case 'growth':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.spa_rounded;
    }
  }

  SubscriptionPlan _getPlanByTier(String tier) {
    return SubscriptionPlan.all.firstWhere(
      (p) => p.tier == tier,
      orElse: () => SubscriptionPlan.free,
    );
  }
}

// ─── Comparison row model ─────────────────────────────────────────────────────

class _ComparisonRow {
  final String label;
  final String Function(SubscriptionPlan) getValue;

  const _ComparisonRow(this.label, this.getValue);
}

final _comparisonRows = <_ComparisonRow>[
  _ComparisonRow('Active Students', (p) {
    if (p.maxStudents == -1) return 'Unlimited';
    return 'Up to ${p.maxStudents}';
  }),
  _ComparisonRow('Batches', (p) {
    if (p.maxBatches == -1) return 'Unlimited';
    return 'Up to ${p.maxBatches}';
  }),
  _ComparisonRow('WhatsApp Receipts', (p) {
    if (p.whatsappReceiptsPerMonth == -1) return 'Unlimited';
    return '${p.whatsappReceiptsPerMonth}/mo';
  }),
  _ComparisonRow('WA Reminders', (p) {
    if (p.whatsappRemindersPerMonth == -1) return 'Unlimited';
    return '${p.whatsappRemindersPerMonth}/mo';
  }),
  _ComparisonRow('Staff Accounts', (p) {
    if (p.maxStaff == -1) return 'Unlimited';
    return '${p.maxStaff} staff';
  }),
  _ComparisonRow('Biometric Auth', (p) => p.biometricAuth ? '✓' : '✗'),
  _ComparisonRow('Support System', (p) => p.supportSystem ? '✓' : '✗'),
  _ComparisonRow('Cloud Backup', (p) => p.cloudBackup ? '✓' : '✗'),
  _ComparisonRow('Due Reminders', (p) => p.dueReminders ? '✓' : '✗'),
  _ComparisonRow('Invoice Send', (p) => p.invoiceSend ? '✓' : '✗'),
  _ComparisonRow('CSV Export', (p) => p.csvExport ? '✓' : '✗'),
];

// ─── FAQ items ────────────────────────────────────────────────────────────────

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

final _faqItems = <_FaqItem>[
  _FaqItem(
    'How does billing work?',
    'Payment integration is coming soon. Once launched, you will be able to subscribe directly within the app securely.',
  ),
  _FaqItem(
    'Can I upgrade or downgrade at any time?',
    'Yes. You can upgrade at any time and the new plan activates immediately (pro-rated). To downgrade, your current plan remains active until the end of the billing period, then the lower tier kicks in.',
  ),
  _FaqItem(
    'What happens when I reach the student limit?',
    'When you reach your plan\'s student limit, you won\'t be able to add new students until you upgrade. Your existing data and access are fully preserved. You\'ll see an in-app upgrade prompt.',
  ),
  _FaqItem(
    'Is my fee collection data safe if I cancel?',
    'Absolutely. If you cancel or downgrade, your data is preserved in read-only mode for 7 days. You can export your data to CSV or Excel at any time while you have access.',
  ),
  _FaqItem(
    'What\'s the refund policy?',
    'Refund policies will be available once our payment integration goes live. We aim to provide fair, prorated options.',
  ),
  _FaqItem(
    'Do WhatsApp messages cost extra?',
    'No. WhatsApp notifications are included in your plan limits. The Starter plan includes unlimited receipts and reminders. Free plan includes 100 receipts and 30 reminders per month.',
  ),
  _FaqItem(
    'How does the referral program work?',
    'Share your unique referral code with another coaching center. When they sign up and start a paid plan, both of you get ₹100 off your next monthly bill. There\'s no limit on how many people you can refer.',
  ),
];

// ─── Upgrade bottom sheet widget ──────────────────────────────────────────────

class _UpgradeSheet extends StatelessWidget {
  final Subscription currentSub;
  final bool isAnnual;
  final VoidCallback onToggle;

  const _UpgradeSheet({
    required this.currentSub,
    required this.isAnnual,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final plans = SubscriptionPlan.all
        .where((p) => p.tier != 'free' && p.tier != currentSub.effectivePlan)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose Your Plan',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Unlock more students, AI features, and premium support.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          ...plans.map((plan) => _PlanOptionCard(
                plan: plan,
                isAnnual: isAnnual,
                onSelect: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Payment integration coming soon',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primaryContainer,
                    ),
                  );
                },
              )),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Subscriptions will be managed securely in-app',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanOptionCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isAnnual;
  final VoidCallback onSelect;

  const _PlanOptionCard({
    required this.plan,
    required this.isAnnual,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final price = isAnnual ? plan.annualPrice : plan.monthlyPrice;
    final isGrowth = plan.tier == 'growth';

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isGrowth
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                )
              : null,
          color: isGrowth ? null : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: isGrowth
              ? null
              : Border.all(
                  color: AppColors.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              isGrowth
                  ? Icons.workspace_premium_rounded
                  : Icons.bolt_rounded,
              color: isGrowth ? Colors.white : const Color(0xFF2563EB),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isGrowth
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    isGrowth
                        ? 'Unlimited students + Cloud Backup & Support'
                        : 'Up to ${plan.maxStudents} students + Backup',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isGrowth
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹$price',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isGrowth ? Colors.white : AppColors.primary,
                  ),
                ),
                Text(
                  '/${isAnnual ? 'year' : 'month'}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isGrowth
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gradient button helper ───────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
