import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks monthly quota usage (WhatsApp receipts, reminders, SMS, AI calls)
/// via the `subscription_usage` table in Supabase.
class UsageRepository {
  final SupabaseClient _client;

  UsageRepository(this._client);

  String? get _ownerId => _client.auth.currentUser?.id;

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns the current month's usage for the logged-in owner.
  /// Returns zeros if no record exists (fresh month).
  Future<Map<String, int>> getCurrentMonthUsage() async {
    final uid = _ownerId;
    if (uid == null) return _emptyUsage();

    try {
      // Use the RPC for a clean interface.
      final result = await _client.rpc(
        'get_current_usage',
        params: {'p_owner_id': uid},
      );

      if (result == null) return _emptyUsage();

      final row = Map<String, dynamic>.from(result as Map);
      return {
        'whatsapp_receipts_used':  (row['whatsapp_receipts_used']  as int?) ?? 0,
        'whatsapp_reminders_used': (row['whatsapp_reminders_used'] as int?) ?? 0,
        'sms_used':                (row['sms_used']                as int?) ?? 0,
        'ai_calls_used':           (row['ai_calls_used']           as int?) ?? 0,
      };
    } catch (e) {
      debugPrint('[UsageRepo] getCurrentMonthUsage error: $e');
      return _emptyUsage();
    }
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Increments a usage counter for the current month.
  /// [column] must be one of:
  ///   'whatsapp_receipts_used' | 'whatsapp_reminders_used' |
  ///   'sms_used' | 'ai_calls_used'
  Future<void> increment(String column, {int by = 1}) async {
    final uid = _ownerId;
    if (uid == null) return;

    try {
      await _client.rpc('increment_usage', params: {
        'p_owner_id':  uid,
        'p_column':    column,
        'p_increment': by,
      });
    } catch (e) {
      debugPrint('[UsageRepo] increment($column) error: $e');
      // Non-fatal — tracking failure should not block the user action.
    }
  }

  /// Convenience: increments WhatsApp receipt counter.
  Future<void> recordWhatsappReceipt() => increment('whatsapp_receipts_used');

  /// Convenience: increments WhatsApp reminder counter.
  Future<void> recordWhatsappReminder() => increment('whatsapp_reminders_used');

  /// Convenience: increments SMS counter.
  Future<void> recordSms() => increment('sms_used');

  /// Convenience: increments AI call counter.
  Future<void> recordAiCall() => increment('ai_calls_used');

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, int> _emptyUsage() => {
        'whatsapp_receipts_used':  0,
        'whatsapp_reminders_used': 0,
        'sms_used':                0,
        'ai_calls_used':           0,
      };
}
