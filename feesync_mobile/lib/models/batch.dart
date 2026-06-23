import 'dart:convert';
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

  // Billing & Rollover
  final String feeType;
  final bool useGlobalBilling;
  final int? customDueDay;
  final bool? customAutoDueGeneration;

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
    this.feeType = 'monthly',
    this.useGlobalBilling = true,
    this.customDueDay,
    this.customAutoDueGeneration,
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
      studentCount: int.tryParse(json['student_count']?.toString() ?? '0') ?? 0,
      maxCapacity: int.tryParse(json['max_capacity']?.toString() ?? '0') ?? 0,
      monthlyFee: double.parse((json['monthly_fee'] ?? 0).toString()),
      colorHex: json['color_hex'],
      iconKey: json['icon_key'],
      createdAt: DateTime.parse(json['created_at']),
      nextClassTime: json['next_class_time'] != null 
          ? DateTime.parse(json['next_class_time']) 
          : null,
      attendancePercentage: double.parse((json['attendance_percentage'] ?? 0).toString()),
      revenueGenerated: double.parse((json['revenue_generated'] ?? 0).toString()),
      pendingDues: double.parse((json['pending_dues'] ?? 0).toString()),
      schedules: () {
        final val = json['schedules'];
        if (val == null) return <ScheduleSlot>[];
        try {
          if (val is String) {
            final decoded = jsonDecode(val) as List;
            return decoded.map((e) => ScheduleSlot.fromJson(e)).toList();
          } else if (val is List) {
            return val.map((e) => ScheduleSlot.fromJson(e)).toList();
          }
        } catch (_) {}
        return <ScheduleSlot>[];
      }(),
      scheduleDays: json['schedule_days'] != null && json['schedule_days'].toString().isNotEmpty
          ? (json['schedule_days'] as String).split(',').map((e) => int.parse(e.trim())).toList()
          : [],
      startTime: json['start_time'] ?? '16:00',
      endTime: json['end_time'] ?? '17:30',
      room: json['room'] ?? 'Room 101',
      autoRollNumber: json['auto_roll_number'] ?? false,
      collectParentDetails: json['collect_parent_details'] ?? true,
      feeType: json['fee_type'] ?? 'monthly',
      useGlobalBilling: json['use_global_billing'] ?? true,
      customDueDay: json['custom_due_day'],
      customAutoDueGeneration: json['custom_auto_due_generation'],
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
      'fee_type': feeType,
      'use_global_billing': useGlobalBilling,
      if (customDueDay != null) 'custom_due_day': customDueDay,
      if (customAutoDueGeneration != null) 'custom_auto_due_generation': customAutoDueGeneration,
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
    String? feeType,
    bool? useGlobalBilling,
    int? customDueDay,
    bool? customAutoDueGeneration,
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
      feeType: feeType ?? this.feeType,
      useGlobalBilling: useGlobalBilling ?? this.useGlobalBilling,
      customDueDay: customDueDay ?? this.customDueDay,
      customAutoDueGeneration: customAutoDueGeneration ?? this.customAutoDueGeneration,
    );
  }
}
