import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
        elevation: 0,
        backgroundColor: AppColors.darkSurface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Structures'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Categories Tab
          categoriesAsync.when(
            data: (categories) => _buildCategoryList(categories),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          // Structures Tab
          structuresAsync.when(
            data: (structures) => _buildStructureList(structures),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new fee
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryList(List<FeeCategory> categories) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories found', style: TextStyle(color: AppColors.textTertiary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildFeeCard(
          title: category.name,
          description: category.description ?? 'No description',
          isActive: category.isActive,
        );
      },
    );
  }

  Widget _buildStructureList(List<FeeStructure> structures) {
    if (structures.isEmpty) {
      return const Center(child: Text('No structures found', style: TextStyle(color: AppColors.textTertiary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: structures.length,
      itemBuilder: (context, index) {
        final structure = structures[index];
        return _buildDetailedStructureCard(structure);
      },
    );
  }

  Widget _buildFeeCard({
    required String title,
    required String description,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (!isActive)
            StatusBadge(status: 'INACTIVE', backgroundColor: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDetailedStructureCard(FeeStructure structure) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                structure.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                CurrencyFormatter.format(structure.amount),
                style: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoBadge(structure.planType.toUpperCase(), AppColors.primary.withValues(alpha: 0.1), AppColors.primary),
              const SizedBox(width: 8),
              _buildInfoBadge('CLASS ${structure.studentClass}', AppColors.textTertiary.withValues(alpha: 0.1), AppColors.textTertiary),
            ],
          ),
          if (structure.lateFine > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Late fine: ${CurrencyFormatter.format(structure.lateFine)} after ${structure.graceDays} days',
              style: const TextStyle(fontSize: 11, color: AppColors.overdue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textCol),
      ),
    );
  }
}
