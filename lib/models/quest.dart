class Quest {
  final String id;
  final String title;
  final String description;
  final String type;
  final String difficulty;
  final int vpReward;
  final Map<String, dynamic> requirements;
  final DateTime expiresAt;
  final bool isCompleted;
  final double progress;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.vpReward,
    required this.requirements,
    required this.expiresAt,
    this.isCompleted = false,
    this.progress = 0.0,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'daily',
      difficulty: json['difficulty'] as String? ?? 'medium',
      vpReward: json['vp_reward'] as int? ?? 0,
      requirements: json['requirements'] as Map<String, dynamic>? ?? {},
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(days: 1)),
      isCompleted: json['is_completed'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'difficulty': difficulty,
      'vp_reward': vpReward,
      'requirements': requirements,
      'expires_at': expiresAt.toIso8601String(),
      'is_completed': isCompleted,
      'progress': progress,
    };
  }
}
