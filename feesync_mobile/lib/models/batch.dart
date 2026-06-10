import 'package:flutter/material.dart';
import 'schedule.dart';

enum BatchStatus {
  active,
  upcoming,
  completed,
}

class Batch {
  final String id;
  final String accountId;
  final String name;
  final String subject;
  final String teacherName;
  final BatchStatus status;
  final int studentCount;
  final int maxCapacity;
  final double monthlyFee;
  final String? colorHex;
  final String? iconKey;
  final DateTime createdAt;
  final DateTime? nextClassTime;
  final double attendancePercentage;
  final double revenueGenerated;
  final double pendingDues;
  
  // Schedule Fields
  final List<ScheduleSlot> schedules;
  final List<int> scheduleDays;
  final String startTime;
  final String endTime;
  final String room;

  // Settings Fields
  final bool autoRollNumber;
  final bool collectParentDetails;

  Batch({
    required this.id,
    required this.accountId,
    required this.name,
    required this.subject,
    required this.teacherName,
    this.status = BatchStatus.active,
    this.studentCount = 0,
    required this.maxCapacity,
    required this.monthlyFee,
    this.colorHex,
    this.iconKey,
    required this.createdAt,
    this.nextClassTime,
    this.attendancePercentage = 0.0,
    this.revenueGenerated = 0.0,
    this.pendingDues = 0.0,
    this.schedules = const [],
    this.scheduleDays = const [],
    this.startTime = '16:00',
    this.endTime = '17:30',
    this.room = 'Room 101',
    this.autoRollNumber = false,
    this.collectParentDetails = true,
  });

  double get capacityPercentage => (studentCount / maxCapacity).clamp(0.0, 1.0);
  
  Color get color => colorHex != null 
      ? Color(int.parse(colorHex!.replaceFirst('#', '0xFF'))) 
      : Colors.blue;

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'],
      accountId: json['account_id'],
      name: json['name'],
      subject: json['subject'],
      teacherName: json['teacher_name'],
      status: BatchStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => BatchStatus.active,
      ),
      studentCount: json['student_count'] ?? 0,
      maxCapacity: json['max_capacity'],
      monthlyFee: (json['monthly_fee'] as num).toDouble(),
      colorHex: json['color_hex'],
      iconKey: json['icon_key'],
      createdAt: DateTime.parse(json['created_at']),
      nextClassTime: json['next_class_time'] != null 
          ? DateTime.parse(json['next_class_time']) 
          : null,
      attendancePercentage: (json['attendance_percentage'] as num? ?? 0.0).toDouble(),
      revenueGenerated: (json['revenue_generated'] as num? ?? 0.0).toDouble(),
      pendingDues: (json['pending_dues'] as num? ?? 0.0).toDouble(),
      schedules: json['schedules'] != null 
          ? (json['schedules'] as List).map((e) => ScheduleSlot.fromJson(e)).toList()
          : [],
      scheduleDays: json['schedule_days'] != null && json['schedule_days'].toString().isNotEmpty
          ? (json['schedule_days'] as String).split(',').map((e) => int.parse(e.trim())).toList()
          : [],
      startTime: json['start_time'] ?? '16:00',
      endTime: json['end_time'] ?? '17:30',
      room: json['room'] ?? 'Room 101',
      autoRollNumber: json['auto_roll_number'] ?? false,
      collectParentDetails: json['collect_parent_details'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'name': name,
      'subject': subject,
      'teacher_name': teacherName,
      'status': status.toString().split('.').last,
      'student_count': studentCount,
      'max_capacity': maxCapacity,
      'monthly_fee': monthlyFee,
      'color_hex': colorHex,
      'icon_key': iconKey,
      'created_at': createdAt.toIso8601String(),
      'next_class_time': nextClassTime?.toIso8601String(),
      'attendance_percentage': attendancePercentage,
      'revenue_generated': revenueGenerated,
      'pending_dues': pendingDues,
      'schedules': schedules.map((e) => e.toJson()).toList(),
      'schedule_days': scheduleDays.join(','),
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
      'auto_roll_number': autoRollNumber,
      'collect_parent_details': collectParentDetails,
    };
  }

  Batch copyWith({
    String? id,
    String? accountId,
    String? name,
    String? subject,
    String? teacherName,
    BatchStatus? status,
    int? studentCount,
    int? maxCapacity,
    double? monthlyFee,
    String? colorHex,
    String? iconKey,
    DateTime? createdAt,
    DateTime? nextClassTime,
    double? attendancePercentage,
    double? revenueGenerated,
    double? pendingDues,
    List<ScheduleSlot>? schedules,
    List<int>? scheduleDays,
    String? startTime,
    String? endTime,
    String? room,
    bool? autoRollNumber,
    bool? collectParentDetails,
  }) {
    return Batch(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      teacherName: teacherName ?? this.teacherName,
      status: status ?? this.status,
      studentCount: studentCount ?? this.studentCount,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      colorHex: colorHex ?? this.colorHex,
      iconKey: iconKey ?? this.iconKey,
      createdAt: createdAt ?? this.createdAt,
      nextClassTime: nextClassTime ?? this.nextClassTime,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      revenueGenerated: revenueGenerated ?? this.revenueGenerated,
      pendingDues: pendingDues ?? this.pendingDues,
      schedules: schedules ?? this.schedules,
      scheduleDays: scheduleDays ?? this.scheduleDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      autoRollNumber: autoRollNumber ?? this.autoRollNumber,
      collectParentDetails: collectParentDetails ?? this.collectParentDetails,
    );
  }
}
