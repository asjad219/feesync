import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../providers/providers.dart';
import '../../../models/models.dart';
import 'package:intl/intl.dart';

class BatchDetailScreen extends ConsumerStatefulWidget {
  final String batchId;
  final int initialTabIndex;
  const BatchDetailScreen({super.key, required this.batchId, this.initialTabIndex = 0});

  @override
  ConsumerState<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends ConsumerState<BatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5, 
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final batchAsync = ref.watch(batchByIdProvider(widget.batchId));
    final bool isDark = AppColors.isDarkMode;
    final Color scaffoldBgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: batchAsync.when(
        data: (batch) => batch == null 
            ? const Center(child: Text('Batch not found')) 
            : _buildContent(batch),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(Batch batch) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildHeroHeader(batch),
        _buildStickyTabBar(batch.color),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(
            batch: batch,
            onAttendanceTap: () => _tabController.animateTo(2),
            onAddStudentTap: () => context.push('/students/add?batchId=${batch.id}'),
            onRemindersTap: () => context.push('/notifications'),
            onEditTap: () => context.push('/batches/create?batchId=${batch.id}'),
          ),
          _StudentsTab(batchId: batch.id),
          _AttendanceTab(batchId: batch.id),
          _FeesTab(batchId: batch.id),
          _AnalyticsTab(batchId: batch.id, accentColor: batch.color),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(Batch batch) {
    final bool isDark = AppColors.isDarkMode;
    final scaffoldBgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFC);
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);

    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: scaffoldBgColor,
      iconTheme: IconThemeData(color: textPrimaryColor),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner / Background Glow
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: batch.color.withOpacity(isDark ? 0.2 : 0.15),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: batch.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.school, color: batch.color, size: 32),
                      ),
                      _AiHealthScore(score: 92),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    batch.name,
                    style: GoogleFonts.manrope(
                      color: textPrimaryColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${batch.subject} • ${batch.teacherName}',
                          style: GoogleFonts.inter(
                            color: textSecondaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(
                        status: batch.status.name.toUpperCase(),
                        color: batch.status == BatchStatus.active 
                            ? const Color(0xFF10B981) 
                            : (batch.status == BatchStatus.upcoming ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _HeaderStat(label: 'Students', value: '${batch.studentCount}/${batch.maxCapacity}'),
                      const SizedBox(width: 24),
                      _HeaderStat(label: 'Revenue', value: '₹${NumberFormat.compact().format(batch.revenueGenerated)}'),
                      const SizedBox(width: 24),
                      _HeaderStat(label: 'Attendance', value: '${(batch.attendancePercentage * 100).toInt()}%'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyTabBar(Color accentColor) {
    final bool isDark = AppColors.isDarkMode;
    final Color unselectedLabelColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 20),
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: unselectedLabelColor,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.5, color: accentColor),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          labelStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Students'),
            Tab(text: 'Attendance'),
            Tab(text: 'Fees'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
    );
  }
}

class _AiHealthScore extends StatelessWidget {
  final int score;
  const _AiHealthScore({required this.score});

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final Color healthColor = score >= 80 
        ? (isDark ? const Color(0xFF10B981) : const Color(0xFF059669))
        : (score >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
        
    final String statusText = score >= 80 ? 'Excellent' : (score >= 50 ? 'Average' : 'Critical');

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: healthColor, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AI BATCH HEALTH',
                style: GoogleFonts.inter(
                  color: isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$score%',
                    style: GoogleFonts.manrope(
                      color: healthColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($statusText)',
                    style: GoogleFonts.inter(
                      color: healthColor.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: textTertiaryColor, fontSize: 12)),
        Text(value, style: GoogleFonts.manrope(color: textPrimaryColor, fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bool isDark = AppColors.isDarkMode;
    final scaffoldBgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFC);
    return Container(
      color: scaffoldBgColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// STUB TABS
class _OverviewTab extends StatelessWidget {
  final Batch batch;
  final VoidCallback onAttendanceTap;
  final VoidCallback onAddStudentTap;
  final VoidCallback onRemindersTap;
  final VoidCallback onEditTap;

  const _OverviewTab({
    required this.batch,
    required this.onAttendanceTap,
    required this.onAddStudentTap,
    required this.onRemindersTap,
    required this.onEditTap,
  });

  List<DateTime> _generateUpcomingDates() {
    final List<DateTime> dates = [];
    DateTime current = DateTime.now();
    while (dates.length < 3) {
      if (current.weekday != DateTime.sunday) {
        dates.add(DateTime(current.year, current.month, current.day));
      }
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final dates = _generateUpcomingDates();
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActions(context),
          const SizedBox(height: 28),
          _buildSectionHeader('Upcoming Schedule'),
          const SizedBox(height: 12),
          ...dates.map((date) {
            final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
            
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isToday 
                          ? primaryColor.withValues(alpha: 0.15) 
                          : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday 
                            ? primaryColor 
                            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('dd').format(date),
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isToday ? primaryColor : textPrimaryColor,
                          ),
                        ),
                        Text(
                          DateFormat('EEE').format(date).toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isToday ? primaryColor : textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday ? 'Today\'s Session' : 'Scheduled Session',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isToday ? primaryColor : textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '04:00 PM - 05:30 PM • Room 101',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.how_to_reg_rounded, color: primaryColor),
                    tooltip: 'Mark Attendance',
                    onPressed: onAttendanceTap,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickAction(
          icon: Icons.how_to_reg,
          label: 'Attendance',
          color: Colors.blueAccent,
          onTap: onAttendanceTap,
        ),
        _QuickAction(
          icon: Icons.person_add,
          label: 'Add Student',
          color: Colors.purpleAccent,
          onTap: onAddStudentTap,
        ),
        _QuickAction(
          icon: Icons.notifications_active,
          label: 'Reminders',
          color: Colors.orangeAccent,
          onTap: onRemindersTap,
        ),
        _QuickAction(
          icon: Icons.edit,
          label: 'Edit',
          color: Colors.grey,
          onTap: onEditTap,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.manrope(color: textPrimaryColor, fontSize: 18, fontWeight: FontWeight.w700)),
        TextButton(
          onPressed: () {}, 
          style: TextButton.styleFrom(foregroundColor: batch.color),
          child: const Text('View All'),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(color: textSecondaryColor, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StudentsTab extends ConsumerWidget {
  final String batchId;
  const _StudentsTab({required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(batchStudentsProvider(batchId));
    final bool isDark = AppColors.isDarkMode;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);

    return studentsAsync.when(
      data: (students) => ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: students.length,
        itemBuilder: (context, index) => _StudentListTile(student: students[index]),
      ),
      loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

class _StudentListTile extends StatelessWidget {
  final StudentBalance student;
  const _StudentListTile({required this.student});

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);

    return InkWell(
      onTap: () => context.push('/students/${student.id}'),
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.2),
              child: Text(student.firstName[0], style: TextStyle(color: primaryColor)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${student.firstName} ${student.lastName}', style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold)),
                  if (student.rollNumber != null && student.rollNumber!.isNotEmpty)
                    Text('Roll No: ${student.rollNumber}', style: TextStyle(color: textTertiaryColor, fontSize: 11)),
                  Text(
                    'Dues: ₹${student.balance}', 
                    style: TextStyle(
                      color: student.balance > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981), 
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textTertiaryColor),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTab extends ConsumerStatefulWidget {
  final String batchId;
  const _AttendanceTab({required this.batchId});

  @override
  ConsumerState<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<_AttendanceTab> {
  int _viewIndex = 0; // 0: Mark, 1: History

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildViewToggle(),
        Expanded(
          child: _viewIndex == 0 
              ? _MarkAttendanceView(batchId: widget.batchId)
              : _AttendanceHistoryView(batchId: widget.batchId),
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    final bool isDark = AppColors.isDarkMode;
    final surfaceContainerColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? surfaceContainerColor.withValues(alpha: 0.5) : surfaceContainerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          _ToggleItem(
            label: 'Daily Marking',
            isSelected: _viewIndex == 0,
            onTap: () => setState(() => _viewIndex = 0),
          ),
          _ToggleItem(
            label: 'Session History',
            isSelected: _viewIndex == 1,
            onTap: () => setState(() => _viewIndex = 1),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleItem({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: primaryColor.withOpacity(0.3)) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? primaryColor : textTertiaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkAttendanceView extends ConsumerWidget {
  final String batchId;
  const _MarkAttendanceView({required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(batchStudentsProvider(batchId));
    final attendanceState = ref.watch(dailyAttendanceProvider(batchId));
    final bool isDark = AppColors.isDarkMode;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);

    return Column(
      children: [
        _buildAttendanceHeader(context, ref, studentsAsync.value ?? []),
        if (attendanceState.statuses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: attendanceState.isSaving 
                    ? null 
                    : () async {
                        try {
                          await ref.read(dailyAttendanceProvider(batchId).notifier).saveAttendance();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Attendance saved successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error saving attendance: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: attendanceState.isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Attendance'),
              ),
            ),
          ),
        Expanded(
          child: studentsAsync.when(
            data: (students) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: students.length,
              itemBuilder: (context, index) => _AttendanceRosterTile(
                student: students[index],
                batchId: batchId,
              ),
            ),
            loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceHeader(BuildContext context, WidgetRef ref, List<StudentBalance> students) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: GoogleFonts.manrope(color: textPrimaryColor, fontWeight: FontWeight.bold),
                ),
                Text('Daily Roster', style: GoogleFonts.inter(color: textTertiaryColor, fontSize: 12)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: students.isEmpty 
                  ? null 
                  : () => ref.read(dailyAttendanceProvider(batchId).notifier).markAllPresent(
                        students.map((s) => s.id).toList(),
                      ),
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Bulk Present'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceHistoryView extends ConsumerWidget {
  final String batchId;
  const _AttendanceHistoryView({required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(batchAttendanceProvider(batchId));
    final studentsAsync = ref.watch(batchStudentsProvider(batchId));
    final bool isDark = AppColors.isDarkMode;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);

    return historyAsync.when(
      data: (records) {
        if (records.isEmpty) return _buildEmptyHistory();
        
        // Group by date
        final Map<String, List<AttendanceRecord>> grouped = {};
        for (var r in records) {
          final dateStr = DateFormat('yyyy-MM-dd').format(r.date);
          grouped.putIfAbsent(dateStr, () => []).add(r);
        }

        final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
        final students = studentsAsync.value ?? [];
        final Map<String, String> studentNames = {
          for (var s in students) s.id: '${s.firstName} ${s.lastName}'
        };

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final dateStr = sortedDates[index];
            final dayRecords = grouped[dateStr]!;
            final presentCount = dayRecords.where((r) => r.status == AttendanceStatus.present).length;
            final date = DateTime.parse(dateStr);

            return _HistoryCard(
              date: date,
              presentCount: presentCount,
              totalCount: dayRecords.length,
              onTap: () => _showSessionDetails(context, date, dayRecords, studentNames),
            );
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyHistory() {
    final bool isDark = AppColors.isDarkMode;
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 48, color: textTertiaryColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('No history records yet', style: GoogleFonts.inter(color: textTertiaryColor)),
        ],
      ),
    );
  }

  void _showSessionDetails(BuildContext context, DateTime date, List<AttendanceRecord> records, Map<String, String> studentNames) {
    final bool isDark = AppColors.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _SessionDetailsSheet(date: date, records: records, studentNames: studentNames),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final DateTime date;
  final int presentCount;
  final int totalCount;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.date,
    required this.presentCount,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (presentCount / totalCount * 100).toInt();
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final healthColor = percentage > 80 
        ? const Color(0xFF10B981) 
        : (percentage > 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: healthColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$percentage%',
                    style: GoogleFonts.inter(
                      fontSize: 12, 
                      fontWeight: FontWeight.w800, 
                      color: healthColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(date),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPrimaryColor),
                    ),
                    Text(
                      '$presentCount Present • ${totalCount - presentCount} Absent',
                      style: GoogleFonts.inter(fontSize: 12, color: textTertiaryColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: textTertiaryColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionDetailsSheet extends StatelessWidget {
  final DateTime date;
  final List<AttendanceRecord> records;
  final Map<String, String> studentNames;

  const _SessionDetailsSheet({
    required this.date,
    required this.records,
    required this.studentNames,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Session Details', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimaryColor)),
                  Text(DateFormat('MMMM d, yyyy').format(date), style: GoogleFonts.inter(fontSize: 14, color: textTertiaryColor)),
                ],
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: textTertiaryColor)),
            ],
          ),
          const SizedBox(height: 24),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: records.length,
              itemBuilder: (context, index) {
                final r = records[index];
                final isPresent = r.status == AttendanceStatus.present;
                final studentName = studentNames[r.studentId] ?? 'Student';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                        child: Icon(Icons.person_rounded, size: 16, color: textTertiaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: TextStyle(color: textPrimaryColor),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: isPresent ? 'PRESENT' : 'ABSENT'),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AttendanceRosterTile extends ConsumerWidget {
  final StudentBalance student;
  final String batchId;
  const _AttendanceRosterTile({required this.student, required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(dailyAttendanceProvider(batchId).select((s) => s.statuses[student.id]));
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryColor.withValues(alpha: 0.2),
            child: Text(student.firstName[0], style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${student.firstName} ${student.lastName}',
                  style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
                ),
                if (student.rollNumber != null && student.rollNumber!.isNotEmpty)
                  Text(
                    'Roll No: ${student.rollNumber}',
                    style: TextStyle(color: textTertiaryColor, fontSize: 11),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              _StatusToggle(
                label: 'P',
                isSelected: status == AttendanceStatus.present,
                activeColor: const Color(0xFF10B981),
                onTap: () => ref.read(dailyAttendanceProvider(batchId).notifier).setStatus(student.id, AttendanceStatus.present),
              ),
              const SizedBox(width: 8),
              _StatusToggle(
                label: 'A',
                isSelected: status == AttendanceStatus.absent,
                activeColor: const Color(0xFFEF4444),
                onTap: () => ref.read(dailyAttendanceProvider(batchId).notifier).setStatus(student.id, AttendanceStatus.absent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _StatusToggle({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white54 : Colors.black54),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _FeesTab extends ConsumerWidget {
  final String batchId;
  const _FeesTab({required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(batchStudentsProvider(batchId));
    final bool isDark = AppColors.isDarkMode;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return studentsAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return Center(child: Text('No students in this batch', style: TextStyle(color: textTertiaryColor)));
        }

        // Calculate Stats
        double totalFees = 0;
        double totalPaid = 0;
        double totalBalance = 0;
        int defaulterCount = 0;

        for (final s in students) {
          totalFees += s.totalFeeAmount;
          totalPaid += s.totalPaidAmount;
          totalBalance += s.balance;
          if (s.balance > 0) defaulterCount++;
        }

        final collectionPct = totalFees > 0 ? totalPaid / totalFees : 0.0;
        final defaulterPct = students.isNotEmpty ? defaulterCount / students.length : 0.0;
        final pendingPct = totalFees > 0 ? totalBalance / totalFees : 0.0;

        final defaulters = students.where((s) => s.balance > 0).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(batchStudentsProvider(batchId)),
          color: primaryColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCollectionStats(collectionPct, defaulterPct, pendingPct),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Defaulters', style: GoogleFonts.manrope(color: textPrimaryColor, fontSize: 18, fontWeight: FontWeight.w700)),
                    if (defaulters.isNotEmpty)
                      TextButton(
                        onPressed: () => _sendBulkReminders(context, defaulters),
                        style: TextButton.styleFrom(foregroundColor: primaryColor),
                        child: const Text('Send All Reminders'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (defaulters.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 32),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Great job! No pending dues.',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: defaulters.map((s) => _DefaulterTile(student: s)).toList(),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildCollectionStats(double collection, double defaulters, double pending) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleProgress(value: collection, label: 'Collection', color: const Color(0xFF2563EB)),
          _CircleProgress(value: defaulters, label: 'Defaulters', color: const Color(0xFFEF4444)),
          _CircleProgress(value: pending, label: 'Pending', color: const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  void _sendBulkReminders(BuildContext context, List<StudentBalance> defaulters) {
    final bool isDark = AppColors.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ReminderPreviewSheet(
        title: 'Send All Reminders',
        subtitle: 'You are about to send reminders to ${defaulters.length} students.',
        students: defaulters,
        onConfirm: () async {
          Navigator.pop(context);
          // In bulk mode, we might just open them one by one or send to a service.
          // For now, let's open the first one and notify user.
          if (defaulters.isNotEmpty) {
            _launchWhatsApp(defaulters.first);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Starting reminder sequence for ${defaulters.length} students...')),
            );
          }
        },
      ),
    );
  }

  static void _launchWhatsApp(StudentBalance s) async {
    final phone = s.parentPhone ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) return;
    
    final message = "Dear Parent, this is a reminder regarding the pending fee of ₹${s.balance.toStringAsFixed(0)} for ${s.firstName}. Kindly clear it at the earliest. Thank you!";
    final url = 'https://wa.me/${cleanPhone.startsWith('+') ? cleanPhone : '+91$cleanPhone'}?text=${Uri.encodeComponent(message)}';
    
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _CircleProgress extends StatelessWidget {
  final double value;
  final String label;
  final Color color;

  const _CircleProgress({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Center(
                child: Text(
                  '${(value * 100).toInt()}%', 
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w800, 
                    color: textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: textTertiaryColor, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _DefaulterTile extends StatelessWidget {
  final StudentBalance student;
  const _DefaulterTile({required this.student});

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final surfaceContainerLowColor = isDark ? const Color(0xFF1A1A28) : const Color(0xFFF8FAFC);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/students/${student.id}'),
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: surfaceContainerLowColor,
                child: Text(student.firstName[0], style: TextStyle(fontSize: 12, color: textTertiaryColor)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  student.fullName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textPrimaryColor),
                ),
              ),
              Text(
                '₹${NumberFormat('#,###').format(student.balance)}',
                style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.send_rounded, size: 20, color: Color(0xFF2563EB)),
                onPressed: () => _showSingleReminder(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSingleReminder(BuildContext context) {
    final bool isDark = AppColors.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ReminderPreviewSheet(
        title: 'Send Reminder',
        subtitle: 'Send fee reminder to ${student.fullName}\'s parent.',
        students: [student],
        onConfirm: () {
          Navigator.pop(context);
          _FeesTab._launchWhatsApp(student);
        },
      ),
    );
  }
}

class _ReminderPreviewSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<StudentBalance> students;
  final VoidCallback onConfirm;

  const _ReminderPreviewSheet({
    required this.title,
    required this.subtitle,
    required this.students,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final s = students.first;
    final message = "Dear Parent, this is a reminder regarding the pending fee of ₹${s.balance.toStringAsFixed(0)} for ${s.firstName}. Kindly clear it at the earliest. Thank you!";

    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimaryColor)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: textTertiaryColor)),
                ],
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: textTertiaryColor)),
            ],
          ),
          const SizedBox(height: 32),
          Text('MESSAGE PREVIEW', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: textTertiaryColor)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Text(
              students.length > 1 
                ? 'Multiple personalized messages will be sent...'
                : message,
              style: GoogleFonts.inter(fontSize: 14, color: textPrimaryColor, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: Text(
                students.length > 1 ? 'SEND ALL VIA WHATSAPP' : 'SEND VIA WHATSAPP',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTab extends ConsumerWidget {
  final String batchId;
  final Color? accentColor;
  const _AnalyticsTab({required this.batchId, this.accentColor});

  Color get activeAccentColor => accentColor ?? AppColors.primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(batchAnalyticsProvider(batchId));
    final bool isDark = AppColors.isDarkMode;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);

    return analyticsAsync.when(
      data: (analytics) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(batchAnalyticsProvider(batchId)),
        color: primaryColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAttendanceTrend(analytics),
              const SizedBox(height: 24),
              _buildCollectionTrend(analytics),
              const SizedBox(height: 24),
              _buildStudentMetrics(analytics),
              const SizedBox(height: 24),
              _buildAiInsights(analytics),
            ],
          ),
        ),
      ),
      loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildAttendanceTrend(BatchAnalytics data) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance Trend', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: textPrimaryColor)),
          const SizedBox(height: 24),
          if (data.attendanceTrend.isEmpty)
            _buildEmptyState('No attendance recorded yet')
          else
            SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.attendanceTrend.entries.take(7).map((e) {
                  final pct = e.value;
                  return Tooltip(
                    message: '${DateFormat('MMM d').format(e.key)}: ${(pct * 100).toInt()}%',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 24,
                          height: (pct * 80).clamp(5, 80),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [const Color(0xFF10B981), const Color(0xFF10B981).withOpacity(0.3)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(DateFormat('E').format(e.key), style: TextStyle(fontSize: 9, color: textTertiaryColor)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollectionTrend(BatchAnalytics data) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Collection Trend', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: textPrimaryColor)),
          const SizedBox(height: 24),
          if (data.collectionTrend.isEmpty)
            _buildEmptyState('No collections recorded yet')
          else
            SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.collectionTrend.entries.map((e) {
                  final amount = e.value;
                  final maxVal = data.collectionTrend.values.reduce((a, b) => a > b ? a : b);
                  final heightPct = maxVal > 0 ? amount / maxVal : 0.0;
                  
                  return Tooltip(
                    message: '${e.key}: ₹${amount.toInt()}',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 32,
                          height: (heightPct * 80).clamp(5, 80),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [const Color(0xFF2563EB), const Color(0xFF2563EB).withOpacity(0.3)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(e.key, style: TextStyle(fontSize: 9, color: textTertiaryColor)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentMetrics(BatchAnalytics data) {
    final bool isDark = AppColors.isDarkMode;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);

    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Students', style: GoogleFonts.inter(fontSize: 10, color: textSecondaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${data.genderDistribution.values.fold(0, (a, b) => a + b)}', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimaryColor)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gender Ratio', style: GoogleFonts.inter(fontSize: 10, color: textSecondaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.male, size: 14, color: Color(0xFF2563EB)),
                    Text('${data.genderDistribution['Male'] ?? 0}', style: TextStyle(fontSize: 14, color: textPrimaryColor)),
                    const SizedBox(width: 8),
                    const Icon(Icons.female, size: 14, color: Color(0xFFEC4899)),
                    Text('${data.genderDistribution['Female'] ?? 0}', style: TextStyle(fontSize: 14, color: textPrimaryColor)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiInsights(BatchAnalytics data) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: activeAccentColor.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: activeAccentColor, size: 20),
              const SizedBox(width: 8),
              Text('AI INSIGHTS', style: GoogleFonts.manrope(color: activeAccentColor, fontWeight: FontWeight.w800, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          ...data.aiInsights.map((text) => _InsightRow(text)),
        ],
      ),
    );
  }

  Widget _InsightRow(String text) {
    final bool isDark = AppColors.isDarkMode;
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: activeAccentColor, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: textSecondaryColor, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    final bool isDark = AppColors.isDarkMode;
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(msg, style: TextStyle(color: textTertiaryColor.withOpacity(0.5), fontSize: 12)),
      ),
    );
  }
}
