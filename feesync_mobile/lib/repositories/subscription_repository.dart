import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';

class SubscriptionRepository {
  final SupabaseClient _client;

  SubscriptionRepository(this._client);

  String? get _ownerId => _client.auth.currentUser?.id;

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetches the subscription record for the current owner.
  /// Returns a default Free plan if no record exists or on any error.
  Future<Subscription> getSubscription() async {
    final uid = _ownerId;
    if (uid == null) return Subscription.defaultFree('');

    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (response == null) {
        // New user: create a free subscription record.
        return _createDefaultSubscription(uid);
      }
      return Subscription.fromJson(response);
    } catch (e) {
      debugPrint('[SubscriptionRepo] getSubscription error: $e');
      // If table doesn't exist yet or any error, return free tier gracefully.
      return Subscription.defaultFree(uid);
    }
  }

  /// Creates a default Free subscription row in the DB for a new user.
  Future<Subscription> _createDefaultSubscription(String uid) async {
    try {
      final defaultSub = Subscription.defaultFree(uid);
      final response = await _client
          .from('subscriptions')
          .insert({
            'user_id':                   uid,
            'plan_type':                 'free',
            'billing_cycle':             'monthly',
            'max_students':              defaultSub.maxStudents,
            'max_batches':               defaultSub.maxBatches,
            'whatsapp_receipts_limit':   defaultSub.whatsappReceiptsLimit,
            'whatsapp_reminders_limit':  defaultSub.whatsappRemindersLimit,
            'sms_limit':                 defaultSub.smsLimit,
            'max_staff':                 defaultSub.maxStaff,
            'status':                    defaultSub.status,
            'start_date':                defaultSub.startDate.toIso8601String(),
          })
          .select()
          .single();
      return Subscription.fromJson(response);
    } catch (e) {
      debugPrint('[SubscriptionRepo] createDefaultSubscription error: $e');
      return Subscription.defaultFree(uid);
    }
  }

  // ── Usage counts ──────────────────────────────────────────────────────────

  /// Returns the active staff count for the current owner.
  Future<int> getActiveStaffCount() async {
    final uid = _ownerId;
    if (uid == null) return 0;

    try {
      // RLS enforces account-level isolation via get_account_id().
      // Do NOT add .eq('account_id', uid) — uid is auth UID, not account UUID.
      final response = await _client
          .from('users')
          .select('id')
          .eq('is_active', true)
          .neq('role', 'admin');
      return (response as List).length;
    } catch (e) {
      debugPrint('[SubscriptionRepo] getActiveStaffCount error: $e');
      return 0;
    }
  }

  /// Returns the active student count for the current owner.
  Future<int> getActiveStudentCount() async {
    final uid = _ownerId;
    if (uid == null) return 0;

    try {
      // RLS enforces account-level isolation via get_account_id().
      // Do NOT add .eq('account_id', uid) — the uid is the auth UID
      // and account_id is a separate account UUID; the explicit filter
      // would return 0 rows.
      final response = await _client
          .from('students')
          .select('id');
      return (response as List).length;
    } catch (e) {
      debugPrint('[SubscriptionRepo] getActiveStudentCount error: $e');
      return 0;
    }
  }

  /// Returns the active batch count for the current owner.
  Future<int> getActiveBatchCount() async {
    final uid = _ownerId;
    if (uid == null) return 0;

    try {
      // RLS enforces account-level isolation; no explicit account_id filter needed.
      final response = await _client
          .from('batches')
          .select('id')
          .eq('status', 'active');
      return (response as List).length;
    } catch (e) {
      debugPrint('[SubscriptionRepo] getActiveBatchCount error: $e');
      return 0;
    }
  }

  // ── Write ──────────────────────────────────────────────────────────────────
  // Write methods (upsertSubscription, upsertViaRpc) have been removed.
  // Subscription updates are now handled by RevenueCat webhooks securely.
}
