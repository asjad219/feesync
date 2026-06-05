import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';

class SubscriptionRepository {
  final SupabaseClient _client;

  SubscriptionRepository(this._client);

  /// Returns the owner_id (account_id) for the current user.
  String? get _ownerId => _client.auth.currentUser?.id;

  /// Fetches the subscription record for the current owner.
  /// Returns a default Free plan if no record exists.
  Future<Subscription> getSubscription() async {
    final uid = _ownerId;
    if (uid == null) return Subscription.defaultFree('');

    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('owner_id', uid)
          .maybeSingle();

      if (response == null) {
        return Subscription.defaultFree(uid);
      }
      return Subscription.fromJson(response);
    } catch (_) {
      // If table doesn't exist yet or any error, return free tier gracefully
      return Subscription.defaultFree(uid);
    }
  }

  /// Returns the active student count for the current owner.
  Future<int> getActiveStudentCount() async {
    final uid = _ownerId;
    if (uid == null) return 0;

    try {
      final response = await _client
          .from('students')
          .select('id')
          .eq('owner_id', uid)
          .eq('status', 'active');

      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Returns the active batch count for the current owner.
  Future<int> getActiveBatchCount() async {
    final uid = _ownerId;
    if (uid == null) return 0;

    try {
      final response = await _client
          .from('batches')
          .select('id')
          .eq('owner_id', uid)
          .eq('status', 'active');

      return (response as List).length;
    } catch (_) {
      // fallback: try with account_id field (some schemas use account_id)
      try {
        final response = await _client
            .from('batches')
            .select('id')
            .eq('account_id', uid);
        return (response as List).length;
      } catch (_) {
        return 0;
      }
    }
  }

  /// Upserts a subscription record (used by backend webhook — exposed here for
  /// manual testing / admin override in debug builds).
  Future<Subscription> upsertSubscription(Map<String, dynamic> data) async {
    final uid = _ownerId;
    if (uid == null) throw Exception('Not authenticated');

    final payload = {...data, 'owner_id': uid};
    final response = await _client
        .from('subscriptions')
        .upsert(payload, onConflict: 'owner_id')
        .select()
        .single();

    return Subscription.fromJson(response);
  }
}
