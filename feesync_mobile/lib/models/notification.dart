enum NotificationType {
  paymentReminder,
  paymentConfirmation,
  welcome,
  feeUpdate,
}

enum NotificationChannel {
  email,
  sms,
  both,
}

enum NotificationStatus {
  pending,
  sent,
  failed,
}

class AppNotification {
  final String id;
  final String accountId;
  final String? studentId;
  final NotificationType type;
  final NotificationChannel channel;
  final String? subject;
  final String message;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final NotificationStatus status;
  final String? createdBy;
  final DateTime createdAt;

  // Joined data from students
  final String? studentFirstName;
  final String? studentLastName;
  final String? studentClass;

  AppNotification({
    required this.id,
    required this.accountId,
    this.studentId,
    required this.type,
    required this.channel,
    this.subject,
    required this.message,
    this.scheduledFor,
    this.sentAt,
    required this.status,
    this.createdBy,
    required this.createdAt,
    this.studentFirstName,
    this.studentLastName,
    this.studentClass,
  });

  String get studentFullName => 
    (studentFirstName != null && studentLastName != null) 
      ? '$studentFirstName $studentLastName' 
      : 'N/A';

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    NotificationType parseType(String? typeStr) {
      switch (typeStr) {
        case 'payment_reminder': return NotificationType.paymentReminder;
        case 'payment_confirmation': return NotificationType.paymentConfirmation;
        case 'welcome': return NotificationType.welcome;
        case 'fee_update': return NotificationType.feeUpdate;
        default: return NotificationType.feeUpdate;
      }
    }

    return AppNotification(
      id: json['id'],
      accountId: json['account_id'],
      studentId: json['student_id'],
      type: parseType(json['type']),
      channel: NotificationChannel.values.firstWhere(
        (e) => e.name == json['channel'],
        orElse: () => NotificationChannel.email,
      ),
      subject: json['subject'],
      message: json['message'],
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.parse(json['scheduled_for'])
          : null,
      sentAt: json['sent_at'] != null 
          ? DateTime.parse(json['sent_at']) 
          : null,
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NotificationStatus.pending,
      ),
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      // Data from join
      studentFirstName: json['students']?['first_name'],
      studentLastName: json['students']?['last_name'],
      studentClass: json['students']?['class'],
    );
  }

  Map<String, dynamic> toJson() {
    String typeToString(NotificationType t) {
      switch (t) {
        case NotificationType.paymentReminder: return 'payment_reminder';
        case NotificationType.paymentConfirmation: return 'payment_confirmation';
        case NotificationType.welcome: return 'welcome';
        case NotificationType.feeUpdate: return 'fee_update';
      }
    }

    return {
      'id': id,
      'account_id': accountId,
      'student_id': studentId,
      'type': typeToString(type),
      'channel': channel.name,
      'subject': subject,
      'message': message,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'status': status.name,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
