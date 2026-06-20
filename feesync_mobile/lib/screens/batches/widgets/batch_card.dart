import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/batch.dart';
import 'package:intl/intl.dart';

class BatchCard extends StatelessWidget {
  final Batch batch;
  final VoidCallback? onView;
  final VoidCallback? onMarkAttendance;
  final VoidCallback? onAddStudent;

  const BatchCard({
    super.key,
    required this.batch,
    this.onView,
    this.onMarkAttendance,
    this.onAddStudent,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final surfaceColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);

    final statusColor = _getStatusColor(batch.status, isDark);
    final capacityColor = batch.capacityPercentage > 0.9 
        ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)) 
        : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669));

    final hasAlert = batch.pendingDues > 5000;
    final radius = BorderRadius.circular(24);

    final cardBg = isDark
        ? LinearGradient(
            colors: [surfaceColor.withValues(alpha: 0.75), surfaceColor.withValues(alpha: 0.65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [surfaceColor.withValues(alpha: 0.9), surfaceColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final borderColor = hasAlert
        ? const Color(0xFFDC2626).withValues(alpha: isDark ? 0.4 : 0.25)
        : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04));

    final alertShadow = [
      BoxShadow(
        color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.15 : 0.05),
        blurRadius: 24,
        spreadRadius: 1,
      )
    ];

    final normalShadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ];

    final dividerColor = isDark 
        ? Colors.white.withValues(alpha: 0.06) 
        : Colors.black.withValues(alpha: 0.04);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: hasAlert ? alertShadow : normalShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: cardBg,
              borderRadius: radius,
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            batch.name,
                            style: GoogleFonts.manrope(
                              color: textPrimaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${batch.subject} • ${batch.teacherName}',
                            style: GoogleFonts.inter(
                              color: textTertiaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: batch.status, color: statusColor),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: dividerColor, height: 1),
                const SizedBox(height: 16),

                // MIDDLE SECTION - Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MiniStat(
                      label: 'Students',
                      value: '${batch.studentCount}/${batch.maxCapacity}',
                      icon: Icons.group_rounded,
                      color: capacityColor,
                    ),
                    _MiniStat(
                      label: 'Attendance',
                      value: '${(batch.attendancePercentage * 100).toInt()}%',
                      icon: Icons.calendar_today_rounded,
                      color: primaryColor,
                    ),
                    _MiniStat(
                      label: 'Revenue',
                      value: '₹${NumberFormat('#,##,###').format(batch.revenueGenerated)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Capacity Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Batch Capacity',
                          style: GoogleFonts.inter(
                            color: textTertiaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(batch.capacityPercentage * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            color: capacityColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: batch.capacityPercentage,
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                        valueColor: AlwaysStoppedAnimation<Color>(capacityColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // BOTTOM ACTIONS
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onView,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
                          foregroundColor: primaryColor,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          side: BorderSide(
                            color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          'View Batch',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _IconButton(
                      icon: Icons.how_to_reg_rounded,
                      onPressed: onMarkAttendance,
                      tooltip: 'Mark Attendance',
                    ),
                    const SizedBox(width: 8),
                    _IconButton(
                      icon: Icons.person_add_rounded,
                      onPressed: onAddStudent,
                      tooltip: 'Add Student',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BatchStatus status, bool isDark) {
    switch (status) {
      case BatchStatus.active:
        return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      case BatchStatus.upcoming:
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      case BatchStatus.completed:
        return isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final BatchStatus status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Text(
        status.toString().split('.').last.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                color: textTertiaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: textPrimaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const _IconButton({required this.icon, this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: textPrimaryColor, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
