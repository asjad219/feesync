import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  final SupabaseClient _client;

  SettingsRepository(this._client);

  Future<String> _getAccountId() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final userData = await _client
        .from('users')
        .select('account_id')
        .eq('id', user.id)
        .single();

    return userData['account_id'] as String;
  }

  Future<AppSettings?> getSettings() async {
    try {
      final accountId = await _getAccountId();
      final response = await _client
          .from('app_settings')
          .select()
          .eq('account_id', accountId)
          .single();
      return AppSettings.fromJson(response);
    } catch (e) {
      // If no settings exist yet, create default ones
      return _initializeDefaultSettings();
    }
  }

  Future<AppSettings> _initializeDefaultSettings() async {
    final accountId = await _getAccountId();

    final response = await _client.from('app_settings').insert({
      'account_id': accountId,
      'center_name': 'FeeSync Academy',
    }).select().single();

    return AppSettings.fromJson(response);
  }

  Future<AppSettings> updateSettings(Map<String, dynamic> data) async {
    final accountId = await _getAccountId();
    final response = await _client
        .from('app_settings')
        .update(data)
        .eq('account_id', accountId)
        .select()
        .single();
    return AppSettings.fromJson(response);
  }
}
