import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';
import 'supabase_provider.dart';
import 'user_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SettingsRepository(client);
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  final notifier = SettingsNotifier(repository);

  ref.listen(currentUserProfileProvider, (previous, next) {
    debugPrint('[DEBUG] settingsProvider: currentUserProfileProvider state changed. value: ${next.value?.id}');
    // When the user profile transitions from null to loaded, load settings
    final nextProfile = next.value;
    final prevProfile = previous?.value;
    if (nextProfile != null) {
      if (prevProfile == null || nextProfile.accountId != prevProfile.accountId) {
        debugPrint('[DEBUG] settingsProvider: Loading settings for account: ${nextProfile.accountId}');
        notifier.loadSettings();
      }
    } else if (next.hasValue && nextProfile == null) {
      // User is logged out
      debugPrint('[DEBUG] settingsProvider: Profile is null (logged out), clearing settings');
      notifier.clearSettings();
    }
  });

  return notifier;
});

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    debugPrint('[DEBUG] SettingsNotifier: loadSettings started');
    state = const AsyncValue.loading();
    try {
      final settings = await _repository.getSettings();
      debugPrint('[DEBUG] SettingsNotifier: fetched settings from repository: $settings');
      if (settings != null) {
        state = AsyncValue.data(settings);
        debugPrint('[DEBUG] SettingsNotifier: State updated to AsyncValue.data');
      } else {
        // Not authenticated yet — stay in loading state silently
        state = const AsyncValue.loading();
        debugPrint('[DEBUG] SettingsNotifier: No settings found, remaining in loading state');
      }
    } catch (e, st) {
      debugPrint('[DEBUG] SettingsNotifier: error loading settings: $e');
      state = AsyncValue.error(e, st);
    }
  }

  void clearSettings() {
    state = const AsyncValue.loading();
  }

  Future<void> updateSetting(String key, dynamic value) async {
    if (state.value == null) return;
    
    try {
      final updated = await _repository.updateSettings({key: value});
      state = AsyncValue.data(updated);
    } catch (e, st) {
      // Revert or handle error
      state = AsyncValue.error(e, st);
      await loadSettings(); // Reload to be safe
    }
  }

  Future<void> updateMultipleSettings(Map<String, dynamic> data) async {
    try {
      final updated = await _repository.updateSettings(data);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      await loadSettings();
    }
  }
}
