import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paywall_dialog.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../models/batch.dart';
import 'widgets/batch_card.dart';

class BatchListScreen extends ConsumerWidget {
  const BatchListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(batchNotifierProvider);
    final search = ref.watch(batchSearchProvider);
    final statusFilter = ref.watch(batchStatusFilterProvider);
    final subDataAsync = ref.watch(subscriptionScreenDataProvider);

    final batches = batchesAsync.valueOrNull;

    final bool isDark = AppColors.isDarkMode;
    final Color primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final Color scaffoldBgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFC);
    final Color textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final Color surfaceColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);

    // Paywall check: can the user add another batch?
    Future<void> onAddBatchTap() async {
      final data = subDataAsync.valueOrNull;
      if (data != null && !data.canAddBatch) {
        await showPaywallDialog(
          context,
          ref,
          trigger: PaywallTrigger.batchLimit,
        );
        return;
      }
      if (context.mounted) context.push('/batches/create');
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      extendBodyBehindAppBar: true,
      appBar: const _BatchesTopBar(),
      body: RefreshIndicator(
        onRefresh: () => ref.read(batchNotifierProvider.notifier).loadBatches(),
        color: primaryColor,
        backgroundColor: isDark ? const Color(0xFF12121F) : const Color(0xFFFFFFFF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 128, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAiInsightChip(isDark, primaryColor, batches),
                const SizedBox(height: 20),
                _buildKpiSection(isDark, primaryColor, batches),
                const SizedBox(height: 24),
                _buildSearchAndFilters(context, ref, search, isDark, primaryColor, surfaceColor, textPrimaryColor),
                const SizedBox(height: 20),
                batchesAsync.when(
                  data: (batches) {
                    final filteredBatches = batches.where((b) {
                      final matchesSearch = search.isEmpty || 
                          b.name.toLowerCase().contains(search.toLowerCase()) ||
                          b.subject.toLowerCase().contains(search.toLowerCase());
                      final matchesStatus = statusFilter == null || b.status == statusFilter;
                      return matchesSearch && matchesStatus;
                    }).toList();

                    if (filteredBatches.isEmpty) {
                      return _buildEmptyState(isDark);
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: filteredBatches.length,
                      itemBuilder: (context, index) {
                        final batch = filteredBatches[index];
                        return BatchCard(
                          batch: batch,
                          onView: () => context.push('/batches/${batch.id}'),
                          onMarkAttendance: () => context.push('/batches/${batch.id}?tab=2'),
                          onAddStudent: () => context.push('/students/add?batchId=${batch.id}'),
                        );
                      },
                    );
                  },
                  loading: () => _buildLoadingState(primaryColor),
                  error: (err, stack) => _buildErrorState(err.toString()),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildPremiumFab(onAddBatchTap, primaryColor, isDark),
    );
  }

  String _formatRevenue(double value) {
    if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${value.toStringAsFixed(0)}';
    }
  }

  Widget _buildAiInsightChip(bool isDark, Color primaryColor, List<Batch>? batches) {
    if (batches == null || batches.isEmpty) return const SizedBox.shrink();
    
    final nearingCapacityCount = batches.where((b) => b.maxCapacity > 0 && (b.studentCount / b.maxCapacity) >= 0.8).length;
    final message = nearingCapacityCount == 0 
        ? 'All batches have optimal capacity' 
        : '$nearingCapacityCount batch${nearingCapacityCount == 1 ? '' : 'es'} nearing capacity';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: primaryColor, size: 14),
          const SizedBox(width: 6),
          Text(
            message,
            style: GoogleFonts.inter(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection(bool isDark, Color primaryColor, List<Batch>? batches) {
    final secondaryColor = isDark ? const Color(0xFFD0BCFF) : const Color(0xFF7C3AED);

    final String activeBatchesVal;
    final String totalStudentsVal;
    final String attendanceHealthVal;
    final String monthlyRevenueVal;

    if (batches == null) {
      activeBatchesVal = '--';
      totalStudentsVal = '--';
      attendanceHealthVal = '--';
      monthlyRevenueVal = '--';
    } else {
      final activeCount = batches.where((b) => b.status == BatchStatus.active).length;
      final totalStudents = batches.fold<int>(0, (sum, b) => sum + b.studentCount);
      
      final batchesWithAttendance = batches.where((b) => b.studentCount > 0).toList();
      final avgAttendance = batchesWithAttendance.isEmpty
          ? 0.0
          : batchesWithAttendance.fold<double>(0.0, (sum, b) => sum + b.attendancePercentage) / batchesWithAttendance.length;

      final totalRevenue = batches.fold<double>(0.0, (sum, b) => sum + b.revenueGenerated);

      activeBatchesVal = activeCount.toString();
      totalStudentsVal = totalStudents.toString();
      attendanceHealthVal = '${avgAttendance.round()}%';
      monthlyRevenueVal = _formatRevenue(totalRevenue);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: StatCard(
              title: 'Active Batches',
              value: activeBatchesVal,
              icon: Icons.layers_rounded,
              iconColor: primaryColor,
              iconBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 160,
            child: StatCard(
              title: 'Total Students',
              value: totalStudentsVal,
              icon: Icons.group_rounded,
              iconColor: secondaryColor,
              iconBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3E8FF),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 160,
            child: StatCard(
              title: 'Attendance Health',
              value: attendanceHealthVal,
              icon: Icons.analytics_rounded,
              iconColor: const Color(0xFF10B981),
              iconBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFECFDF5),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 160,
            child: StatCard(
              title: 'Monthly Revenue',
              value: monthlyRevenueVal,
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFFF59E0B),
              iconBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context, 
    WidgetRef ref, 
    String search, 
    bool isDark, 
    Color primaryColor, 
    Color surfaceColor,
    Color textPrimaryColor,
  ) {
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    
    return Column(
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
            onChanged: (val) => ref.read(batchSearchProvider.notifier).state = val,
            style: TextStyle(color: textPrimaryColor, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintText: 'Search batches...',
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
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: ref.watch(batchStatusFilterProvider) == null,
                onTap: () => ref.read(batchStatusFilterProvider.notifier).state = null,
              ),
              _FilterChip(
                label: 'Active',
                isSelected: ref.watch(batchStatusFilterProvider) == BatchStatus.active,
                onTap: () => ref.read(batchStatusFilterProvider.notifier).state = BatchStatus.active,
              ),
              _FilterChip(
                label: 'Upcoming',
                isSelected: ref.watch(batchStatusFilterProvider) == BatchStatus.upcoming,
                onTap: () => ref.read(batchStatusFilterProvider.notifier).state = BatchStatus.upcoming,
              ),
              _FilterChip(
                label: 'Completed',
                isSelected: ref.watch(batchStatusFilterProvider) == BatchStatus.completed,
                onTap: () => ref.read(batchStatusFilterProvider.notifier).state = BatchStatus.completed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear_rounded, size: 64, color: textTertiaryColor.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No batches found',
              style: GoogleFonts.manrope(
                color: textTertiaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator(color: primaryColor)),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildPremiumFab(VoidCallback onTap, Color primaryColor, bool isDark) {
    return Container(
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
        onPressed: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const CircleBorder(),
        child: Icon(Icons.add_rounded, size: 32, color: isDark ? const Color(0xFFDBEAFE) : Colors.white),
      ),
    );
  }
}

class _BatchesTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _BatchesTopBar();

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
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
                  Expanded(
                    child: Text(
                      'Batches',
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textPrimaryColor,
                        letterSpacing: -0.6,
                      ),
                    ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryColor 
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? primaryColor 
                : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected 
                ? (isDark ? const Color(0xFF0F172A) : Colors.white) 
                : textTertiaryColor,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
