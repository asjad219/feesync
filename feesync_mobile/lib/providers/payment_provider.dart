import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../repositories/payment_repository.dart';
import '../core/services/cache_service.dart';
import 'supabase_provider.dart';
import 'sync_provider.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/sync_task.dart';
import '../core/errors/app_exception.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PaymentRepository(client);
});

// ── Filter state ──────────────────────────────────────────────────────────────

final paymentSearchProvider = StateProvider<String>((ref) => '');
final paymentStatusFilterProvider = StateProvider<PaymentStatus?>((ref) => null);
final paymentMethodFilterProvider = StateProvider<PaymentMethod?>((ref) => null);

// ── Account id helper ─────────────────────────────────────────────────────────

final _paymentAccountIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.id;
});

// ── PaymentNotifier ───────────────────────────────────────────────────────────

class PaymentNotifier extends StateNotifier<AsyncValue<List<Payment>>> {
  final PaymentRepository _repository;
  final CacheService _cache;
  final String? _accountId;
  final Ref _ref;

  PaymentNotifier(this._repository, this._cache, this._accountId, this._ref)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    if (_accountId == null) return;
    // 1. Emit cached data immediately
    final cached = await _cache.loadPayments(_accountId);
    if (cached != null) {
      state = AsyncValue.data(cached);
      debugPrint('[Payments] Loaded ${cached.length} payments from cache');
    }
    await loadPayments();
  }

  Future<void> loadPayments() async {
    if (_accountId == null) return;
    try {
      final payments = await _repository
          .getPayments()
          .timeout(const Duration(seconds: 10));
      await _cache.savePayments(_accountId, payments);
      _ref.read(lastSyncTimesProvider.notifier).update(
            (s) => {...s, 'payments': DateTime.now()},
          );
      state = AsyncValue.data(payments);
      debugPrint('[Payments] Fetched ${payments.length} payments from network');
    } catch (e, st) {
      debugPrint('[Payments][OFFLINE] loadPayments failed: $e');
      if (state is AsyncData) {
        _ref.read(offlineToastProvider.notifier).state = "You're offline. Showing saved data.";
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  bool _isOfflineException(dynamic e) {
    return e is NetworkException;
  }

  Future<void> createPayment(
    Map<String, dynamic> data,
    List<Map<String, dynamic>> feeAllocations,
  ) async {
    try {
      await _repository.createPayment(data, feeAllocations);
      await loadPayments();
    } catch (e) {
      if (_isOfflineException(e)) {
        final tempId = const Uuid().v4();
        data['id'] = tempId;
        final task = SyncTask(
          id: tempId,
          type: 'create_payment',
          payload: {'paymentData': data, 'feeAllocations': feeAllocations, 'tempId': tempId},
          createdAt: DateTime.now(),
        );
        await _ref.read(syncQueueServiceProvider).enqueueTask(task);
        
        // Optimistic update
        final current = state.valueOrNull ?? [];
        final newPayment = Payment.fromJson({
          ...data,
          'status': 'completed',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'is_offline': true,
        });
        
        state = AsyncValue.data([newPayment, ...current]);
        if (_accountId != null) {
          await _cache.savePayments(_accountId, state.value!);
        }
      } else {
        rethrow;
      }
    }
  }

  Future<void> updatePayment(String id, Map<String, dynamic> data) async {
    await _repository.updatePayment(id, data);
    await loadPayments();
  }

  Future<void> deletePayment(String id) async {
    await _repository.deletePayment(id);
    await loadPayments();
  }
}

final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, AsyncValue<List<Payment>>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  final cache = ref.watch(cacheServiceProvider);
  final accountId = ref.watch(_paymentAccountIdProvider);
  return PaymentNotifier(repository, cache, accountId, ref);
});

// ── Filtered payments ─────────────────────────────────────────────────────────

final filteredPaymentsProvider = Provider<AsyncValue<List<Payment>>>((ref) {
  final paymentsAsync = ref.watch(paymentNotifierProvider);
  final search = ref.watch(paymentSearchProvider).toLowerCase();
  final statusFilter = ref.watch(paymentStatusFilterProvider);
  final methodFilter = ref.watch(paymentMethodFilterProvider);

  return paymentsAsync.whenData((payments) {
    return payments.where((payment) {
      final matchesSearch = search.isEmpty ||
          (payment.student?.fullName.toLowerCase().contains(search) ?? false) ||
          (payment.receiptNumber?.toLowerCase().contains(search) ?? false) ||
          (payment.transactionId?.toLowerCase().contains(search) ?? false);

      final matchesStatus =
          statusFilter == null || payment.status == statusFilter;
      final matchesMethod =
          methodFilter == null || payment.paymentMethod == methodFilter;

      return matchesSearch && matchesStatus && matchesMethod;
    }).toList();
  });
});

// ── Quick stat providers (cached-fallback aware) ──────────────────────────────

final recentPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  try {
    return await repository
        .getRecentPayments(limit: 10)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Payments][OFFLINE] getRecentPayments failed: $e');
    // Fall back to cached payments sorted by date
    final cached = ref.read(paymentNotifierProvider).valueOrNull ?? [];
    return cached.take(10).toList();
  }
});

final totalCollectionProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  try {
    return await repository
        .getTotalCollection()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Payments][OFFLINE] getTotalCollection failed: $e');
    return {'total': 0.0, 'count': 0};
  }
});

final todayCollectionProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
  try {
    return await repository
        .getTotalCollection(startDate: startOfDay, endDate: endOfDay)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Payments][OFFLINE] getTodayCollection failed: $e');
    return {'total': 0.0, 'count': 0};
  }
});

final monthCollectionProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final nextMonth = now.month == 12
      ? DateTime(now.year + 1, 1, 1)
      : DateTime(now.year, now.month + 1, 1);
  final endOfMonth = nextMonth.subtract(const Duration(seconds: 1));
  try {
    return await repository
        .getTotalCollection(startDate: startOfMonth, endDate: endOfMonth)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Payments][OFFLINE] getMonthCollection failed: $e');
    return {'total': 0.0, 'count': 0};
  }
});

final allPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  try {
    return await repository
        .getPayments()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Payments][OFFLINE] getAllPayments failed: $e');
    return ref.read(paymentNotifierProvider).valueOrNull ?? [];
  }
});
