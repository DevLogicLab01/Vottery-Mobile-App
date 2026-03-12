class PlatformLog {
  final String id;
  final String? userId;
  final String logLevel;
  final String logCategory;
  final String eventType;
  final String message;
  final DateTime createdAt;
  final bool sensitiveData;
  final Map<String, dynamic>? metadata;
  final String? logSource;

  PlatformLog({
    required this.id,
    this.userId,
    required this.logLevel,
    required this.logCategory,
    required this.eventType,
    required this.message,
    required this.createdAt,
    required this.sensitiveData,
    this.metadata,
    this.logSource,
  });

  factory PlatformLog.fromJson(Map<String, dynamic> json) {
    return PlatformLog(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      logLevel: json['log_level'] as String,
      logCategory: json['log_category'] as String,
      eventType: json['event_type'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      sensitiveData: json['sensitive_data'] as bool,
      metadata: json['metadata'] as Map<String, dynamic>?,
      logSource: json['log_source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'log_level': logLevel,
      'log_category': logCategory,
      'event_type': eventType,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'sensitive_data': sensitiveData,
      'metadata': metadata,
      'log_source': logSource,
    };
  }
}
