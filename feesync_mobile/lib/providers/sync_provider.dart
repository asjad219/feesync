import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/cache_service.dart';

// Provides the SharedPreferences instance (overridden in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

// Provides the CacheService
final cacheServiceProvider = Provider<CacheService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CacheService(prefs);
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
