import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/batch.dart';
import '../../../models/student.dart';
import '../../../models/fee.dart';

class BatchSelectionDropdown extends StatelessWidget {
  final List<Batch> batches;
  final String? selectedBatchId;
  final ValueChanged<String?> onChanged;

  const BatchSelectionDropdown({
    super.key,
    required this.batches,
    this.selectedBatchId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainer.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedBatchId,
          hint: const Text('All Batches / Classes'),
          dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Batches / Classes'),
            ),
            ...batches.map((b) => DropdownMenuItem<String>(
                  value: b.id,
                  child: Text('${b.name} (${b.subject})'),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class StudentSelectionButton extends StatelessWidget {
  final Student? selectedStudent;
  final VoidCallback onTap;

  const StudentSelectionButton({
    super.key,
    required this.selectedStudent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final displayName = selectedStudent != null 
        ? '${selectedStudent!.fullName} (${selectedStudent!.studentClass})'
        : 'Select a student';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainer.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                displayName,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: selectedStudent != null ? FontWeight.w600 : FontWeight.w400,
                  color: selectedStudent != null ? AppColors.textPrimary : AppColors.textHint,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class PendingDuesSelector extends StatelessWidget {
  final List<Due> dues;
  final List<String> selectedDueIds;
  final void Function(Due due, bool isSelected) onDueToggled;
  final String? currencyCode;

  const PendingDuesSelector({
    super.key,
    required this.dues,
    required this.selectedDueIds,
    required this.onDueToggled,
    this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    if (dues.isEmpty) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
            child: Center(child: Text('No pending dues for this student', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainer.withValues(alpha: 0.5) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Advance Payment Mode', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Since there are no pending dues, any amount recorded will be automatically added to the student\'s advance balance.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ],
      );
    }
    
    final currencyFormatter = CurrencyFormatter.numberFormat(currencyCode, decimalDigits: 0);

    return Column(
      children: dues.map((due) {
        final isSelected = selectedDueIds.contains(due.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => onDueToggled(due, isSelected),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary.withValues(alpha: 0.1) 
                    : (isDark ? AppColors.surfaceContainer.withValues(alpha: 0.5) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primary.withValues(alpha: 0.3) 
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1)),
                ),
                boxShadow: isSelected ? null : (isDark ? null : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]),
              ),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isSelected ? AppColors.primary : AppColors.textTertiary, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(due.periodName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text('Due: ${DateFormat('MMM d, yyyy').format(due.dueDate)}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  Text(currencyFormatter.format(due.dueAmount), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
