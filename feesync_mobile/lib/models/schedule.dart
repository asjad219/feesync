class ScheduleSlot {
  final int dayOfWeek; // 1 (Mon) to 7 (Sun)
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final String? room;

  ScheduleSlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      room: json['room'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
    };
  }

  ScheduleSlot copyWith({
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
  }) {
    return ScheduleSlot(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
    );
  }
}
