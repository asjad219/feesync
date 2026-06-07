import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/local_settings.dart';

final localSettingsProvider = StateNotifierProvider<LocalSettingsNotifier, LocalSettings>((ref) {
  return LocalSettingsNotifier();
});

class LocalSettingsNotifier extends StateNotifier<LocalSettings> {
  late final Future<void> initFuture;

  LocalSettingsNotifier() : super(LocalSettings.defaultSettings()) {
    initFuture = loadSettings();
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/local_settings.json');
  }

  Future<void> loadSettings() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        state = LocalSettings.fromJson(json);
      }
    } catch (e) {
      // Keep default settings in case of error
    }
  }

  Future<void> updateSettings(LocalSettings settings) async {
    state = settings;
    try {
      final file = await _localFile;
      await file.writeAsString(jsonEncode(state.toJson()));
    } catch (e) {
      // Handle error or ignore
    }
  }

  Future<void> updateBiometricEnabled(bool enabled) async {
    await updateSettings(state.copyWith(biometricEnabled: enabled));
  }

  Future<void> updatePinLockEnabled(bool enabled) async {
    await updateSettings(state.copyWith(pinLockEnabled: enabled));
  }

  Future<void> updateSessionAlertsEnabled(bool enabled) async {
    await updateSettings(state.copyWith(sessionAlertsEnabled: enabled));
  }

  Future<void> updateAiConfidenceThreshold(double threshold) async {
    await updateSettings(state.copyWith(aiConfidenceThreshold: threshold));
  }

  Future<void> updatePinHash(String? hash) async {
    await updateSettings(state.copyWith(pinHash: hash, clearPin: hash == null));
  }

  Future<void> updateLockOnMinimize(bool enabled) async {
    await updateSettings(state.copyWith(lockOnMinimize: enabled));
  }

  Future<void> resetAll() async {
    final defaults = LocalSettings.defaultSettings();
    await updateSettings(defaults);
  }
}
