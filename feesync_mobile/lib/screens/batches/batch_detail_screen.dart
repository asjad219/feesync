import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/paywall_dialog.dart';
import '../../../core/billing/feature_gate.dart';
import '../../../providers/providers.dart';
import '../../../providers/subscription_provider.dart';
import '../../../models/models.dart';
import '../../../providers/local_settings_provider.dart';
import '../../../services/app_lock_service.dart';
import '../../../core/services/network_service.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/permission_guard.dart';

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batchAsync = ref.watch(batchByIdProvider(widget.batchId));
    final analytics = ref.watch(batchAnalyticsProvider(widget.batchId)).valueOrNull;
    final students = ref.watch(batchStudentsProvider(widget.batchId)).valueOrNull;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFC);
    final Color primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final Color textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);

    return PermissionGuard(
      permission: 'view_students',
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        body: batchAsync.when(
          data: (batch) {
            if (batch == null) return const Center(child: Text('Batch not found'));
            
            double actualAttendance = batch.attendancePercentage;
            double actualRevenue = batch.revenueGenerated;
            double actualPending = batch.pendingDues;

            if (analytics != null && analytics.attendanceTrend.isNotEmpty) {
              actualAttendance = analytics.attendanceTrend.values.reduce((a, b) => a + b) / analytics.attendanceTrend.length;
            }
            
            if (students != null && students.isNotEmpty) {
              actualRevenue = students.fold<double>(0.0, (sum, s) => sum + s.totalPaidAmount);
              actualPending = students.fold<double>(0.0, (sum, s) => sum + s.balance);
            }

            final displayBatch = batch.copyWith(
              attendancePercentage: actualAttendance,
              revenueGenerated: actualRevenue,
              pendingDues: actualPending,
            );

            return _buildContent(displayBatch, analytics, students);
          },
          loading: () {
            final isOnline = ref.watch(isOnlineProvider).value ?? true;
            if (!isOnline) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 80, color: Color(0xFFDC2626)),
                    const SizedBox(height: 24),
                    Text(
                      "📡 No Internet Connection",
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Please check your network and try again.",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(batchByIdProvider(widget.batchId)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }
            return Center(child: CircularProgressIndicator(color: primaryColor));
          },
          error: (err, _) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 80, color: Color(0xFFDC2626)),
                    const SizedBox(height: 24),
                    Text(
                      "Error Loading Batch Details",
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      err.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(batchByIdProvider(widget.batchId)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(Batch batch, BatchAnalytics? analytics, List<StudentBalance>? students) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildHeroHeader(batch, analytics, students),
        _buildStickyTabBar(batch.color),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(
            batch: batch,
            onAttendanceTap: () => _tabController.animateTo(2),
            onAddStudentTap: () async {
              final FeatureGate gate = ref.read(featureGateProvider).valueOrNull 
                  ?? await ref.read(featureGateProvider.future);
              if (!gate.canAddStudent) {
                if (mounted) {
                  await showPaywallDialog(
                    context,
                    ref,
                    trigger: PaywallTrigger.studentLimit,
                  );
                }
                return;
              }
              if (mounted) {
                // Navigate to add student with this batch pre-selected
                await context.push('/students/add?batchId=${batch.id}');
                // Refresh data upon returning
                ref.invalidate(batchStudentsProvider(batch.id));
                ref.invalidate(batchAnalyticsProvider(batch.id));
                ref.invalidate(batchByIdProvider(batch.id));
                ref.invalidate(batchNotifierProvider);
                invalidateDashboardAnalytics(ref);
              }
            },
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

  Widget _buildHeroHeader(Batch batch, BatchAnalytics? analytics, List<StudentBalance>? students) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFC);
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);

    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: scaffoldBgColor,
      iconTheme: IconThemeData(color: textPrimaryColor),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double expandedHeight = 340.0;
          final double collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
          final double scrollRatio = ((constraints.maxHeight - collapsedHeight) / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);
          final double opacity = (scrollRatio - 0.3).clamp(0.0, 0.7) / 0.7; // Fade out smoothly

          return FlexibleSpaceBar(
            title: Opacity(
              opacity: 1.0 - opacity,
              child: Text(
                batch.name,
                style: GoogleFonts.manrope(
                  color: textPrimaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            centerTitle: true,
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
                      color: batch.color.withValues(alpha: isDark ? 0.2 : 0.15),
                    ),
                  ),
                ),
                
                Opacity(
                  opacity: opacity,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, collapsedHeight + 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: batch.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.school, color: batch.color, size: 32),
                              ),
                              _AiHealthScore(result: _calculateHealthData(batch, analytics, students)),
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
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildStickyTabBar(Color accentColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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

class HealthScoreResult {
  final int score;
  final String statusText;
  final Color? customColor;
  final bool isInsufficientData;

  HealthScoreResult({
    required this.score,
    required this.statusText,
    this.customColor,
    this.isInsufficientData = false,
  });
}

HealthScoreResult _calculateHealthData(Batch batch, BatchAnalytics? analytics, List<StudentBalance>? students) {
  if (batch.studentCount == 0) {
    return HealthScoreResult(score: 0, statusText: 'No Students');
  }

  if (batch.studentCount < 3) {
    return HealthScoreResult(score: 0, statusText: '', isInsufficientData: true);
  }

  final bool hasAttendance = analytics != null && analytics.attendanceTrend.isNotEmpty;

  // Occupancy Score (30%)
  final double occupancyRatio = batch.maxCapacity > 0 ? (batch.studentCount / batch.maxCapacity) : 0.0;
  final double occupancyScore = (occupancyRatio * 100).clamp(0.0, 100.0) * 0.30;

  // Attendance Score (30%)
  double avgAttendance = batch.attendancePercentage;
  if (hasAttendance) {
    avgAttendance = analytics.attendanceTrend.values.reduce((a, b) => a + b) / analytics.attendanceTrend.length;
  }
  final double attendanceScore = (avgAttendance * 100).clamp(0.0, 100.0) * 0.30;

  // Fee Collection Score (25%)
  double collectionScore = 0.0;
  final double expectedCollection = batch.revenueGenerated + batch.pendingDues;
  if (expectedCollection > 0) {
    collectionScore = ((batch.revenueGenerated / expectedCollection) * 100).clamp(0.0, 100.0) * 0.25;
  }

  // Schedule Score (15%)
  // Since we don't have total exact session counts historically, we estimate from attendance records
  // or default to a reasonable baseline if sessions happened.
  double scheduleScore = 0.0;
  if (analytics != null && analytics.attendanceTrend.isNotEmpty) {
     // If they are recording attendance, we assume they are completing sessions.
     // In a full system we'd compare expected slots vs completed. For now, max it to 15%.
     scheduleScore = 100.0 * 0.15;
  }

  int totalScore = (occupancyScore + attendanceScore + collectionScore + scheduleScore).round().clamp(0, 100);

  String status;
  if (totalScore <= 20) {
    status = 'Critical';
  } else if (totalScore <= 50) {
    status = 'Poor';
  } else if (totalScore <= 75) {
    status = 'Good';
  } else if (totalScore <= 90) {
    status = 'Excellent';
  } else {
    status = 'Outstanding';
  }

  return HealthScoreResult(score: totalScore, statusText: status);
}

class _AiHealthScore extends StatelessWidget {
  final HealthScoreResult result;
  const _AiHealthScore({required this.result});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (result.isInsufficientData) {
      return GestureDetector(
        onTap: () => _showHealthDetailsDialog(context, result),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: AppColors.textTertiary, size: 16),
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
                  Text(
                    'Insufficient Data',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Color healthColor;
    if (result.score <= 20) {
      healthColor = const Color(0xFFEF4444); // Critical
    } else if (result.score <= 50) {
      healthColor = const Color(0xFFF97316); // Poor
    } else if (result.score <= 75) {
      healthColor = const Color(0xFFEAB308); // Good
    } else {
      healthColor = isDark ? const Color(0xFF10B981) : const Color(0xFF059669); // Excellent / Outstanding
    }

    return GestureDetector(
      onTap: () => _showHealthDetailsDialog(context, result),
      child: GlassCard(
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
                      '${result.score}%',
                      style: GoogleFonts.manrope(
                        color: healthColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${result.statusText})',
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
      ),
    );
  }

  void _showHealthDetailsDialog(BuildContext context, HealthScoreResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color surfaceColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
        final Color textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Batch Health',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              if (result.isInsufficientData) ...[
                Text(
                  'Insufficient Data',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add at least 3 students to unlock AI insights.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ] else ...[
                Text(
                  'Score: ${result.score}%',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Batch health is calculated using weighted metrics: Student Occupancy (30%), Attendance Rate (30%), Fee Collection Rate (25%), and Schedule Completion (15%).',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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

  List<Map<String, dynamic>> _generateUpcomingSessions(Batch batch) {
    final List<Map<String, dynamic>> sessions = [];
    DateTime current = DateTime.now();
    
    int targetCount = batch.schedules.isNotEmpty 
        ? batch.schedules.length 
        : (batch.scheduleDays.isNotEmpty ? batch.scheduleDays.length : 6);
    if (targetCount < 3) targetCount = 3;
    
    if (batch.schedules.isNotEmpty) {
      for (int i = 0; i < 30 && sessions.length < targetCount; i++) {
        final weekdayIndex = current.weekday - 1;
        try {
          final slot = batch.schedules.firstWhere((s) => s.dayOfWeek == weekdayIndex);
          sessions.add({'date': DateTime(current.year, current.month, current.day), 'slot': slot});
        } catch (_) {}
        current = current.add(const Duration(days: 1));
      }
    } else {
      final activeDays = batch.scheduleDays.isNotEmpty 
          ? batch.scheduleDays 
          : [0, 1, 2, 3, 4, 5]; // Mon to Sat

      for (int i = 0; i < 30 && sessions.length < targetCount; i++) {
        final weekdayIndex = current.weekday - 1;
        if (activeDays.contains(weekdayIndex)) {
          sessions.add({'date': DateTime(current.year, current.month, current.day), 'slot': null});
        }
        current = current.add(const Duration(days: 1));
      }
    }
    return sessions;
  }

  String _formatTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final time = TimeOfDay(hour: hour, minute: minute);
      
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final sessions = _generateUpcomingSessions(batch);
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
          _buildSectionHeader(context, 'Upcoming Schedule'),
          const SizedBox(height: 12),
          ...sessions.map((session) {
            final date = session['date'] as DateTime;
            final slot = session['slot'] as ScheduleSlot?;
            final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
            final startTime = slot?.startTime ?? batch.startTime;
            final endTime = slot?.endTime ?? batch.endTime;
            
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
                          '${_formatTimeString(startTime)} - ${_formatTimeString(endTime)}',
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.manrope(color: textPrimaryColor, fontSize: 18, fontWeight: FontWeight.w700)),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondaryColor = isDark ? const Color(0xFFC3C6D7) : const Color(0xFF475569);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);

    return studentsAsync.when(
      data: (students) => ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: students.length,
        itemBuilder: (context, index) => _StudentListTile(student: students[index], batchId: batchId),
      ),
      loading: () {
        final isOnline = ref.watch(isOnlineProvider).value ?? true;
        if (!isOnline) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No Internet Connection",
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please check your network and try again.",
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        return Center(child: CircularProgressIndicator(color: primaryColor));
      },
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                "Error Loading Students",
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentListTile extends ConsumerWidget {
  final StudentBalance student;
  final String batchId;
  const _StudentListTile({required this.student, required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return InkWell(
      onTap: () async {
        await context.push('/students/${student.id}');
        ref.invalidate(batchStudentsProvider(batchId));
        ref.invalidate(batchAnalyticsProvider(batchId));
        ref.invalidate(batchByIdProvider(batchId));
      },
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            StudentAvatar(
              studentId: student.id, 
              firstName: student.firstName, 
              gender: student.gender, 
              radius: 24
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${student.firstName} ${student.lastName}${student.rollNumber != null && student.rollNumber!.isNotEmpty ? ' • Roll: ${student.rollNumber}' : ''}',
                    style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
                  ),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: primaryColor.withValues(alpha: 0.3)) : null,
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
    final historyAsync = ref.watch(batchAttendanceProvider(batchId));
    
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);

    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final isTakenToday = historyAsync.value?.any((r) => r.date.toIso8601String().split('T')[0] == todayStr) ?? false;

    return Column(
      children: [
        _buildAttendanceHeader(context, ref, studentsAsync.value ?? [], isTakenToday),
        if (isTakenToday)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 12),
                Text(
                  "Today's attendance is taken",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        if (attendanceState.statuses.isNotEmpty && !isTakenToday)
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
            loading: () {
              final isOnline = ref.watch(isOnlineProvider).value ?? true;
              final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
              if (!isOnline) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          "No Internet Connection",
                          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimaryColor),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Center(child: CircularProgressIndicator(color: primaryColor));
            },
            error: (err, _) {
              final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
              return Center(
                child: Text(
                  'Error: $err',
                  style: TextStyle(color: textPrimaryColor),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceHeader(BuildContext context, WidgetRef ref, List<StudentBalance> students, bool isTakenToday) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                  'Today, ${DateFormat('MMM d').format(DateTime.now())}',
                  style: GoogleFonts.manrope(color: textPrimaryColor, fontWeight: FontWeight.bold),
                ),
                Text('Daily Roster', style: GoogleFonts.inter(color: textTertiaryColor, fontSize: 12)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: students.isEmpty || isTakenToday
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);

    return historyAsync.when(
      data: (records) {
        if (records.isEmpty) return _buildEmptyHistory(context);
        
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

  Widget _buildEmptyHistory(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 48, color: textTertiaryColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No history records yet', style: GoogleFonts.inter(color: textTertiaryColor)),
        ],
      ),
    );
  }

  void _showSessionDetails(BuildContext context, DateTime date, List<AttendanceRecord> records, Map<String, String> studentNames) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
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

  String _formatHistoryDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) {
      return 'Today, ${DateFormat('MMM d').format(date)}';
    } else if (dateToCompare == yesterday) {
      return 'Yesterday, ${DateFormat('MMM d').format(date)}';
    } else {
      return DateFormat('EEEE, MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (presentCount / totalCount * 100).toInt();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                  color: healthColor.withValues(alpha: 0.1),
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
                      _formatHistoryDate(date),
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

class _SessionDetailsSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final List<AttendanceRecord> records;
  final Map<String, String> studentNames;

  const _SessionDetailsSheet({
    required this.date,
    required this.records,
    required this.studentNames,
  });

  @override
  ConsumerState<_SessionDetailsSheet> createState() => _SessionDetailsSheetState();
}

class _SessionDetailsSheetState extends ConsumerState<_SessionDetailsSheet> {
  bool _isEditMode = false;
  bool _isSaving = false;
  late Map<String, bool> _localStatuses;

  @override
  void initState() {
    super.initState();
    _localStatuses = {
      for (var r in widget.records) r.id: r.status == AttendanceStatus.present
    };
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final client = ref.read(supabaseClientProvider);
      
      for (var r in widget.records) {
        final wasPresent = r.status == AttendanceStatus.present;
        final isNowPresent = _localStatuses[r.id] ?? false;
        
        if (wasPresent != isNowPresent) {
          await client.from('attendance').update({
            'status': isNowPresent ? 'present' : 'absent',
          }).eq('id', r.id);
        }
      }

      if (widget.records.isNotEmpty) {
        final batchId = widget.records.first.batchId;
        ref.invalidate(batchAttendanceProvider(batchId));
        ref.invalidate(batchAnalyticsProvider(batchId));
        ref.invalidate(batchByIdProvider(batchId));
        ref.invalidate(batchNotifierProvider);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance updated successfully')));
        Navigator.pop(context); // Close the sheet to let it refresh cleanly
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFFB4C5FF) : const Color(0xFF2563EB);
    final bool isEditable = DateTime.now().difference(widget.date).inDays <= 7;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
                  Text(DateFormat('MMMM d, yyyy').format(widget.date), style: GoogleFonts.inter(fontSize: 14, color: textTertiaryColor)),
                ],
              ),
              if (!_isEditMode)
                IconButton(
                  onPressed: () => Navigator.pop(context), 
                  icon: Icon(Icons.close_rounded, color: textTertiaryColor)
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isEditable)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditMode ? 'Modify attendance:' : 'Session records are locked after 7 days.',
                  style: GoogleFonts.inter(
                    fontSize: 12, 
                    color: isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B),
                  ),
                ),
                if (!_isEditMode)
                  TextButton.icon(
                    onPressed: () => setState(() => _isEditMode = true),
                    icon: Icon(Icons.edit_rounded, size: 16, color: primaryColor),
                    label: Text('Edit', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.records.length,
              itemBuilder: (context, index) {
                final r = widget.records[index];
                final isPresent = _localStatuses[r.id] ?? false;
                final studentName = widget.studentNames[r.studentId] ?? 'Student';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isEditMode && isPresent 
                          ? const Color(0xFF10B981).withValues(alpha: 0.3) 
                          : (_isEditMode && !isPresent 
                              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                              : Colors.transparent),
                    ),
                  ),
                  child: Row(
                    children: [
                      StudentAvatar(
                        studentId: r.studentId,
                        firstName: studentName.split(' ').first,
                        radius: 16,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          studentName,
                          style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_isEditMode)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _localStatuses[r.id] = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isPresent ? const Color(0xFF10B981) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isPresent ? const Color(0xFF10B981) : textTertiaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Text('P', style: TextStyle(color: isPresent ? Colors.white : textTertiaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _localStatuses[r.id] = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: !isPresent ? const Color(0xFFEF4444) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: !isPresent ? const Color(0xFFEF4444) : textTertiaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Text('A', style: TextStyle(color: !isPresent ? Colors.white : textTertiaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        )
                      else
                        StatusBadge(status: isPresent ? 'PRESENT' : 'ABSENT'),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isEditMode) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSaving ? null : () {
                      setState(() {
                        _isEditMode = false;
                        // Reset local statuses
                        _localStatuses = {
                          for (var r in widget.records) r.id: r.status == AttendanceStatus.present
                        };
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: textTertiaryColor, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);

    final displayRoll = student.rollNumber != null && student.rollNumber!.isNotEmpty
        ? RegExp(r'\d+$').stringMatch(student.rollNumber!) ?? student.rollNumber
        : null;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          StudentAvatar(
            studentId: student.id, 
            firstName: student.firstName, 
            gender: student.gender, 
            radius: 20
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${student.firstName} ${student.lastName}${displayRoll != null ? ' • Roll: $displayRoll' : ''}',
                  style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                    children: defaulters.map((s) => _DefaulterTile(student: s, batchId: batchId)).toList(),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ReminderPreviewSheet(
        title: 'Send All Reminders',
        subtitle: 'You are about to send reminders to ${defaulters.length} students.',
        students: defaulters,
        batchId: batchId,
        onConfirm: (_) async {
          Navigator.pop(context);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => _BulkSendProgressDialog(
              defaulters: defaulters,
              batchId: batchId,
            ),
          );
        },
      ),
    );
  }

  static void _launchWhatsAppWithMessage(StudentBalance s, String message) async {
    final phone = s.parentPhone ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

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
                backgroundColor: color.withValues(alpha: 0.1),
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
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: textSecondaryColor, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _DefaulterTile extends ConsumerWidget {
  final StudentBalance student;
  final String batchId;
  const _DefaulterTile({required this.student, required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await context.push('/students/${student.id}');
          ref.invalidate(batchStudentsProvider(batchId));
          ref.invalidate(batchAnalyticsProvider(batchId));
          ref.invalidate(batchByIdProvider(batchId));
        },
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              StudentAvatar(
                studentId: student.id, 
                firstName: student.firstName, 
                gender: student.gender, 
                radius: 24
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName + (student.rollNumber != null && student.rollNumber!.isNotEmpty ? ' • Roll: ${student.rollNumber}' : ''),
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textPrimaryColor),
                    ),
                  ],
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ReminderPreviewSheet(
        title: 'Send Reminder',
        subtitle: 'Send fee reminder to ${student.fullName}\'s parent.',
        students: [student],
        batchId: batchId,
        onConfirm: (messageText) {
          Navigator.pop(context);
          _FeesTab._launchWhatsAppWithMessage(student, messageText);
        },
      ),
    );
  }
}

class _ReminderPreviewSheet extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final List<StudentBalance> students;
  final String batchId;
  final Function(String) onConfirm;

  const _ReminderPreviewSheet({
    required this.title,
    required this.subtitle,
    required this.students,
    required this.batchId,
    required this.onConfirm,
  });

  @override
  ConsumerState<_ReminderPreviewSheet> createState() => _ReminderPreviewSheetState();
}

class _ReminderPreviewSheetState extends ConsumerState<_ReminderPreviewSheet> {
  bool _isEditing = false;
  late TextEditingController _messageController;
  String _dueDateStr = 'N/A';
  bool _isLoadingDues = true;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    if (widget.students.length == 1) {
      _loadOldestDueDate();
    } else {
      _isLoadingDues = false;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadOldestDueDate() async {
    try {
      final studentId = widget.students.first.id;
      final dues = await ref.read(feeRepositoryProvider).getDues(studentId: studentId);
      final unpaid = dues.where((d) => d.status != 'paid' && d.status != 'cancelled').toList();
      if (unpaid.isNotEmpty) {
        unpaid.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        if (mounted) {
          setState(() {
            _dueDateStr = DateFormat('dd MMM yyyy').format(unpaid.first.dueDate);
            _isLoadingDues = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingDues = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDues = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    final settingsAsync = ref.watch(settingsProvider);
    final batchAsync = ref.watch(batchByIdProvider(widget.batchId));

    if (widget.students.length == 1) {
      if (_isLoadingDues || settingsAsync.isLoading || batchAsync.isLoading) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
          ),
        );
      }

      final settings = settingsAsync.valueOrNull;
      final batch = batchAsync.valueOrNull;
      final student = widget.students.first;

      final template = settings?.tplFeeReminder ?? 'Hi {parent_name}, this is a reminder that a fee of ₹{amount} is due for {student_name} on {due_date}. Please pay on time to avoid late charges. — {school_name}';
      final instituteName = settings?.centerName ?? '';
      final batchName = batch?.name ?? '';

      if (!_isControllerInitialized) {
        final generatedMessage = generateReminderMessage(
          template: template,
          student: student,
          batchName: batchName,
          instituteName: instituteName,
          dueDate: _dueDateStr,
        );
        _messageController.text = generatedMessage;
        _isControllerInitialized = true;
      }
    }
// ... [rest of _ReminderPreviewSheet is here, unchanged until _BulkSendProgressDialog] ...

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimaryColor)),
                    const SizedBox(height: 4),
                    Text(widget.subtitle, style: GoogleFonts.inter(fontSize: 13, color: textTertiaryColor)),
                  ],
                ),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: textTertiaryColor)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MESSAGE PREVIEW', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: textTertiaryColor)),
              if (widget.students.length == 1)
                IconButton(
                  icon: Icon(_isEditing ? Icons.check_circle_outline_rounded : Icons.edit_rounded, size: 20, color: const Color(0xFF2563EB)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _isEditing = !_isEditing),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditing && widget.students.length == 1) ...[
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              minLines: 3,
              style: GoogleFonts.inter(fontSize: 14, color: textPrimaryColor, height: 1.5),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "You can customize this reminder before sending. Changes made here affect only this reminder and will not modify the default reminder template in Settings.",
              style: GoogleFonts.inter(fontSize: 11, color: textTertiaryColor, height: 1.4),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: Text(
                widget.students.length > 1 
                  ? 'Multiple personalized messages will be sent...'
                  : _messageController.text,
                style: GoogleFonts.inter(fontSize: 14, color: textPrimaryColor, height: 1.5),
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.students.length == 1) {
                  final textToSend = _messageController.text.trim();
                  if (textToSend.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reminder message cannot be empty.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  widget.onConfirm(textToSend);
                } else {
                  widget.onConfirm('');
                }
              },
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
                widget.students.length > 1 ? 'SEND ALL VIA WHATSAPP' : 'SEND VIA WHATSAPP',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkSendProgressDialog extends ConsumerStatefulWidget {
  final List<StudentBalance> defaulters;
  final String batchId;

  const _BulkSendProgressDialog({
    required this.defaulters,
    required this.batchId,
  });

  @override
  ConsumerState<_BulkSendProgressDialog> createState() => _BulkSendProgressDialogState();
}

class _BulkSendProgressDialogState extends ConsumerState<_BulkSendProgressDialog> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Map<String, String> _dueDates = {};
  bool _isLoadingDueDates = true;
  bool _isSending = false;
  bool _isPaused = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAllDueDates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isSending && !_isPaused) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && _isSending && !_isPaused) {
          _sendNext();
        }
      });
    }
  }

  Future<void> _loadAllDueDates() async {
    try {
      final studentIds = widget.defaulters.map((d) => d.id).toList();
      final client = ref.read(supabaseClientProvider);
      final response = await client
          .from('dues')
          .select('student_id, due_date')
          .inFilter('student_id', studentIds)
          .neq('status', 'paid')
          .neq('status', 'cancelled')
          .order('due_date', ascending: true);
          
      final Map<String, String> dates = {};
      for (final row in response as List) {
        final studentId = row['student_id'] as String;
        final rawDate = row['due_date'] as String;
        if (!dates.containsKey(studentId)) {
          final dt = DateTime.parse(rawDate);
          dates[studentId] = DateFormat('dd MMM yyyy').format(dt);
        }
      }
      if (mounted) {
        setState(() {
          _dueDates = dates;
          _isLoadingDueDates = false;
          _isSending = true;
        });
        _sendCurrent();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDueDates = false;
          _isSending = true;
        });
        _sendCurrent();
      }
    }
  }

  void _sendNext() {
    setState(() {
      _currentIndex++;
    });
    _sendCurrent();
  }

  Future<void> _sendCurrent() async {
    if (_currentIndex >= widget.defaulters.length) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All reminders sent successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
      return;
    }

    final student = widget.defaulters[_currentIndex];
    final phone = student.parentPhone ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Skipping ${student.fullName} (No phone number)')),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _sendNext();
        }
      });
      return;
    }

    final settings = ref.read(settingsProvider).valueOrNull;
    final batch = ref.read(batchByIdProvider(widget.batchId)).valueOrNull;
    
    final template = settings?.tplFeeReminder ?? 'Hi {parent_name}, this is a reminder that a fee of ₹{amount} is due for {student_name} on {due_date}. Please pay on time to avoid late charges. — {school_name}';
    final instituteName = settings?.centerName ?? '';
    final batchName = batch?.name ?? '';
    
    final message = generateReminderMessage(
      template: template,
      student: student,
      batchName: batchName,
      instituteName: instituteName,
      dueDate: _dueDates[student.id] ?? 'N/A',
    );

    final url = 'https://wa.me/${cleanPhone.startsWith('+') ? cleanPhone : '+91$cleanPhone'}?text=${Uri.encodeComponent(message)}';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          _errorMsg = 'Could not launch WhatsApp for ${student.fullName}';
          _isPaused = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error sending reminder for ${student.fullName}: $e';
        _isPaused = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? const Color(0xFFE3E0F4) : const Color(0xFF0F172A);
    final textSecondaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sending Reminders',
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              _isLoadingDueDates
                  ? 'Loading student dues...'
                  : 'Progress: ${_currentIndex + 1} of ${widget.defaulters.length}',
              style: GoogleFonts.inter(fontSize: 14, color: textSecondaryColor),
            ),
            const SizedBox(height: 20),
            if (_isLoadingDueDates)
              const CircularProgressIndicator(color: Color(0xFF2563EB))
            else ...[
              LinearProgressIndicator(
                value: widget.defaulters.isEmpty ? 0 : (_currentIndex + 1) / widget.defaulters.length,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
              const SizedBox(height: 20),
              Text(
                _isPaused
                    ? 'Paused: $_errorMsg'
                    : 'Opening WhatsApp for ${widget.defaulters[_currentIndex].fullName}\'s parent...',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: textPrimaryColor),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isPaused) ...[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isPaused = false;
                        _errorMsg = '';
                      });
                      _sendCurrent();
                    },
                    child: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      _sendNext();
                    },
                    child: Text('Skip', style: GoogleFonts.inter(color: textSecondaryColor)),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSending = false;
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Cancel', style: GoogleFonts.inter(color: Colors.redAccent)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

