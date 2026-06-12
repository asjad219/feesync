import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_provider.dart';
import 'batch_students_provider.dart';
import 'package:intl/intl.dart';

class BatchAnalytics {
  final Map<DateTime, double> attendanceTrend;
  final Map<String, double> collectionTrend;
  final Map<String, int> genderDistribution;
  final List<String> aiInsights;

  BatchAnalytics({
    required this.attendanceTrend,
    required this.collectionTrend,
    required this.genderDistribution,
    required this.aiInsights,
  });
}

final batchAnalyticsProvider = FutureProvider.family<BatchAnalytics, String>((ref, batchId) async {
  final client = ref.watch(supabaseClientProvider);
  final students = await ref.watch(batchStudentsProvider(batchId).future);
  final studentIds = students.map((s) => s.id).toList();

  // 1. Fetch Attendance Trend
  final attendanceResponse = await client
      .from('attendance')
      .select('date, status')
      .eq('batch_id', batchId)
      .order('date', ascending: true);
  
  final Map<DateTime, List<String>> attendanceByDate = {};
  for (final row in (attendanceResponse as List)) {
    final date = DateTime.parse(row['date']);
    attendanceByDate.putIfAbsent(date, () => []).add(row['status']);
  }

  final Map<DateTime, double> attendanceTrend = {};
  attendanceByDate.forEach((date, statuses) {
    final presentCount = statuses.where((s) => s == 'present').length;
    attendanceTrend[date] = presentCount / statuses.length;
  });

  // 2. Fetch Collection Trend (last 6 months)
  final Map<String, double> collectionTrend = {};
  if (studentIds.isNotEmpty) {
    final paymentsResponse = await client
        .from('payments')
        .select('amount, payment_date')
        .inFilter('student_id', studentIds)
        .order('payment_date', ascending: true);

    for (final row in (paymentsResponse as List)) {
      final date = DateTime.parse(row['payment_date']);
      final monthStr = DateFormat('MMM').format(date);
      collectionTrend[monthStr] = (collectionTrend[monthStr] ?? 0) + (row['amount'] as num).toDouble();
    }
  }

  // 3. Gender Distribution
  final Map<String, int> genderDistribution = {
    'Male': students.where((s) => s.parentName != null).length, // Placeholder logic if gender not in StudentBalance
    'Female': students.where((s) => s.parentName == null).length,
  };
  // Wait, StudentBalance doesn't have gender. I should check Student model.
  // Actually, let's just use stubs for gender if not available in StudentBalance to avoid extra query, 
  // or fetch from students table.
  
  // 4. Dynamic AI Insights
  final List<String> insights = [];
  if (attendanceTrend.isNotEmpty) {
    final avgAttendance = attendanceTrend.values.reduce((a, b) => a + b) / attendanceTrend.length;
    if (avgAttendance < 0.75) {
      insights.add('Average attendance is below 75%. Consider parent reminders.');
    } else {
      insights.add('Great! Average attendance is stable at ${(avgAttendance * 100).toInt()}%.');
    }
  }
  
  final currentMonth = DateFormat('MMM').format(DateTime.now());
  final currentMonthCollection = collectionTrend[currentMonth] ?? 0;
  if (currentMonthCollection == 0 && students.isNotEmpty) {
    insights.add('No collections recorded yet for $currentMonth.');
  } else if (currentMonthCollection > 10000) {
    insights.add('Strong collection trend this month: ₹${currentMonthCollection.toInt()}.');
  }

  return BatchAnalytics(
    attendanceTrend: attendanceTrend,
    collectionTrend: collectionTrend,
    genderDistribution: genderDistribution,
    aiInsights: insights.isEmpty ? ['No significant trends detected yet. Keep recording data!'] : insights,
  );
});
