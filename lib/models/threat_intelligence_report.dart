/// Threat Intelligence Report Model
/// Represents threat intelligence analysis by Perplexity with web search
class ThreatIntelligenceReport {
  final String reportId;
  final String threatLevel;
  final List<EmergingThreat> emergingThreats;
  final Map<String, dynamic> forecast60d;
  final Map<String, dynamic> forecast90d;
  final List<String> seasonalPatterns;
  final List<String> recommendedActions;
  final List<String> relatedQuestions;
  final Map<String, dynamic> webSources;
  final DateTime generatedAt;

  ThreatIntelligenceReport({
    required this.reportId,
    required this.threatLevel,
    required this.emergingThreats,
    required this.forecast60d,
    required this.forecast90d,
    required this.seasonalPatterns,
    required this.recommendedActions,
    required this.relatedQuestions,
    required this.webSources,
    required this.generatedAt,
  });

  /// Create ThreatIntelligenceReport from JSON
  factory ThreatIntelligenceReport.fromJson(Map<String, dynamic> json) {
    return ThreatIntelligenceReport(
      reportId: json['report_id'] as String? ?? '',
      threatLevel: json['threat_level'] as String? ?? 'unknown',
      emergingThreats:
          (json['emerging_threats'] as List<dynamic>?)
              ?.map((e) => EmergingThreat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      forecast60d: json['forecast_60d'] as Map<String, dynamic>? ?? {},
      forecast90d: json['forecast_90d'] as Map<String, dynamic>? ?? {},
      seasonalPatterns:
          (json['seasonal_patterns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recommendedActions:
          (json['recommended_actions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      relatedQuestions:
          (json['related_questions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      webSources: json['web_sources'] as Map<String, dynamic>? ?? {},
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert ThreatIntelligenceReport to JSON
  Map<String, dynamic> toJson() {
    return {
      'report_id': reportId,
      'threat_level': threatLevel,
      'emerging_threats': emergingThreats.map((e) => e.toJson()).toList(),
      'forecast_60d': forecast60d,
      'forecast_90d': forecast90d,
      'seasonal_patterns': seasonalPatterns,
      'recommended_actions': recommendedActions,
      'related_questions': relatedQuestions,
      'web_sources': webSources,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  ThreatIntelligenceReport copyWith({
    String? reportId,
    String? threatLevel,
    List<EmergingThreat>? emergingThreats,
    Map<String, dynamic>? forecast60d,
    Map<String, dynamic>? forecast90d,
    List<String>? seasonalPatterns,
    List<String>? recommendedActions,
    List<String>? relatedQuestions,
    Map<String, dynamic>? webSources,
    DateTime? generatedAt,
  }) {
    return ThreatIntelligenceReport(
      reportId: reportId ?? this.reportId,
      threatLevel: threatLevel ?? this.threatLevel,
      emergingThreats: emergingThreats ?? this.emergingThreats,
      forecast60d: forecast60d ?? this.forecast60d,
      forecast90d: forecast90d ?? this.forecast90d,
      seasonalPatterns: seasonalPatterns ?? this.seasonalPatterns,
      recommendedActions: recommendedActions ?? this.recommendedActions,
      relatedQuestions: relatedQuestions ?? this.relatedQuestions,
      webSources: webSources ?? this.webSources,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  String toString() {
    return 'ThreatIntelligenceReport(reportId: $reportId, threatLevel: $threatLevel, emergingThreats: ${emergingThreats.length})';
  }
}

/// Emerging Threat Model
/// Represents individual emerging threats in the intelligence report
class EmergingThreat {
  final String type;
  final double likelihood;
  final double impact;
  final String description;
  final List<String> indicators;

  EmergingThreat({
    required this.type,
    required this.likelihood,
    required this.impact,
    required this.description,
    required this.indicators,
  });

  factory EmergingThreat.fromJson(Map<String, dynamic> json) {
    return EmergingThreat(
      type: json['type'] as String? ?? '',
      likelihood: (json['likelihood'] as num?)?.toDouble() ?? 0.0,
      impact: (json['impact'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      indicators:
          (json['indicators'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'likelihood': likelihood,
      'impact': impact,
      'description': description,
      'indicators': indicators,
    };
  }
}
