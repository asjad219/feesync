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
          .eq('owner_id', uid)
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
            'owner_id':                  uid,
            'plan_tier':                 'free',
            'billing_cycle':             'monthly',
            'max_students':              defaultSub.maxStudents,
            'max_batches':               defaultSub.maxBatches,
            'whatsapp_receipts_limit':   defaultSub.whatsappReceiptsLimit,
            'whatsapp_reminders_limit':  defaultSub.whatsappRemindersLimit,
            'sms_limit':                 defaultSub.smsLimit,
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
      final response = await _client
          .from('users')
          .select('id')
          .eq('account_id', uid)
          .eq('is_active', true);
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
      // Try account_id field first (matches schema).
      final response = await _client
          .from('students')
          .select('id')
          .eq('account_id', uid);
      return (response as List).length;
    } catch (_) {
      try {
        // Fallback to owner_id field.
        final response = await _client
            .from('students')
            .select('id')
            .eq('owner_id', uid);
        return (response as List).length;
      } catch (e) {
        debugPrint('[SubscriptionRepo] getActiveStudentCount error: $e');
        return 0;
      }
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
          .eq('account_id', uid)
          .eq('status', 'active');
      return (response as List).length;
    } catch (_) {
      try {
        final response = await _client
            .from('batches')
            .select('id')
            .eq('account_id', uid);
        return (response as List).length;
      } catch (e) {
        debugPrint('[SubscriptionRepo] getActiveBatchCount error: $e');
        return 0;
      }
    }
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Upserts a subscription record.
  /// Called by the billing service after purchase verification or by tests.
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

  /// Calls the `upsert_subscription` Postgres RPC directly.
  /// Used by [BillingService] after Google Play purchase verification.
  Future<Subscription> upsertViaRpc({
    required String planTier,
    required String billingCycle,
    required DateTime validUntil,
    String? googlePlayToken,
    String? googlePlayProductId,
    String? razorpaySubId,
    String? razorpayPaymentId,
  }) async {
    final uid = _ownerId;
    if (uid == null) throw Exception('Not authenticated');

    final result = await _client.rpc('upsert_subscription', params: {
      'p_owner_id'           : uid,
      'p_plan_tier'          : planTier,
      'p_billing_cycle'      : billingCycle,
      'p_valid_until'        : validUntil.toIso8601String(),
      'p_google_play_token'  : googlePlayToken,
      'p_google_play_product': googlePlayProductId,
      'p_razorpay_sub_id'    : razorpaySubId,
      'p_razorpay_payment_id': razorpayPaymentId,
    });

    return Subscription.fromJson(Map<String, dynamic>.from(result as Map));
  }
}
