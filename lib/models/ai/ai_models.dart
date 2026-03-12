/// AI Consensus Result Model
/// Represents the aggregated result from multiple AI providers
class AIConsensusResult {
  const AIConsensusResult({
    required this.id,
    required this.analysisType,
    required this.providerResults,
    required this.consensusRecommendation,
    required this.confidence,
    required this.hasConsensus,
    required this.timestamp,
    this.metadata,
  });

  final String id;
  final String analysisType;
  final List<AIProviderResult> providerResults;
  final String consensusRecommendation;
  final double confidence;
  final bool hasConsensus;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  factory AIConsensusResult.fromJson(Map<String, dynamic> json) {
    return AIConsensusResult(
      id: json['id'] as String,
      analysisType: json['analysisType'] as String,
      providerResults: (json['providerResults'] as List)
          .map((e) => AIProviderResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      consensusRecommendation: json['consensusRecommendation'] as String,
      confidence: json['confidence'] as double,
      hasConsensus: json['hasConsensus'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// AI Provider Result Model
/// Represents individual AI provider response
class AIProviderResult {
  const AIProviderResult({
    required this.name,
    required this.recommendation,
    required this.confidence,
    required this.responseTime,
    required this.success,
    this.errorMessage,
  });

  final String name;
  final String recommendation;
  final double confidence;
  final int responseTime;
  final bool success;
  final String? errorMessage;

  factory AIProviderResult.fromJson(Map<String, dynamic> json) {
    return AIProviderResult(
      name: json['name'] as String,
      recommendation: json['recommendation'] as String,
      confidence: json['confidence'] as double,
      responseTime: json['responseTime'] as int,
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// Quest Model
/// Represents AI-generated personalized quests
class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.targetValue,
    required this.currentProgress,
    required this.vpReward,
    required this.expiresAt,
    required this.status,
    this.metadata,
  });

  final String id;
  final String title;
  final String description;
  final String type;
  final String difficulty;
  final int targetValue;
  final int currentProgress;
  final int vpReward;
  final DateTime expiresAt;
  final String status;
  final Map<String, dynamic>? metadata;

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      difficulty: json['difficulty'] as String,
      targetValue: json['targetValue'] as int,
      currentProgress: json['currentProgress'] as int,
      vpReward: json['vpReward'] as int,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      status: json['status'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
