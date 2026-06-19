class SyncTask {
  final String id;
  final String type; // e.g., 'payment'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;

  SyncTask({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
      };

  factory SyncTask.fromJson(Map<String, dynamic> json) => SyncTask(
        id: json['id'],
        type: json['type'],
        payload: json['payload'],
        createdAt: DateTime.parse(json['created_at']),
        retryCount: json['retry_count'] ?? 0,
      );
}
