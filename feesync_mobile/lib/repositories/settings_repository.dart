import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  final SupabaseClient _client;
  static const _timeout = Duration(seconds: 10);

  SettingsRepository(this._client);

  Future<String?> _getAccountId() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final userData = await _client
          .from('users')
          .select('account_id')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(_timeout);

      if (userData == null) return null;
      return userData['account_id'] as String;
    } catch (e) {
      debugPrint('[SettingsRepo][OFFLINE] _getAccountId failed: $e');
      return null;
    }
  }

  Future<AppSettings?> getSettings() async {
    final accountId = await _getAccountId();
    if (accountId == null) return null;

    try {
      final response = await _client
          .from('app_settings')
          .select()
          .eq('account_id', accountId)
          .single()
          .timeout(_timeout);
      return AppSettings.fromJson(response);
    } catch (e) {
      debugPrint('[SettingsRepo][OFFLINE] getSettings failed: $e');
      // If no settings row exists yet, try to create defaults
      try {
        return await _initializeDefaultSettings(accountId);
      } catch (initError) {
        debugPrint('[SettingsRepo][OFFLINE] initializeDefaultSettings failed: $initError');
        return null;
      }
    }
  }

  Future<AppSettings> _initializeDefaultSettings(String accountId) async {
    final response = await _client.from('app_settings').insert({
      'account_id': accountId,
      'center_name': 'FeeSync Academy',
    }).select().single().timeout(_timeout);

    return AppSettings.fromJson(response);
  }

  Future<AppSettings> updateSettings(Map<String, dynamic> data) async {
    final accountId = await _getAccountId();
    if (accountId == null) throw Exception('Not authenticated');

    try {
      final response = await _client
          .from('app_settings')
          .update(data)
          .eq('account_id', accountId)
          .select()
          .single()
          .timeout(_timeout);
      return AppSettings.fromJson(response);
    } catch (e) {
      debugPrint('[SettingsRepo] updateSettings failed: $e');
      rethrow;
    }
  }
}
