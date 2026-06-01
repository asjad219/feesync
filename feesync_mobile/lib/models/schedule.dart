class ScheduleSlot {
  final String id;
  final String batchId;
  final int dayOfWeek; // 1 (Mon) to 7 (Sun)
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final String? room;

  ScheduleSlot({
    required this.id,
    required this.batchId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      id: json['id'],
      batchId: json['batch_id'],
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      room: json['room'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
    };
  }
}
