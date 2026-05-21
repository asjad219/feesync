import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../providers/providers.dart';

// Search and filter state
final studentSearchProvider = StateProvider<String>((ref) => '');
final studentClassFilterProvider = StateProvider<String?>((ref) => null);

// Filtered students provider
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

// Get unique classes from students
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
      appBar: AppBar(
        title: const Text('Students'),
        elevation: 0,
        backgroundColor: AppColors.darkSurface,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(studentSearchProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(studentSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Filter Chips
          if (classes.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final classItem = classes[index];
                  final isSelected = selectedClass == classItem;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChipButton(
                      label: classItem,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(studentClassFilterProvider.notifier).state =
                            isSelected ? null : classItem;
                      },
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          // Student List
          Expanded(
            child: filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No students found',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final status = _getPaymentStatus(student.balance);

                      return StudentCard(
                        name: student.fullName,
                        className: student.studentClass,
                        section: student.section,
                        balance: student.balance.abs(),
                        status: status,
                        onTap: () {
                          context.push('/students/${student.id}');
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/students/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