String generateReminderMessage({
  required String template,
  required StudentBalance student,
  required String batchName,
  required String instituteName,
  required String dueDate,
}) {
  final String parentName = (student.parentName == null || student.parentName!.trim().isEmpty)
      ? "Parent"
      : student.parentName!.trim();

  final String studentName = student.firstName.trim().isEmpty
      ? "Student"
      : student.fullName.trim();

  final double dueVal = student.balance > 0 ? student.balance : student.dueAmount;
  final String dueAmountStr = dueVal > 0 
      ? '₹${NumberFormat('#,###').format(dueVal)}' 
      : 'Pending Fee';

  final String finalDueDate = dueDate.isEmpty ? 'N/A' : dueDate;

  String msg = template;
  
  msg = msg.replaceAll('{parent_name}', parentName);
  msg = msg.replaceAll('{student_name}', studentName);
  
  msg = msg.replaceAll('{due_amount}', dueAmountStr);
  msg = msg.replaceAll('{amount}', dueAmountStr);
  
  msg = msg.replaceAll('{batch_name}', batchName.isEmpty ? 'N/A' : batchName);
  
  final String instName = instituteName.isEmpty ? 'FeeSync' : instituteName;
  msg = msg.replaceAll('{institute_name}', instName);
  msg = msg.replaceAll('{school_name}', instName);
  
  msg = msg.replaceAll('{due_date}', finalDueDate);
  
  msg = msg.replaceAll(RegExp(r'\{[^}]*\}'), '');
  
  return msg;
}

