import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_stats.dart';
import '../repositories/payment_repository.dart';
import '../repositories/student_repository.dart';
import '../repositories/fee_repository.dart';
import '../core/services/cache_service.dart';
import 'supabase_provider.dart';
import 'sync_provider.dart';
import 'package:intl/intl.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final dashboardAnalyticsRepositoryProvider =
    Provider<DashboardAnalyticsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DashboardAnalyticsRepository(
    PaymentRepository(client),
    StudentRepository(client),
    FeeRepository(client),
    client,
  );
});

// ── Time cycle ────────────────────────────────────────────────────────────────

enum TimeCycle { monthly, quarterly, yearly }

final selectedTimeCycleProvider =
    StateProvider<TimeCycle>((ref) => TimeCycle.monthly);

// ── Dashboard Stats Notifier ──────────────────────────────────────────────────

class DashboardStatsNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  final DashboardAnalyticsRepository _repo;
  final CacheService _cache;
  final String? _accountId;
  final Ref _ref;

  DashboardStatsNotifier(this._repo, this._cache, this._accountId, this._ref)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    if (_accountId == null) return;
    // 1. Emit cached data immediately (zero-wait render)
    final cached = await _cache.loadDashboardStats(_accountId);
    if (cached != null) {
      state = AsyncValue.data(cached);
      debugPrint('[Dashboard] Loaded stats from cache');
    }
    // 2. Fetch from network in background
    await fetch();
  }

  Future<void> fetch([TimeCycle? cycle]) async {
    if (_accountId == null) return;
    final timeCycle = cycle ?? TimeCycle.monthly;
    try {
      final stats = await _repo.getDashboardStatsForCycle(timeCycle);
      await _cache.saveDashboardStats(_accountId, stats);
      // Update global last sync time
      _ref.read(lastSyncTimesProvider.notifier).update(
            (s) => {...s, 'dashboard': DateTime.now()},
          );
      state = AsyncValue.data(stats);
      debugPrint('[Dashboard] Fetched fresh stats from network');
    } catch (e, st) {
      debugPrint('[Dashboard][OFFLINE] getDashboardStats failed: $e');
      if (state is AsyncData) {
        _ref.read(offlineToastProvider.notifier).state = "You're offline. Showing saved data.";
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

// ── Monthly Stats Notifier ────────────────────────────────────────────────────

class MonthlyStatsNotifier extends StateNotifier<AsyncValue<List<MonthlyStat>>> {
  final DashboardAnalyticsRepository _repo;
  final CacheService _cache;
  final String? _accountId;

  MonthlyStatsNotifier(this._repo, this._cache, this._accountId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    if (_accountId == null) return;
    // 1. Emit cached data immediately
    final cached = await _cache.loadMonthlyStats(_accountId);
    if (cached != null) {
      state = AsyncValue.data(cached);
      debugPrint('[Dashboard] Loaded monthly stats from cache');
    }
    await fetch();
  }

  Future<void> fetch() async {
    if (_accountId == null) return;
    try {
      final data = await _repo.getMonthlyCollectionData();
      await _cache.saveMonthlyStats(_accountId, data);
      state = AsyncValue.data(data);
    } catch (e, st) {
      debugPrint('[Dashboard][OFFLINE] getMonthlyCollectionData failed: $e');
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

// ── Recent Transactions Notifier ─────────────────────────────────────────────

class RecentTransactionsNotifier
    extends StateNotifier<AsyncValue<List<RecentTransaction>>> {
  final DashboardAnalyticsRepository _repo;
  final CacheService _cache;
  final String? _accountId;

  RecentTransactionsNotifier(this._repo, this._cache, this._accountId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    if (_accountId == null) return;
    // 1. Emit cached data immediately
    final cached = await _cache.loadRecentTransactions(_accountId);
    if (cached != null) {
      state = AsyncValue.data(cached);
      debugPrint('[Dashboard] Loaded recent transactions from cache');
    }
    await fetch();
  }

  Future<void> fetch() async {
    if (_accountId == null) return;
    try {
      final data = await _repo.getRecentTransactions(limit: 5);
      await _cache.saveRecentTransactions(_accountId, data);
      state = AsyncValue.data(data);
    } catch (e, st) {
      debugPrint('[Dashboard][OFFLINE] getRecentTransactions failed: $e');
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

// ── Class Stats Notifier ─────────────────────────────────────────────────────

class ClassStatsNotifier extends StateNotifier<AsyncValue<List<ClassStat>>> {
  final DashboardAnalyticsRepository _repo;
  final CacheService _cache;
  final String? _accountId;

  ClassStatsNotifier(this._repo, this._cache, this._accountId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    if (_accountId == null) return;
    // 1. Emit cached data immediately
    final cached = await _cache.loadClassStats(_accountId);
    if (cached != null) {
      state = AsyncValue.data(cached);
      debugPrint('[Dashboard] Loaded class stats from cache');
    }
    await fetch();
  }

  Future<void> fetch() async {
    if (_accountId == null) return;
    try {
      final data = await _repo.getClassCollectionData();
      await _cache.saveClassStats(_accountId, data);
      state = AsyncValue.data(data);
    } catch (e, st) {
      debugPrint('[Dashboard][OFFLINE] getClassCollectionData failed: $e');
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _accountIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.id;
});

final dashboardStatsProvider =
    StateNotifierProvider<DashboardStatsNotifier, AsyncValue<DashboardStats>>(
        (ref) {
  final repo = ref.watch(dashboardAnalyticsRepositoryProvider);
  final cache = ref.watch(cacheServiceProvider);
  final accountId = ref.watch(_accountIdProvider);
  return DashboardStatsNotifier(repo, cache, accountId, ref);
});

final monthlyCollectionDataProvider = StateNotifierProvider<MonthlyStatsNotifier,
    AsyncValue<List<MonthlyStat>>>((ref) {
  final repo = ref.watch(dashboardAnalyticsRepositoryProvider);
  final cache = ref.watch(cacheServiceProvider);
  final accountId = ref.watch(_accountIdProvider);
  return MonthlyStatsNotifier(repo, cache, accountId);
});

final recentTransactionsProvider = StateNotifierProvider<
    RecentTransactionsNotifier, AsyncValue<List<RecentTransaction>>>((ref) {
  final repo = ref.watch(dashboardAnalyticsRepositoryProvider);
  final cache = ref.watch(cacheServiceProvider);
  final accountId = ref.watch(_accountIdProvider);
  return RecentTransactionsNotifier(repo, cache, accountId);
});

final classCollectionDataProvider = StateNotifierProvider<
    ClassStatsNotifier, AsyncValue<List<ClassStat>>>((ref) {
  final repo = ref.watch(dashboardAnalyticsRepositoryProvider);
  final cache = ref.watch(cacheServiceProvider);
  final accountId = ref.watch(_accountIdProvider);
  return ClassStatsNotifier(repo, cache, accountId);
});

/// Invalidates all dashboard data and triggers background refresh.
void invalidateDashboardAnalytics(WidgetRef ref) {
  ref.read(dashboardStatsProvider.notifier).fetch();
  ref.read(monthlyCollectionDataProvider.notifier).fetch();
  ref.read(recentTransactionsProvider.notifier).fetch();
  ref.read(classCollectionDataProvider.notifier).fetch();
}

// ── Analytics Repository ──────────────────────────────────────────────────────

class DashboardAnalyticsRepository {
  final PaymentRepository _paymentRepo;
  final StudentRepository _studentRepo;
  final FeeRepository _feeRepo;
  final SupabaseClient _client;
  static const _excludedDueStatuses = {'cancelled', 'deleted'};
  static const _timeout = Duration(seconds: 10);

  DashboardAnalyticsRepository(
    this._paymentRepo,
    this._studentRepo,
    this._feeRepo,
    this._client,
  );

  Future<String?> _getAccountId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final userResponse = await _client
        .from('users')
        .select('account_id')
        .eq('id', userId)
        .maybeSingle()
        .timeout(_timeout);
    return userResponse?['account_id'] as String?;
  }

  Future<DashboardStats> getDashboardStats() =>
      getDashboardStatsForCycle(TimeCycle.monthly);

  Future<DashboardStats> getDashboardStatsForCycle(TimeCycle cycle) async {
    try {
      final now = DateTime.now();
      final cycleRange = _rangeForCycle(now, cycle);
      final previousCycleRange = _previousRangeForCycle(cycleRange, cycle);

      final results = await Future.wait<dynamic>([
        _studentRepo.getStudents().timeout(_timeout),
        _studentRepo.getStudentBalances().timeout(_timeout),
        _paymentRepo.getTotalCollection(
          startDate: cycleRange.start,
          endDate: cycleRange.endInclusive,
        ).timeout(_timeout),
        _paymentRepo.getTotalCollection(
          startDate: previousCycleRange.start,
          endDate: previousCycleRange.endInclusive,
        ).timeout(_timeout),
        _paymentRepo.getTotalCollection().timeout(_timeout),
        _feeRepo.getDues().timeout(_timeout),
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
      final totalCollectedInPreviousPeriod =
          _extractTotal(previousPeriodCollection);
      final totalCollectedAllTime = _extractTotal(allTimeCollection);

      final totalDue = dues.fold<double>(0, (sum, due) {
        final status = due.status.toString().toLowerCase();
        if (_excludedDueStatuses.contains(status)) return sum;
        return sum + (due.amountAssigned as double);
      });

      final collectionRate =
          totalDue > 0 ? (totalCollectedAllTime / totalDue) * 100 : 0.0;
      final growth = _calculateGrowth(
        currentAmount: totalCollectedInPeriod,
        previousAmount: totalCollectedInPreviousPeriod,
      );

      debugPrint(
        '[DashboardAnalytics] cycle=$cycle '
        'totalDue=$totalDue '
        'totalCollectedAllTime=$totalCollectedAllTime '
        'currentCycleCollections=$totalCollectedInPeriod '
        'collectionRate=$collectionRate',
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
      debugPrint('[DashboardAnalytics][OFFLINE] getDashboardStatsForCycle: $e');
      rethrow;
    }
  }

  Future<List<MonthlyStat>> getMonthlyCollectionData() async {
    try {
      final now = DateTime.now();
      final List<MonthlyStat> monthlyData = [];

      for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthRange = _monthRange(date);

        final collection = await _paymentRepo.getTotalCollection(
          startDate: monthRange.start,
          endDate: monthRange.endInclusive,
        ).timeout(_timeout);

        final amount = (collection['total'] as num?)?.toDouble() ?? 0;
        final monthName = DateFormat('MMM').format(date);
        monthlyData.add(MonthlyStat(month: monthName, amount: amount));
      }

      return monthlyData;
    } catch (e) {
      debugPrint('[DashboardAnalytics][OFFLINE] getMonthlyCollectionData: $e');
      rethrow;
    }
  }

  Future<List<CategoryStat>> getCategoryCollectionData() async {
    try {
      final accountId = await _getAccountId();
      if (accountId == null) return [];

      final response = await _client.rpc(
        'get_category_collection_distribution',
        params: {'p_account_id': accountId},
      ).timeout(_timeout);

      if (response is List) {
        return response.map((json) {
          final map = json as Map<String, dynamic>;
          return CategoryStat(
            name: map['category_name'] as String? ?? 'Unknown',
            amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
            percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[DashboardAnalytics][OFFLINE] getCategoryCollectionData: $e');
      rethrow;
    }
  }

  Future<List<ClassStat>> getClassCollectionData() async {
    try {
      final students = await _studentRepo.getStudents().timeout(_timeout);
      final payments = await _paymentRepo.getPayments().timeout(_timeout);
      final completedPayments =
          payments.where((p) => p.status.name == 'completed').toList();
      final balances = await _studentRepo.getStudentBalances().timeout(_timeout);

      final classMap = <String, Map<String, double>>{};

      for (var student in students) {
        if (!classMap.containsKey(student.studentClass)) {
          classMap[student.studentClass] = {'collected': 0.0, 'pending': 0.0};
        }
      }

      for (var payment in completedPayments) {
        if (payment.student != null) {
          final className = payment.student!.studentClass;
          if (classMap.containsKey(className)) {
            classMap[className]!['collected'] =
                (classMap[className]!['collected'] as double) + payment.amount;
          }
        }
      }

      for (var balance in balances) {
        if (classMap.containsKey(balance.studentClass)) {
          classMap[balance.studentClass]!['pending'] =
              (classMap[balance.studentClass]!['pending'] as double) +
                  balance.dueAmount;
        }
      }

      return classMap.entries
          .map((entry) => ClassStat(
                className: entry.key,
                collected: entry.value['collected'] as double,
                pending: entry.value['pending'] as double,
              ))
          .toList();
    } catch (e) {
      debugPrint('[DashboardAnalytics][OFFLINE] getClassCollectionData: $e');
      rethrow;
    }
  }

  Future<List<RecentTransaction>> getRecentTransactions(
      {int limit = 5}) async {
    try {
      final payments = await _paymentRepo
          .getRecentPayments(limit: limit)
          .timeout(_timeout);

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
      debugPrint('[DashboardAnalytics][OFFLINE] getRecentTransactions: $e');
      rethrow;
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _CycleRange {
  final DateTime start;
  final DateTime endInclusive;
  const _CycleRange({required this.start, required this.endInclusive});
}

class _GrowthResult {
  final double percentage;
  final bool isNewGrowth;
  const _GrowthResult({required this.percentage, required this.isNewGrowth});
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
      return _monthRange(DateTime(
          currentRange.start.year, currentRange.start.month - 1, 1));
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
    return const _GrowthResult(percentage: 0, isNewGrowth: true);
  }
  return const _GrowthResult(percentage: 0, isNewGrowth: false);
}
