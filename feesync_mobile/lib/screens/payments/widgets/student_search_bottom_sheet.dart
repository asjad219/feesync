import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/student_avatar.dart';
import '../../../models/student.dart';

class StudentSearchBottomSheet extends StatefulWidget {
  final List<StudentBalance> balances;
  final String? selectedBatchId;
  final ValueChanged<StudentBalance> onStudentSelected;

  const StudentSearchBottomSheet({
    super.key,
    required this.balances,
    this.selectedBatchId,
    required this.onStudentSelected,
  });

  @override
  State<StudentSearchBottomSheet> createState() => _StudentSearchBottomSheetState();
}

class _StudentSearchBottomSheetState extends State<StudentSearchBottomSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter balances by batch
    final batchFiltered = widget.balances.where((b) {
      if (widget.selectedBatchId != null && b.batchId != widget.selectedBatchId) {
        return false;
      }
      return true;
    }).toList();

    // Filter by search query
    final filtered = batchFiltered.where((b) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.fullName.toLowerCase().contains(q) ||
          b.admissionNumber.toLowerCase().contains(q) ||
          (b.rollNumber ?? '').toLowerCase().contains(q);
    }).toList();

    final isDark = AppColors.isDarkMode;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Student',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Search Input
              TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by name, roll, or admission no...',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: AppColors.textTertiary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  fillColor: isDark
                      ? AppColors.surfaceContainerLow.withValues(alpha: 0.6)
                      : Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 16),
              // Filter count
              Text(
                'Showing ${filtered.length} of ${batchFiltered.length} students',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded, size: 48, color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            Text(
                              'No students found',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final student = filtered[index];
                          final balanceText = student.balance > 0
                              ? 'Balance: ₹${student.balance.toStringAsFixed(0)}'
                              : 'No dues';
                          final balanceColor = student.balance > 0
                              ? AppColors.error
                              : AppColors.success;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              tileColor: isDark
                                  ? AppColors.surfaceContainerLow.withValues(alpha: 0.3)
                                  : Colors.white,
                              leading: StudentAvatar(
                                studentId: student.id,
                                firstName: student.firstName,
                                gender: student.gender,
                                radius: 22,
                              ),
                              title: Text(
                                student.fullName,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                'Class: ${student.studentClass} • Roll: ${student.rollNumber ?? 'N/A'}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    balanceText,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: balanceColor,
                                    ),
                                  ),
                                  if (student.admissionNumber.isNotEmpty)
                                    Text(
                                      'ID: ${student.admissionNumber}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                widget.onStudentSelected(student);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
