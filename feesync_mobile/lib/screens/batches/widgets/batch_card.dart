import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass/glass_card.dart';
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
    final statusColor = _getStatusColor(batch.status);
    final capacityColor = batch.capacityPercentage > 0.9 ? Colors.orangeAccent : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          // Glow effect for urgent states
          if (batch.pendingDues > 5000)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          
          GlassCard(
            padding: const EdgeInsets.all(20),
            borderColor: batch.pendingDues > 5000 
                ? Colors.redAccent.withOpacity(0.3) 
                : Colors.white.withOpacity(0.1),
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
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${batch.subject} • ${batch.teacherName}',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.5),
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

                const SizedBox(height: 20),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 20),

                // MIDDLE SECTION - Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MiniStat(
                      label: 'Students',
                      value: '${batch.studentCount}/${batch.maxCapacity}',
                      icon: Icons.people_outline,
                      color: capacityColor,
                    ),
                    _MiniStat(
                      label: 'Attendance',
                      value: '${(batch.attendancePercentage * 100).toInt()}%',
                      icon: Icons.calendar_today_outlined,
                      color: AppColors.primary,
                    ),
                    _MiniStat(
                      label: 'Revenue',
                      value: '₹${NumberFormat('#,##,###').format(batch.revenueGenerated)}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: Colors.greenAccent,
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
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${(batch.capacityPercentage * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            color: capacityColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: batch.capacityPercentage,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(capacityColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // BOTTOM ACTIONS
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onView,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer.withOpacity(0.2),
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('View Batch'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _IconButton(
                      icon: Icons.how_to_reg_outlined,
                      onPressed: onMarkAttendance,
                      tooltip: 'Mark Attendance',
                    ),
                    const SizedBox(width: 8),
                    _IconButton(
                      icon: Icons.person_add_outlined,
                      onPressed: onAddStudent,
                      tooltip: 'Add Student',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BatchStatus status) {
    switch (status) {
      case BatchStatus.active:
        return Colors.greenAccent;
      case BatchStatus.upcoming:
        return Colors.blueAccent;
      case BatchStatus.completed:
        return Colors.white54;
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toString().split('.').last.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white.withOpacity(0.4)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