class _AnalyticsTab extends ConsumerWidget {
  final String batchId;
  final Color? accentColor;
  const _AnalyticsTab({required this.batchId, this.accentColor});

  Color get activeAccentColor => accentColor ?? AppColors.primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(batchAnalyticsProvider(batchId));
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
              _buildAttendanceTrend(context, analytics),
              const SizedBox(height: 24),
              _buildCollectionTrend(context, analytics),
              const SizedBox(height: 24),
              _buildStudentMetrics(context, analytics),
              const SizedBox(height: 24),
              _buildAiInsights(context, analytics),
              const SizedBox(height: 32),
              _buildAdminDangerZone(context, ref),
            ],
          ),
        ),
      ),
      loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildAttendanceTrend(BuildContext context, BatchAnalytics data) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
            _buildEmptyState(context, 'No attendance recorded yet')
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
                              colors: [const Color(0xFF10B981), const Color(0xFF10B981).withValues(alpha: 0.3)],
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

  Widget _buildCollectionTrend(BuildContext context, BatchAnalytics data) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
            _buildEmptyState(context, 'No collections recorded yet')
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
                              colors: [const Color(0xFF2563EB), const Color(0xFF2563EB).withValues(alpha: 0.3)],
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

  Widget _buildStudentMetrics(BuildContext context, BatchAnalytics data) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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

  Widget _buildAiInsights(BuildContext context, BatchAnalytics data) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: activeAccentColor.withValues(alpha: 0.3),
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
          ...data.aiInsights.map((text) => _buildInsightRow(context, text)),
        ],
      ),
    );
  }

  Widget _buildInsightRow(BuildContext context, String text) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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

  Widget _buildEmptyState(BuildContext context, String msg) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiaryColor = isDark ? const Color(0xFF8D90A0) : const Color(0xFF64748B);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(msg, style: TextStyle(color: textTertiaryColor.withValues(alpha: 0.5), fontSize: 12)),
      ),
    );
  }

  Widget _buildAdminDangerZone(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final user = userProfileAsync.value;
    
    // Only show for admins or owners
    if (user == null || (user.role != 'admin' && user.role != 'owner')) {
      return const SizedBox.shrink();
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Danger Zone', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFFEF4444))),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.1) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delete Batch', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C))),
              const SizedBox(height: 4),
              Text('Once you delete a batch, there is no going back. Please be certain.', style: GoogleFonts.inter(fontSize: 12, color: isDark ? const Color(0xFFFECACA) : const Color(0xFFDC2626))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Note: Batch will not delete if App Lock is enabled.',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleDeleteBatchClick(context, ref),
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 18),
                  label: const Text('DELETE BATCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleDeleteBatchClick(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(localSettingsProvider);
    
    if (settings.biometricEnabled) {
      final appLock = ref.read(appLockServiceProvider);
      final canUse = await appLock.canUseBiometrics();
      if (canUse) {
        final authenticated = await appLock.authenticateWithBiometrics(
          'Please authenticate to delete this batch',
        );
        if (!authenticated) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Authentication failed. Cannot delete batch.'), backgroundColor: Colors.red),
            );
          }
          return;
        }
        debugPrint('[DEBUG] Biometric success received');
      }
    }
    
    if (context.mounted) {
      _confirmDeleteBatch(context, ref);
    }
  }

  void _confirmDeleteBatch(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    bool isDeleting = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              isDeleting ? 'Deleting Batch...' : 'Delete Batch?', 
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDeleting) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(color: Color(0xFFEF4444)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Deleting batch and updating related records. Please wait...',
                      style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Are you sure you want to delete this batch? All related records will be updated or deleted. This action cannot be undone.', 
                    style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ],
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actionsAlignment: MainAxisAlignment.end,
            actions: isDeleting ? [] : [
              TextButton(
                onPressed: () async {
                  setState(() {
                    isDeleting = true;
                    errorMessage = null;
                  });
                  debugPrint('[DEBUG] Confirmation button pressed');
                  try {
                    await ref.read(batchNotifierProvider.notifier).deleteBatch(batchId);

                    ref.invalidate(activeBatchCountProvider);
                    ref.invalidate(subscriptionScreenDataProvider);
                    ref.invalidate(featureGateProvider);
                    ref.invalidate(batchByIdProvider(batchId));
                    ref.invalidate(batchStudentsProvider(batchId));
                    ref.invalidate(batchAnalyticsProvider(batchId));
                    invalidateDashboardAnalytics(ref);

                    debugPrint('[DEBUG] UI refreshed');

                    // Close only the dialog, not the whole screen
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }

                    // Navigate and show snackbar after dialog is dismissed
                    if (context.mounted) {
                      GoRouter.of(context).go('/batches');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Batch deleted successfully.'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('[DEBUG] Delete failed: $e');
                    setState(() {
                      isDeleting = false;
                      errorMessage = e.toString().contains('Exception:') 
                          ? e.toString().replaceAll('Exception:', '').trim()
                          : 'Unable to delete batch. Please try again.';
                    });
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'DELETE',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
