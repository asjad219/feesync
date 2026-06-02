import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  final SupabaseClient _client;

  SettingsRepository(this._client);

  Future<String?> _getAccountId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null; // Not authenticated — return null instead of throwing

    final userData = await _client
        .from('users')
        .select('account_id')
        .eq('id', user.id)
        .maybeSingle(); // Use maybeSingle to avoid PGRST116 when no row exists

    if (userData == null) return null;
    return userData['account_id'] as String;
  }

  Future<AppSettings?> getSettings() async {
    final accountId = await _getAccountId();
    if (accountId == null) return null; // Not authenticated — return null gracefully

    try {
      final response = await _client
          .from('app_settings')
          .select()
          .eq('account_id', accountId)
          .single();
      return AppSettings.fromJson(response);
    } catch (e) {
      // If no settings exist yet, create default ones
      return _initializeDefaultSettings(accountId);
    }
  }

  Future<AppSettings> _initializeDefaultSettings(String accountId) async {
    final response = await _client.from('app_settings').insert({
      'account_id': accountId,
      'center_name': 'FeeSync Academy',
    }).select().single();

    return AppSettings.fromJson(response);
  }

  Future<AppSettings> updateSettings(Map<String, dynamic> data) async {
    final accountId = await _getAccountId();
    if (accountId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('app_settings')
        .update(data)
        .eq('account_id', accountId)
        .select()
        .single();
    return AppSettings.fromJson(response);
  }
}

