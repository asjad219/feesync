import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../models/notification_settings.dart';

class NotificationRepository {
  final SupabaseClient _client;

  NotificationRepository(this._client);

  Future<List<AppNotification>> getNotifications({
    String? studentId,
    String? status,
    String? type,
  }) async {
    var query = _client.from('notifications').select('*, students(first_name, last_name, class)');

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (type != null) {
      query = query.eq('type', type);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => AppNotification.fromJson(json)).toList();
  }

  Future<AppNotification> updateNotificationStatus(String id, String status) async {
    final response = await _client
        .from('notifications')
        .update({'status': status})
        .eq('id', id)
        .select('*, students(first_name, last_name, class)')
        .single();

    return AppNotification.fromJson(response);
  }

  Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  Future<NotificationSettings?> getNotificationSettings() async {
    try {
      final response = await _client
          .from('notification_settings')
          .select()
          .single();

      return NotificationSettings.fromJson(response);
    } catch (e) {
      // If no settings exist yet, it might throw
      return null;
    }
  }

  Future<NotificationSettings> updateNotificationSettings(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('notification_settings')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return NotificationSettings.fromJson(response);
  }
}
