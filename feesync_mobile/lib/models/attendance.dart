enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
}

class AttendanceRecord {
  final String id;
  final String batchId;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;
  final String? notes;

  AttendanceRecord({
    required this.id,
    required this.batchId,
    required this.studentId,
    required this.date,
    required this.status,
    this.notes,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      batchId: json['batch_id'],
      studentId: json['student_id'],
      date: DateTime.parse(json['date']),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AttendanceStatus.present,
      ),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'student_id': studentId,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
      'notes': notes,
    };
  }
}
