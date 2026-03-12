class SecurityAlert {
  final String id;
  final String type;
  final String severity;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final bool acknowledged;

  SecurityAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.metadata,
    required this.timestamp,
    required this.acknowledged,
  });

  factory SecurityAlert.fromJson(Map<String, dynamic> json) {
    return SecurityAlert(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'low',
      description: json['description'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      acknowledged: json['acknowledged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'description': description,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'acknowledged': acknowledged,
    };
  }

  SecurityAlert copyWith({
    String? id,
    String? type,
    String? severity,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    bool? acknowledged,
  }) {
    return SecurityAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }
}
