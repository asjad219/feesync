import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class StaffRepository {
  final SupabaseClient _client;

  StaffRepository(this._client);

  Future<List<UserProfile>> getStaffMembers(String accountId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('account_id', accountId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => UserProfile.fromJson(json)).toList();
  }

  Future<void> inviteStaff({
    required String email,
    required String fullName,
    required String role,
    required Map<String, dynamic> permissions,
  }) async {
    final response = await _client.functions.invoke(
      'invite_staff',
      body: {
        'email': email,
        'fullName': fullName,
        'role': role,
        'permissions': permissions,
      },
    );
    
    if (response.status != 200) {
      throw Exception('Failed to invite staff: ${response.data}');
    }
  }

  Future<void> updateStaff(String userId, {
    String? role,
    Map<String, dynamic>? permissions,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (role != null) updates['role'] = role;
    if (permissions != null) updates['permissions'] = permissions;
    if (isActive != null) updates['is_active'] = isActive;

    await _client.from('users').update(updates).eq('id', userId);
  }

  Future<void> deleteStaff(String userId) async {
    final response = await _client.functions.invoke(
      'delete_staff',
      body: {'targetUserId': userId},
    );
    
    if (response.status != 200) {
      throw Exception('Failed to delete staff: ${response.data}');
    }
  }
}
