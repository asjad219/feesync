import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Status Badge Widget
class StatusBadge extends StatelessWidget {
  final String status;
  final Color? backgroundColor;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.status,
    this.backgroundColor,
    this.textColor,
  });

  Color _getBgColor() {
    if (backgroundColor != null) return backgroundColor!;
    if (status == 'OVERDUE') return AppColors.overdue;
    if (status == 'PENDING') return AppColors.pending;
    return AppColors.paid;
  }

  Color _getTextColor() {
    if (textColor != null) return textColor!;
    return Colors.white;
  }

  factory StatusBadge.overdue() => const StatusBadge(
        status: 'OVERDUE',
        backgroundColor: AppColors.overdue,
        textColor: Colors.white,
      );

  factory StatusBadge.pending() => const StatusBadge(
        status: 'PENDING',
        backgroundColor: AppColors.pending,
        textColor: Colors.white,
      );

  factory StatusBadge.paid() => const StatusBadge(
        status: 'PAID',
        backgroundColor: AppColors.paid,
        textColor: Colors.white,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBgColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getTextColor(),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Student Card Widget
class StudentCard extends StatelessWidget {
  final String name;
  final String className;
  final String? section;
  final double balance;
  final String status;
  final VoidCallback? onTap;

  const StudentCard({
    super.key,
    required this.name,
    required this.className,
    this.section,
    required this.balance,
    required this.status,
    this.onTap,
  });

  StatusBadge _getStatusBadge() {
    if (status == 'OVERDUE') return StatusBadge.overdue();
    if (status == 'PENDING') return StatusBadge.pending();
    return StatusBadge.paid();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$className${section != null ? ' • $section' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                _getStatusBadge(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: status._getStatusColor(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  Color _getStatusColor() {
    if (this == 'OVERDUE') return AppColors.overdue;
    if (this == 'PENDING') return AppColors.pending;
    return AppColors.paid;
  }
}

/// Filter Chip Widget
class FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.darkBorder,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
