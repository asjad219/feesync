import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';
import '../core/services/cache_service.dart';
import 'supabase_provider.dart';
import 'sync_provider.dart';
import 'user_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SettingsRepository(client);
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  final cache = ref.watch(cacheServiceProvider);
  final notifier = SettingsNotifier(repository, cache);

  ref.listen(currentUserProfileProvider, (previous, next) {
    debugPrint(
        '[Settings] currentUserProfileProvider changed. value: ${next.value?.id}');
    final nextProfile = next.value;
    final prevProfile = previous?.value;
    if (nextProfile != null) {
      if (prevProfile == null ||
          nextProfile.accountId != prevProfile.accountId) {
        debugPrint(
            '[Settings] Loading settings for account: ${nextProfile.accountId}');
        notifier.loadSettings(accountId: nextProfile.accountId);
      }
    } else if (next.hasValue && nextProfile == null) {
      debugPrint('[Settings] Logged out — clearing settings');
      notifier.clearSettings();
    } else if (next.hasError) {
      debugPrint('[Settings] Profile load error — using defaults');
      notifier.useDefaults();
    }
  });

  return notifier;
});

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsRepository _repository;
  final CacheService _cache;

  SettingsNotifier(this._repository, this._cache)
      : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings({String? accountId}) async {
    debugPrint('[Settings] loadSettings started (accountId=$accountId)');

    // 1. Emit cached settings immediately (if available)
    if (accountId != null) {
      try {
        final cached = await _cache.loadSettings(accountId);
        if (cached != null) {
          state = AsyncValue.data(cached);
          debugPrint('[Settings] Loaded from cache for account $accountId');
        }
      } catch (e) {
        debugPrint('[Settings] Failed to load from cache: $e');
      }
    }

    // 2. Attempt network fetch with timeout
    try {
      final settings = await _repository.getSettings().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[Settings] getSettings timed out — keeping cached');
          return null;
        },
      );

      if (settings != null) {
        // Save to cache for next offline session
        if (accountId != null) {
          await _cache.saveSettings(accountId, settings);
        }
        state = AsyncValue.data(settings);
        debugPrint('[Settings] Fetched fresh settings from network');
      } else if (state is! AsyncData) {
        // Timeout and no cache — use defaults
        state = AsyncValue.data(AppSettings.defaults());
        debugPrint('[Settings] No data available — using defaults');
      }
    } catch (e) {
      debugPrint('[Settings][OFFLINE] loadSettings failed: $e');
      // If we already have cached/default data, do not overwrite with error
      if (state is! AsyncData) {
        state = AsyncValue.data(AppSettings.defaults());
      }
    }
  }

  void clearSettings() {
    state = const AsyncValue.loading();
  }

  void useDefaults() {
    state = AsyncValue.data(AppSettings.defaults());
  }

  Future<void> updateSetting(String key, dynamic value) async {
    if (state.value == null) return;
    try {
      final updated = await _repository.updateSettings({key: value});
      // Save updated settings to cache
      final accountId = state.value?.accountId;
      if (accountId != null && accountId != 'offline-default') {
        await _cache.saveSettings(accountId, updated);
      }
      state = AsyncValue.data(updated);
    } catch (e, st) {
      debugPrint('[Settings][OFFLINE] updateSetting failed: $e');
      state = AsyncValue.error(e, st);
      await loadSettings();
    }
  }

  Future<void> updateMultipleSettings(Map<String, dynamic> data) async {
    try {
      final updated = await _repository.updateSettings(data);
      final accountId = state.value?.accountId;
      if (accountId != null && accountId != 'offline-default') {
        await _cache.saveSettings(accountId, updated);
      }
      state = AsyncValue.data(updated);
    } catch (e, st) {
      debugPrint('[Settings][OFFLINE] updateMultipleSettings failed: $e');
      state = AsyncValue.error(e, st);
      await loadSettings();
    }
  }
}
