/// Revenue Risk Analysis Model
/// Represents revenue risk intelligence analysis by Anthropic Claude
class RevenueRiskAnalysis {
  final String analysisId;
  final double overallRiskScore;
  final List<RiskFactor> riskFactors;
  final Map<String, dynamic> revenueStreams;
  final List<String> mitigationStrategies;
  final String riskLevel;
  final double confidenceScore;
  final Map<String, dynamic> forecast;
  final List<String> recommendations;
  final DateTime analyzedAt;

  RevenueRiskAnalysis({
    required this.analysisId,
    required this.overallRiskScore,
    required this.riskFactors,
    required this.revenueStreams,
    required this.mitigationStrategies,
    required this.riskLevel,
    required this.confidenceScore,
    required this.forecast,
    required this.recommendations,
    required this.analyzedAt,
  });

  /// Create RevenueRiskAnalysis from JSON
  factory RevenueRiskAnalysis.fromJson(Map<String, dynamic> json) {
    return RevenueRiskAnalysis(
      analysisId: json['analysis_id'] as String? ?? '',
      overallRiskScore: (json['overall_risk_score'] as num?)?.toDouble() ?? 0.0,
      riskFactors:
          (json['risk_factors'] as List<dynamic>?)
              ?.map((e) => RiskFactor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      revenueStreams: json['revenue_streams'] as Map<String, dynamic>? ?? {},
      mitigationStrategies:
          (json['mitigation_strategies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      riskLevel: json['risk_level'] as String? ?? 'medium',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      forecast: json['forecast'] as Map<String, dynamic>? ?? {},
      recommendations:
          (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert RevenueRiskAnalysis to JSON
  Map<String, dynamic> toJson() {
    return {
      'analysis_id': analysisId,
      'overall_risk_score': overallRiskScore,
      'risk_factors': riskFactors.map((e) => e.toJson()).toList(),
      'revenue_streams': revenueStreams,
      'mitigation_strategies': mitigationStrategies,
      'risk_level': riskLevel,
      'confidence_score': confidenceScore,
      'forecast': forecast,
      'recommendations': recommendations,
      'analyzed_at': analyzedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  RevenueRiskAnalysis copyWith({
    String? analysisId,
    double? overallRiskScore,
    List<RiskFactor>? riskFactors,
    Map<String, dynamic>? revenueStreams,
    List<String>? mitigationStrategies,
    String? riskLevel,
    double? confidenceScore,
    Map<String, dynamic>? forecast,
    List<String>? recommendations,
    DateTime? analyzedAt,
  }) {
    return RevenueRiskAnalysis(
      analysisId: analysisId ?? this.analysisId,
      overallRiskScore: overallRiskScore ?? this.overallRiskScore,
      riskFactors: riskFactors ?? this.riskFactors,
      revenueStreams: revenueStreams ?? this.revenueStreams,
      mitigationStrategies: mitigationStrategies ?? this.mitigationStrategies,
      riskLevel: riskLevel ?? this.riskLevel,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      forecast: forecast ?? this.forecast,
      recommendations: recommendations ?? this.recommendations,
      analyzedAt: analyzedAt ?? this.analyzedAt,
    );
  }

  @override
  String toString() {
    return 'RevenueRiskAnalysis(analysisId: $analysisId, overallRiskScore: $overallRiskScore, riskLevel: $riskLevel)';
  }
}

/// Risk Factor Model
/// Represents individual risk factors in revenue analysis
class RiskFactor {
  final String name;
  final double impact;
  final double probability;
  final String category;
  final String description;

  RiskFactor({
    required this.name,
    required this.impact,
    required this.probability,
    required this.category,
    required this.description,
  });

  factory RiskFactor.fromJson(Map<String, dynamic> json) {
    return RiskFactor(
      name: json['name'] as String? ?? '',
      impact: (json['impact'] as num?)?.toDouble() ?? 0.0,
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'general',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'impact': impact,
      'probability': probability,
      'category': category,
      'description': description,
    };
  }
}
