import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_profile.dart';

class AccountRepository {
  final SupabaseClient _client;

  AccountRepository(this._client);

  Future<AccountProfile> getAccountProfile(String accountId) async {
    final response = await _client
        .from('accounts')
        .select()
        .eq('id', accountId)
        .single();

    return AccountProfile.fromJson(response);
  }

  Future<AccountProfile> updateAccountProfile(
    String accountId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .from('accounts')
        .update(data)
        .eq('id', accountId)
        .select()
        .single();

    return AccountProfile.fromJson(response);
  }

  Future<String> bootstrapOwner({
    required String centerName,
    required String contactEmail,
    required String ownerFullName,
    required String contactPhone,
    required String centerAddress,
    String? centerGstin,
    String? centerLogoUrl,
  }) async {
    final response = await _client.rpc('bootstrap_owner', params: {
      'center_name': centerName,
      'contact_email': contactEmail,
      'owner_full_name': ownerFullName,
      'contact_phone': contactPhone,
      'center_address': centerAddress,
      'center_gstin': centerGstin,
      'center_logo_url': centerLogoUrl,
    });

    return response.toString();
  }

  Future<void> requestAccountDeletion(
    String accountId,
    String userId,
    String? reason,
  ) async {
    await _client.from('account_deletion_requests').insert({
      'account_id': accountId,
      'user_id': userId,
      'reason': reason,
    });
  }
}
