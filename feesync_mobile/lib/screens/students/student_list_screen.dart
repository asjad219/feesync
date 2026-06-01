import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../providers/providers.dart';

final studentSearchProvider = StateProvider<String>((ref) => '');
final studentClassFilterProvider = StateProvider<String?>((ref) => null);

final filteredStudentBalancesProvider = Provider<List>((ref) {
  final students = ref.watch(studentBalancesProvider).value ?? [];
  final searchQuery = ref.watch(studentSearchProvider).toLowerCase();
  final classFilter = ref.watch(studentClassFilterProvider);

  return students.where((student) {
    final matchesSearch = searchQuery.isEmpty ||
        student.fullName.toLowerCase().contains(searchQuery) ||
        student.admissionNumber.toLowerCase().contains(searchQuery);

    final matchesClass = classFilter == null ||
        classFilter.isEmpty ||
        student.studentClass == classFilter;

    return matchesSearch && matchesClass;
  }).toList();
});

final studentClassesProvider = Provider<List<String>>((ref) {
  final students = ref.watch(studentBalancesProvider).value ?? [];
  final classes = students.map((s) => s.studentClass).toSet().toList();
  classes.sort();
  return classes;
});

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

  String _getPaymentStatus(double balance) {
    if (balance > 0) return 'OVERDUE';
    return 'PAID';
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = ref.watch(filteredStudentBalancesProvider);
    final classes = ref.watch(studentClassesProvider);
    final selectedClass = ref.watch(studentClassFilterProvider);

    return Scaffold(
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
            onPressed: () {},
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
              onRefresh: () => ref.refresh(studentBalancesProvider.future),
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
                          name: student.fullName,
                          className: student.studentClass,
                          admissionNo: student.admissionNumber,
                          balance: student.balance.abs(),
                          status: _getPaymentStatus(student.balance),
                          onTap: () => context.push('/students/${student.id}'),
                        );
                      },
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
          onPressed: () => context.push('/students/add'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, size: 32, color: Colors.white),
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