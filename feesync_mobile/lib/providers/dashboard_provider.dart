import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats.dart';
import '../repositories/payment_repository.dart';
import '../repositories/student_repository.dart';
import '../repositories/fee_repository.dart';
import 'supabase_provider.dart';
import 'package:intl/intl.dart';

final dashboardAnalyticsRepositoryProvider =
    Provider<DashboardAnalyticsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DashboardAnalyticsRepository(
    PaymentRepository(client),
    StudentRepository(client),
    FeeRepository(client),
  );
});

enum TimeCycle {
  monthly,
  quarterly,
  yearly,
}

final selectedTimeCycleProvider = StateProvider<TimeCycle>((ref) => TimeCycle.monthly);

void invalidateDashboardAnalytics(WidgetRef ref) {
  ref.invalidate(dashboardStatsProvider);
  ref.invalidate(monthlyCollectionDataProvider);
  ref.invalidate(categoryCollectionDataProvider);
  ref.invalidate(classCollectionDataProvider);
  ref.invalidate(recentTransactionsProvider);
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final cycle = ref.watch(selectedTimeCycleProvider);
  final repo = ref.watch(dashboardAnalyticsRepositoryProvider);
  return repo.getDashboardStatsForCycle(cycle);
});

final monthlyCollectionDataProvider =
    FutureProvider<List<MonthlyStat>>((ref) async {
  final repo = ref.watch(dashboardAnalyticsRepositoryProvider);
  return repo.getMonthlyCollectionData();
});

final categoryCollectionDataProvider =
    FutureProvider<List<CategoryStat>>((ref) async {
  final repo = ref.watch(dashboardAnalyticsRepositoryProvider);
  return repo.getCategoryCollectionData();
});

final classCollectionDataProvider = FutureProvider<List<ClassStat>>((ref) async {
  final repo = ref.watch(dashboardAnalyticsRepositoryProvider);
  return repo.getClassCollectionData();
});

final recentTransactionsProvider =
    FutureProvider<List<RecentTransaction>>((ref) async {
  final repo = ref.watch(dashboardAnalyticsRepositoryProvider);
  return repo.getRecentTransactions(limit: 5);
});

class DashboardAnalyticsRepository {
  final PaymentRepository _paymentRepo;
  final StudentRepository _studentRepo;
  final FeeRepository _feeRepo;
  static const _excludedDueStatuses = {'cancelled', 'deleted'};

  DashboardAnalyticsRepository(
    this._paymentRepo,
    this._studentRepo,
    this._feeRepo,
  );

  /// Get overall dashboard statistics
  Future<DashboardStats> getDashboardStats() => getDashboardStatsForCycle(TimeCycle.monthly);

