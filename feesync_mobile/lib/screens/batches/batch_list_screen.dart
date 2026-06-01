import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/kpi_card.dart';
import '../../../providers/batch_provider.dart';
import '../../../models/batch.dart';
import 'widgets/batch_card.dart';

class BatchListScreen extends ConsumerWidget {
  const BatchListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(batchNotifierProvider);
    final search = ref.watch(batchSearchProvider);
    final statusFilter = ref.watch(batchStatusFilterProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkBg,
              AppColors.darkBg.withBlue(40).withOpacity(0.8),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => ref.read(batchNotifierProvider.notifier).loadBatches(),
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceContainer,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildAppBar(context, ref),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 0, 10),
                  child: _buildKpiSection(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: _buildSearchAndFilters(context, ref, search),
                ),
              ),

              batchesAsync.when(
                data: (batches) {
                  final filteredBatches = batches.where((b) {
                    final matchesSearch = search.isEmpty || 
                        b.name.toLowerCase().contains(search.toLowerCase()) ||
                        b.subject.toLowerCase().contains(search.toLowerCase());
                    final matchesStatus = statusFilter == null || b.status == statusFilter;
                    return matchesSearch && matchesStatus;
                  }).toList();

                  return filteredBatches.isEmpty
                      ? _buildEmptyState()
                      : SliverPadding(
                          padding: const EdgeInsets.all(20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final batch = filteredBatches[index];
                                return BatchCard(
                                  batch: batch,
                                  onView: () => context.push('/batches/${batch.id}'),
                                  onMarkAttendance: () => context.push('/batches/${batch.id}?tab=2'),
                                  onAddStudent: () => context.push('/students/add?batchId=${batch.id}'),
                                );
                              },
                              childCount: filteredBatches.length,
                            ),
                          ),
                        );
                },
                loading: () => _buildLoadingState(),
                error: (err, stack) => _buildErrorState(err.toString()),
              ),

              // Bottom padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildPremiumFab(context),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.darkBg.withOpacity(0.8),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coaching Batches',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildAiInsightChip(),
                ],
              ),
              Row(
                children: [
                  _AppBarIcon(icon: Icons.notifications_none_outlined, onPressed: () {}),
                  const SizedBox(width: 12),
                  _AppBarIcon(icon: Icons.settings_outlined, onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiInsightChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 14),
          const SizedBox(width: 6),
          Text(
            '3 batches nearing capacity',
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: const [
          KpiCard(
            title: 'Active Batches',
            value: '12',
            icon: Icons.layers_outlined,
            color: Colors.blueAccent,
            trend: 0.08,
          ),
          KpiCard(
            title: 'Total Students',
            value: '248',
            icon: Icons.people_outline,
            color: Colors.purpleAccent,
            trend: 0.12,
          ),
          KpiCard(
            title: 'Attendance Health',
            value: '94%',
            icon: Icons.analytics_outlined,
            color: Colors.greenAccent,
            trend: -0.02,
          ),
          KpiCard(
            title: 'Monthly Revenue',
            value: '₹1.2L',
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.orangeAccent,
            trend: 0.15,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, WidgetRef ref, String search) {
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(16),
          child: TextField(
            onChanged: (val) => ref.read(batchSearchProvider.notifier).state = val,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search batches...',
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
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

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              'No batches found',
              style: GoogleFonts.manrope(
                color: Colors.white.withOpacity(0.5),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SliverFillRemaining(
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildErrorState(String error) {
    return SliverFillRemaining(
      child: Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildPremiumFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => context.push('/batches/create'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }
}

class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AppBarIcon({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.black : Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
