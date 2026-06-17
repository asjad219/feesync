import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/network_service.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/settings_provider.dart';

/// Listens to connectivity changes and triggers background data refresh
/// when the device comes back online.
class SyncService {
  final Ref _ref;
  StreamSubscription<bool>? _subscription;

  SyncService(this._ref) {
    _startListening();
  }

  void _startListening() {
    final networkService = _ref.read(networkServiceProvider);

    _subscription = networkService.connectivityStream.listen((isOnline) {
      if (isOnline) {
        debugPrint('[SyncService] Network restored — triggering background sync');
        _syncAll();
      } else {
        debugPrint('[SyncService] Network lost');
      }
    });
  }

  Future<void> _syncAll() async {
    try {
      // Trigger all data providers to refresh in background
      await Future.wait([
        _ref.read(dashboardStatsProvider.notifier).fetch(),
        _ref.read(monthlyCollectionDataProvider.notifier).fetch(),
        _ref.read(recentTransactionsProvider.notifier).fetch(),
        _ref.read(studentBalancesProvider.notifier).loadStudents(),
        _ref.read(batchNotifierProvider.notifier).loadBatches(),
        _ref.read(paymentNotifierProvider.notifier).loadPayments(),
        _ref.read(settingsProvider.notifier).loadSettings(),
      ]);
      debugPrint('[SyncService] Background sync completed');
    } catch (e) {
      debugPrint('[SyncService] Background sync error: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    debugPrint('[SyncService] Disposed');
  }
}

/// Auto-initialized at app startup. Disposes itself when provider is destroyed.
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(ref);
  ref.onDispose(service.dispose);
  return service;
});
