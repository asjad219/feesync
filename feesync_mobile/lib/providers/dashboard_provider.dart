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

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repo = ref.watch(dashboardAnalyticsRepositoryProvider);
  return repo.getDashboardStats();
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

  DashboardAnalyticsRepository(
    this._paymentRepo,
    this._studentRepo,
    this._feeRepo,
  );

  /// Get overall dashboard statistics
  Future<DashboardStats> getDashboardStats() async {
    try {
      // Get total students
      final students = await _studentRepo.getStudents();
      final totalStudents = students.length;

      // Get balance information
      final balances = await _studentRepo.getStudentBalances();
      final totalPending = balances.fold<double>(
        0,
        (sum, balance) => sum + balance.balance,
      );

      // Get total collected this month
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final monthlyCollection = await _paymentRepo.getTotalCollection(
        startDate: monthStart,
        endDate: monthEnd,
      );
      final collectedThisMonth =
          (monthlyCollection['total'] as num?)?.toDouble() ?? 0;

      // Get all-time collection
      final allTimeCollection = await _paymentRepo.getTotalCollection();
      final totalCollected =
          (allTimeCollection['total'] as num?)?.toDouble() ?? 0;

      // Calculate collection rate
      final totalFees = balances.fold<double>(
        totalCollected,
        (sum, balance) => sum + balance.totalFeeAmount,
      );

      final collectionRate =
          totalFees > 0 ? (totalCollected / totalFees) * 100 : 0.0;

      return DashboardStats(
        totalStudents: totalStudents,
        totalFeesCollected: collectedThisMonth,
        pendingFees: totalPending,
        collectionRate: collectionRate.toDouble(),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      rethrow;
    }
  }

  /// Get monthly collection data for the last 6 months
  Future<List<MonthlyStat>> getMonthlyCollectionData() async {
    try {
      final now = DateTime.now();
      final List<MonthlyStat> monthlyData = [];

      // Get data for last 6 months
      for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final nextMonth = DateTime(date.year, date.month + 1, 1);
        final lastDay = DateTime(nextMonth.year, nextMonth.month, 0);

        final collection = await _paymentRepo.getTotalCollection(
          startDate: date,
          endDate: lastDay,
        );

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
    try {
      final categories = await _feeRepo.getFeeCategories();
      final payments = await _paymentRepo.getPayments();

      double totalAmount = 0;
      final categoryTotals = <String, double>{};

      // Sum up payments by category
      for (var payment in payments) {
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
    try {
      final students = await _studentRepo.getStudents();
      final payments = await _paymentRepo.getPayments();
      final balances = await _studentRepo.getStudentBalances();

      // Group by class
      final classMap = <String, Map<String, double>>{};

      for (var student in students) {
        if (!classMap.containsKey(student.studentClass)) {
          classMap[student.studentClass] = {'collected': 0.0, 'pending': 0.0};
        }
      }

      // Sum collected by class
      for (var payment in payments) {
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
                  balance.balance;
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
      final payments = await _paymentRepo.getRecentPayments(limit: limit);

      return payments
          .map((payment) => RecentTransaction(
                id: payment.id,
                studentName: payment.student?.fullName ?? 'Unknown',
                studentClass: payment.student?.studentClass ?? '',
                amount: payment.amount,
                feeType: 'Tuition Fee', // You can make this dynamic
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