  /// Get dashboard statistics filtered by time cycle
  Future<DashboardStats> getDashboardStatsForCycle(TimeCycle cycle) async {
    const timeout = Duration(seconds: 15);
    try {
      final now = DateTime.now();
      final cycleRange = _rangeForCycle(now, cycle);
      final previousCycleRange = _previousRangeForCycle(cycleRange, cycle);

      final results = await Future.wait<dynamic>([
        _studentRepo.getStudents().timeout(timeout),
        _studentRepo.getStudentBalances().timeout(timeout),
        _paymentRepo.getTotalCollection(
          startDate: cycleRange.start,
          endDate: cycleRange.endInclusive,
        ).timeout(timeout),
        _paymentRepo.getTotalCollection(
          startDate: previousCycleRange.start,
          endDate: previousCycleRange.endInclusive,
        ).timeout(timeout),
        _paymentRepo.getTotalCollection().timeout(timeout),
        _feeRepo.getDues().timeout(timeout),
      ]);

      final students = results[0] as List;
      final balances = results[1] as List;
      final periodCollection = results[2] as Map<String, dynamic>;
      final previousPeriodCollection = results[3] as Map<String, dynamic>;
      final allTimeCollection = results[4] as Map<String, dynamic>;
      final dues = results[5] as List;

      final totalStudents = students.length;
      final totalPending = balances.fold<double>(
        0,
        (sum, balance) => sum + (balance.dueAmount as double),
      );

      final totalCollectedInPeriod = _extractTotal(periodCollection);
      final totalCollectedInPreviousPeriod = _extractTotal(previousPeriodCollection);
      final totalCollectedAllTime = _extractTotal(allTimeCollection);

      final totalDue = dues.fold<double>(0, (sum, due) {
        final status = due.status.toString().toLowerCase();
        if (_excludedDueStatuses.contains(status)) {
          return sum;
        }
        return sum + (due.amountAssigned as double);
      });

      final collectionRate = totalDue > 0
          ? (totalCollectedAllTime / totalDue) * 100
          : 0.0;
      final growth = _calculateGrowth(
        currentAmount: totalCollectedInPeriod,
        previousAmount: totalCollectedInPreviousPeriod,
      );

      debugPrint(
        '[DashboardAnalytics] cycle=$cycle '
        'totalDue=$totalDue '
        'totalCollectedAllTime=$totalCollectedAllTime '
        'currentCycleCollections=$totalCollectedInPeriod '
        'previousCycleCollections=$totalCollectedInPreviousPeriod '
        'collectionRate=$collectionRate '
        'growth=${growth.isNewGrowth ? 'NEW' : growth.percentage} '
        'pendingFees=$totalPending',
      );

      return DashboardStats(
        totalStudents: totalStudents,
        totalFeesCollected: totalCollectedInPeriod,
        pendingFees: totalPending,
        collectionRate: collectionRate,
        growthPercentage: growth.percentage,
        isNewGrowth: growth.isNewGrowth,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error fetching dashboard stats for cycle $cycle: $e');
      rethrow;
    }
  }

  /// Get monthly collection data for the last 6 months
  Future<List<MonthlyStat>> getMonthlyCollectionData() async {
    const timeout = Duration(seconds: 15);
    try {
      final now = DateTime.now();
      final List<MonthlyStat> monthlyData = [];

      // Get data for last 6 months
      for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthRange = _monthRange(date);

        final collection = await _paymentRepo.getTotalCollection(
          startDate: monthRange.start,
          endDate: monthRange.endInclusive,
        ).timeout(timeout);

        final amount = (collection['total'] as num?)?.toDouble() ?? 0;
        final monthName = DateFormat('MMM').format(date);

        monthlyData.add(MonthlyStat(month: monthName, amount: amount));
      }

      return monthlyData;
    } catch (e) {
      debugPrint('Error fetching monthly data: $e');
      rethrow;
    }
  }

  /// Get collection breakdown by fee category
  Future<List<CategoryStat>> getCategoryCollectionData() async {
    const timeout = Duration(seconds: 15);
    try {
      final categories = await _feeRepo.getFeeCategories().timeout(timeout);
      final payments = await _paymentRepo.getPayments().timeout(timeout);
      final completedPayments = payments
          .where((payment) => payment.status.name == 'completed')
          .toList();

      double totalAmount = 0;
      final categoryTotals = <String, double>{};

      // Sum up payments by category
      for (var payment in completedPayments) {
        totalAmount += payment.amount;
        // In a real scenario, you would need to get the category from the fee structure
        // For now, we'll create a simplified version
      }

      // Convert to CategoryStat
      final stats = categories
          .map((cat) {
            final amount = categoryTotals[cat.id] ?? 0;
            final percentage =
                totalAmount > 0 ? (amount / totalAmount) * 100 : 0.0;
            return CategoryStat(
              name: cat.name,
              amount: amount,
              percentage: percentage.toDouble(),
            );
          })
          .where((stat) => stat.amount > 0)
          .toList();

      return stats;
    } catch (e) {
      debugPrint('Error fetching category data: $e');
      rethrow;
    }
  }

