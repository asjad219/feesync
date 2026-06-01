import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/providers.dart';
import '../../models/fee.dart';
import '../../core/widgets/custom_widgets.dart';

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(feeCategoryNotifierProvider);
    final structuresAsync = ref.watch(feeStructureNotifierProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currencyFormatter = CurrencyFormatter.numberFormat(settingsAsync.value?.currency, decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text('Fee Management', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [Tab(text: 'CATEGORIES'), Tab(text: 'STRUCTURES')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAsyncList(categoriesAsync, (data) => _buildCategoryList(data)),
          _buildAsyncList(structuresAsync, (data) => _buildStructureList(data, currencyFormatter)),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAsyncList<T>(AsyncValue<List<T>> asyncVal, Widget Function(List<T>) builder) {
    return asyncVal.when(
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading data', style: TextStyle(color: AppColors.error))),
    );
  }

  Widget _buildCategoryList(List<FeeCategory> categories) {
    if (categories.isEmpty) return _EmptyState(icon: Icons.category_rounded, message: 'No categories defined');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _FeeItemCard(
          title: category.name,
          subtitle: category.description ?? 'System category',
          trailing: StatusBadge(status: category.isActive ? 'ACTIVE' : 'INACTIVE', color: category.isActive ? AppColors.primary : AppColors.textTertiary),
        );
      },
    );
  }

  Widget _buildStructureList(List<FeeStructure> structures, NumberFormat currencyFormatter) {
    if (structures.isEmpty) return _EmptyState(icon: Icons.account_tree_rounded, message: 'No structures defined');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      itemCount: structures.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final s = structures[index];
        return _FeeItemCard(
          title: s.name,
          subtitle: 'Class ${s.studentClass} • ${s.planType.toUpperCase()}',
          trailing: Text(currencyFormatter.format(s.amount), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
        );
      },
    );
  }
}

class _FeeItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  const _FeeItemCard({required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 24),
          Text(message, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}