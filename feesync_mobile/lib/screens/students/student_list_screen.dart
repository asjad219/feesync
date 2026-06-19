import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../core/widgets/offline_widgets.dart';
import '../../core/widgets/paywall_dialog.dart';
import '../../core/billing/feature_gate.dart';
import '../../models/student.dart';
import '../../providers/providers.dart';
import '../../providers/subscription_provider.dart';
import '../../core/widgets/permission_guard.dart';

final studentSearchProvider = StateProvider<String>((ref) => '');
final studentClassFilterProvider = StateProvider<String?>((ref) => null);
final studentStatusFilterProvider = StateProvider<String?>((ref) => null);

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getPaymentStatus(StudentBalance student, {bool aiPredictionsEnabled = false}) {
    if (student.dueAmount > 0) {
      if (aiPredictionsEnabled) {
        if (student.dueAmount >= 5000) return 'HIGH RISK';
        if (student.dueAmount >= 1000) return 'AT RISK';
      }
      return student.status;
    }
    return 'PAID';
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentStatus = ref.watch(studentStatusFilterProvider);
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Students',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterOption(
                    context: context,
                    ref: ref,
                    label: 'All Students',
                    value: null,
                    groupValue: currentStatus,
                  ),
                  _buildFilterOption(
                    context: context,
                    ref: ref,
                    label: 'Overdue / Due (Pending Dues)',
                    value: 'OVERDUE',
                    groupValue: currentStatus,
                  ),
                  _buildFilterOption(
                    context: context,
                    ref: ref,
                    label: 'Paid (No Due Amount)',
                    value: 'PAID',
                    groupValue: currentStatus,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required String? value,
    required String? groupValue,
  }) {
    final isSelected = value == groupValue;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        ref.read(studentStatusFilterProvider.notifier).state = value;
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentBalancesAsync = ref.watch(studentBalancesProvider);
    final selectedClass = ref.watch(studentClassFilterProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final aiPredictionsEnabled = settingsAsync.value?.aiPredictionsEnabled ?? false;

    return PermissionGuard(
      permission: 'view_students',
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        appBar: AppBar(
          title: Text(
            'Students',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => _showFilterBottomSheet(context),
              icon: Icon(Icons.tune_rounded, color: AppColors.textPrimary),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => ref.read(studentSearchProvider.notifier).state = value,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary),
                  fillColor: AppColors.surfaceContainer.withValues(alpha: 0.5),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: AppColors.textTertiary),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(studentSearchProvider.notifier).state = '';
                          },
                        )
                      : null,
                ),
              ),
            ),
  
            studentBalancesAsync.when(
              data: (students) {
                final searchQuery = ref.watch(studentSearchProvider).toLowerCase();
                final classFilter = ref.watch(studentClassFilterProvider);
                final statusFilter = ref.watch(studentStatusFilterProvider);
  
                final filteredStudents = students.where((student) {
                  final matchesSearch = searchQuery.isEmpty ||
                      student.fullName.toLowerCase().contains(searchQuery) ||
                      student.admissionNumber.toLowerCase().contains(searchQuery);
  
                  final matchesClass = classFilter == null ||
                      classFilter.isEmpty ||
                      student.studentClass == classFilter;
  
                  final matchesStatus = statusFilter == null ||
                      (statusFilter == 'PAID' && _getPaymentStatus(student, aiPredictionsEnabled: aiPredictionsEnabled) == 'PAID') ||
                      (statusFilter == 'OVERDUE' && _getPaymentStatus(student, aiPredictionsEnabled: aiPredictionsEnabled) != 'PAID');
  
                  return matchesSearch && matchesClass && matchesStatus;
                }).toList();
  
                final classes = students.map((s) => s.studentClass).toSet().toList();
                classes.sort();
  
                return Expanded(
                  child: Column(
                    children: [
                      if (classes.isNotEmpty)
                        Container(
                          height: 72,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: classes.length,
                            itemBuilder: (context, index) {
                              final classItem = classes[index];
                              final isSelected = selectedClass == classItem;
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: FilterChipButton(
                                  label: classItem,
                                  isSelected: isSelected,
                                  onTap: () => ref.read(studentClassFilterProvider.notifier).state = isSelected ? null : classItem,
                                ),
                              );
                            },
                          ),
                        ),
  
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => ref.read(studentBalancesProvider.notifier).loadStudents(),
                          color: AppColors.primaryContainer,
                          child: filteredStudents.isEmpty
                              ? _EmptyState()
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                                  itemCount: filteredStudents.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final student = filteredStudents[index];
                                    return StudentCard(
                                      studentId: student.id,
                                      firstName: student.firstName,
                                      gender: student.gender,
                                      name: student.fullName,
                                      className: student.studentClass,
                                      admissionNo: student.admissionNumber,
                                      dueAmount: student.dueAmount,
                                      status: _getPaymentStatus(student, aiPredictionsEnabled: aiPredictionsEnabled),
                                      onTap: () => context.push('/students/${student.id}'),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: ShimmerList(itemCount: 5, itemHeight: 88),
                ),
              ),
              error: (err, stack) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RetryErrorPlaceholder(
                        message: 'Could not load students. Tap to retry.',
                        isDark: AppColors.isDarkMode,
                        onRetry: () => ref.read(studentBalancesProvider.notifier).loadStudents(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            shape: BoxShape.circle,
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
            child: const Icon(Icons.add, size: 32, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppColors.surfaceContainer.withValues(alpha: 0.5), shape: BoxShape.circle),
            child: Icon(Icons.group_off_rounded, size: 64, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          Text(
            'No students found',
            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}