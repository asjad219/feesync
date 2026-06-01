import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';
import 'supabase_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SettingsRepository(client);
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _repository.getSettings();
      if (settings != null) {
        state = AsyncValue.data(settings);
      } else {
        state = AsyncValue.error('Settings not found', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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
