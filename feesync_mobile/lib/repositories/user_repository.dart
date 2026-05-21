import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserRepository {
  final SupabaseClient _client;

  UserRepository(this._client);

  Future<UserProfile?> getCurrentUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }
}
