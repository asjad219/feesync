import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/services/cache_service.dart';
import '../core/services/sync_queue_service.dart';
import 'payment_provider.dart';
import 'student_provider.dart';
import 'batch_provider.dart';
import 'dashboard_provider.dart';

// Provides the SharedPreferences instance (overridden in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

// Provides the CacheService
final cacheServiceProvider = Provider<CacheService>((ref) {
  throw UnimplementedError('cacheServiceProvider must be overridden in main.dart');
});

// Tracks the last successful sync time for various entities
final lastSyncTimesProvider = StateProvider<Map<String, DateTime?>>((ref) {
  return {
    'dashboard': null,
    'students': null,
    'batches': null,
    'payments': null,
    'settings': null,
  };
});

// Toast notifications for offline warning
final offlineToastProvider = StateProvider<String?>((ref) => null);

// Provides the SyncQueueService
final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SyncQueueService(prefs);
});

// A notifier to manage background syncing of offline queue
class SyncQueueNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final SyncQueueService _queueService;

  SyncQueueNotifier(this._ref, this._queueService) : super(false) {
    _init();
  }

  void _init() {
    Connectivity().onConnectivityChanged.listen((result) {
      final connectivityResult = result.firstOrNull ?? ConnectivityResult.none;
      if (connectivityResult != ConnectivityResult.none) {
        syncPendingTasks();
      }
    });
    // Attempt sync on startup
    syncPendingTasks();
  }

  Future<void> syncPendingTasks() async {
    if (state) return; // Already syncing
    
    final tasks = _queueService.getPendingTasks();
    if (tasks.isEmpty) return;

    state = true;
    for (final task in tasks) {
      if (task.retryCount > 3) continue; // Skip after 3 retries (could add logic to clear later)

      try {
        if (task.type == 'create_payment') {
          final paymentRepo = _ref.read(paymentRepositoryProvider);
          await paymentRepo.createPaymentOnline(
            task.payload['paymentData'],
            List<Map<String, dynamic>>.from(task.payload['feeAllocations']),
            task.payload['tempId'],
          );
        }
        await _queueService.removeTask(task.id);
      } catch (e) {
        debugPrint('[SyncQueueNotifier] Failed to sync task ${task.id}: $e');
        await _queueService.incrementRetry(task.id);
      }
    }
    
    // Refresh UI data
    _ref.invalidate(studentBalancesProvider);
    _ref.invalidate(batchNotifierProvider);
    _ref.read(dashboardStatsProvider.notifier).fetch();
    _ref.read(monthlyCollectionDataProvider.notifier).fetch();
    _ref.read(recentTransactionsProvider.notifier).fetch();
    _ref.read(classCollectionDataProvider.notifier).fetch();
    
    state = false;
  }
}

final syncQueueNotifierProvider = StateNotifierProvider<SyncQueueNotifier, bool>((ref) {
  final queueService = ref.watch(syncQueueServiceProvider);
  return SyncQueueNotifier(ref, queueService);
});