  /// Get collection breakdown by student class
  Future<List<ClassStat>> getClassCollectionData() async {
    const timeout = Duration(seconds: 15);
    try {
      final students = await _studentRepo.getStudents().timeout(timeout);
      final payments = await _paymentRepo.getPayments().timeout(timeout);
      final completedPayments = payments
          .where((payment) => payment.status.name == 'completed')
          .toList();
      final balances = await _studentRepo.getStudentBalances().timeout(timeout);

      // Group by class
      final classMap = <String, Map<String, double>>{};

      for (var student in students) {
        if (!classMap.containsKey(student.studentClass)) {
          classMap[student.studentClass] = {'collected': 0.0, 'pending': 0.0};
        }
      }

      // Sum collected by class
      for (var payment in completedPayments) {
        if (payment.student != null) {
          final className = payment.student!.studentClass;
          if (classMap.containsKey(className)) {
            classMap[className]!['collected'] =
                (classMap[className]!['collected'] as double) + payment.amount;
          }
        }
      }

      // Sum pending by class
      for (var balance in balances) {
        if (classMap.containsKey(balance.studentClass)) {
          classMap[balance.studentClass]!['pending'] =
              (classMap[balance.studentClass]!['pending'] as double) +
                  balance.dueAmount;
        }
      }

      // Convert to ClassStat
      return classMap.entries
          .map((entry) => ClassStat(
                className: entry.key,
                collected: entry.value['collected'] as double,
                pending: entry.value['pending'] as double,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error fetching class data: $e');
      rethrow;
    }
  }

  /// Get recent transactions
  Future<List<RecentTransaction>> getRecentTransactions({int limit = 5}) async {
    try {
      final payments = await _paymentRepo
          .getRecentPayments(limit: limit)
          .timeout(const Duration(seconds: 15));

      return payments
          .map((payment) => RecentTransaction(
                id: payment.id,
                studentName: payment.student?.fullName ?? 'Unknown',
                studentClass: payment.student?.studentClass ?? '',
                amount: payment.amount,
                feeType: 'Tuition Fee',
                date: payment.paymentDate,
                paymentMethod: payment.paymentMethod.name,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error fetching recent transactions: $e');
      rethrow;
    }
  }
}

class _CycleRange {
  final DateTime start;
  final DateTime endInclusive;

  const _CycleRange({
    required this.start,
    required this.endInclusive,
  });
}

class _GrowthResult {
  final double percentage;
  final bool isNewGrowth;

  const _GrowthResult({
    required this.percentage,
    required this.isNewGrowth,
  });
}

_CycleRange _rangeForCycle(DateTime date, TimeCycle cycle) {
  switch (cycle) {
    case TimeCycle.monthly:
      return _monthRange(date);
    case TimeCycle.quarterly:
      final quarterStartMonth = (((date.month - 1) ~/ 3) * 3) + 1;
      final start = DateTime(date.year, quarterStartMonth, 1);
      final nextStart = DateTime(date.year, quarterStartMonth + 3, 1);
      return _CycleRange(
        start: start,
        endInclusive: nextStart.subtract(const Duration(microseconds: 1)),
      );
    case TimeCycle.yearly:
      final start = DateTime(date.year, 1, 1);
      final nextStart = DateTime(date.year + 1, 1, 1);
      return _CycleRange(
        start: start,
        endInclusive: nextStart.subtract(const Duration(microseconds: 1)),
      );
  }
}

_CycleRange _previousRangeForCycle(_CycleRange currentRange, TimeCycle cycle) {
  switch (cycle) {
    case TimeCycle.monthly:
      return _monthRange(DateTime(currentRange.start.year, currentRange.start.month - 1, 1));
    case TimeCycle.quarterly:
      return _rangeForCycle(
        DateTime(currentRange.start.year, currentRange.start.month - 3, 1),
        TimeCycle.quarterly,
      );
    case TimeCycle.yearly:
      return _rangeForCycle(
        DateTime(currentRange.start.year - 1, 1, 1),
        TimeCycle.yearly,
      );
  }
}

_CycleRange _monthRange(DateTime date) {
  final start = DateTime(date.year, date.month, 1);
  final nextStart = DateTime(date.year, date.month + 1, 1);
  return _CycleRange(
    start: start,
    endInclusive: nextStart.subtract(const Duration(microseconds: 1)),
  );
}

double _extractTotal(Map<String, dynamic> result) {
  return (result['total'] as num?)?.toDouble() ?? 0.0;
}

_GrowthResult _calculateGrowth({
  required double currentAmount,
  required double previousAmount,
}) {
  if (previousAmount > 0) {
    return _GrowthResult(
      percentage: ((currentAmount - previousAmount) / previousAmount) * 100,
      isNewGrowth: false,
    );
  }

  if (currentAmount > 0) {
    return const _GrowthResult(
      percentage: 0,
      isNewGrowth: true,
    );
  }

  return const _GrowthResult(
    percentage: 0,
    isNewGrowth: false,
  );
}
