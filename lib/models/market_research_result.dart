/// Market Research Result Model
/// Represents market research and sentiment analysis by Perplexity
class MarketResearchResult {
  final String researchId;
  final List<String> topics;
  final double sentimentScore;
  final Map<String, dynamic> sentimentBreakdown;
  final List<MarketTrend> trends;
  final Map<String, dynamic> competitiveLandscape;
  final List<String> keyInsights;
  final Map<String, dynamic> dataPoints;
  final List<String> sources;
  final String timeframe;
  final DateTime conductedAt;

  MarketResearchResult({
    required this.researchId,
    required this.topics,
    required this.sentimentScore,
    required this.sentimentBreakdown,
    required this.trends,
    required this.competitiveLandscape,
    required this.keyInsights,
    required this.dataPoints,
    required this.sources,
    required this.timeframe,
    required this.conductedAt,
  });

  /// Create MarketResearchResult from JSON
  factory MarketResearchResult.fromJson(Map<String, dynamic> json) {
    return MarketResearchResult(
      researchId: json['research_id'] as String? ?? '',
      topics:
          (json['topics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble() ?? 0.0,
      sentimentBreakdown:
          json['sentiment_breakdown'] as Map<String, dynamic>? ?? {},
      trends:
          (json['trends'] as List<dynamic>?)
              ?.map((e) => MarketTrend.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      competitiveLandscape:
          json['competitive_landscape'] as Map<String, dynamic>? ?? {},
      keyInsights:
          (json['key_insights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dataPoints: json['data_points'] as Map<String, dynamic>? ?? {},
      sources:
          (json['sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      timeframe: json['timeframe'] as String? ?? 'last_30_days',
      conductedAt: json['conducted_at'] != null
          ? DateTime.parse(json['conducted_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert MarketResearchResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'research_id': researchId,
      'topics': topics,
      'sentiment_score': sentimentScore,
      'sentiment_breakdown': sentimentBreakdown,
      'trends': trends.map((e) => e.toJson()).toList(),
      'competitive_landscape': competitiveLandscape,
      'key_insights': keyInsights,
      'data_points': dataPoints,
      'sources': sources,
      'timeframe': timeframe,
      'conducted_at': conductedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  MarketResearchResult copyWith({
    String? researchId,
    List<String>? topics,
    double? sentimentScore,
    Map<String, dynamic>? sentimentBreakdown,
    List<MarketTrend>? trends,
    Map<String, dynamic>? competitiveLandscape,
    List<String>? keyInsights,
    Map<String, dynamic>? dataPoints,
    List<String>? sources,
    String? timeframe,
    DateTime? conductedAt,
  }) {
    return MarketResearchResult(
      researchId: researchId ?? this.researchId,
      topics: topics ?? this.topics,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      sentimentBreakdown: sentimentBreakdown ?? this.sentimentBreakdown,
      trends: trends ?? this.trends,
      competitiveLandscape: competitiveLandscape ?? this.competitiveLandscape,
      keyInsights: keyInsights ?? this.keyInsights,
      dataPoints: dataPoints ?? this.dataPoints,
      sources: sources ?? this.sources,
      timeframe: timeframe ?? this.timeframe,
      conductedAt: conductedAt ?? this.conductedAt,
    );
  }

  @override
  String toString() {
    return 'MarketResearchResult(researchId: $researchId, sentimentScore: $sentimentScore, topics: ${topics.length})';
  }
}

/// Market Trend Model
/// Represents individual market trends in research results
class MarketTrend {
  final String name;
  final String direction;
  final double strength;
  final String category;
  final String description;
  final List<String> relatedTopics;

  MarketTrend({
    required this.name,
    required this.direction,
    required this.strength,
    required this.category,
    required this.description,
    required this.relatedTopics,
  });

  factory MarketTrend.fromJson(Map<String, dynamic> json) {
    return MarketTrend(
      name: json['name'] as String? ?? '',
      direction: json['direction'] as String? ?? 'neutral',
      strength: (json['strength'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'general',
      description: json['description'] as String? ?? '',
      relatedTopics:
          (json['related_topics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'direction': direction,
      'strength': strength,
      'category': category,
      'description': description,
      'related_topics': relatedTopics,
    };
  }
}
