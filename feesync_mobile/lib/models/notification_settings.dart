import 'notification.dart';

class NotificationSettings {
  final String id;
  final String accountId;
  final int autoReminderDays;
  final int reminderFrequency;
  final List<NotificationChannel> enabledChannels;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationSettings({
    required this.id,
    required this.accountId,
    required this.autoReminderDays,
    required this.reminderFrequency,
    required this.enabledChannels,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      id: json['id'],
      accountId: json['account_id'],
      autoReminderDays: json['auto_reminder_days'] ?? 7,
      reminderFrequency: json['reminder_frequency'] ?? 3,
      enabledChannels: (json['enabled_channels'] as List<dynamic>?)
              ?.map((e) => NotificationChannel.values.firstWhere(
                    (v) => v.name == e.toString(),
                    orElse: () => NotificationChannel.email,
                  ))
              .toList() ??
          [NotificationChannel.email],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'auto_reminder_days': autoReminderDays,
      'reminder_frequency': reminderFrequency,
      'enabled_channels': enabledChannels.map((e) => e.name).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
