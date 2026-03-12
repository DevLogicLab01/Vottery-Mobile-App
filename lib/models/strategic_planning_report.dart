/// Strategic Planning Report Model
/// Represents strategic planning insights by Perplexity with competitive analysis
class StrategicPlanningReport {
  final String reportId;
  final List<StrategicRecommendation> strategicRecommendations;
  final CompetitiveAnalysis competitiveAnalysis;
  final List<MarketOpportunity> marketOpportunities;
  final Map<String, dynamic> riskAssessment;
  final Map<String, dynamic> growthProjections;
  final List<String> keyPriorities;
  final Map<String, dynamic> resourceAllocation;
  final String analysisType;
  final DateTime generatedAt;

  StrategicPlanningReport({
    required this.reportId,
    required this.strategicRecommendations,
    required this.competitiveAnalysis,
    required this.marketOpportunities,
    required this.riskAssessment,
    required this.growthProjections,
    required this.keyPriorities,
    required this.resourceAllocation,
    required this.analysisType,
    required this.generatedAt,
  });

  /// Create StrategicPlanningReport from JSON
  factory StrategicPlanningReport.fromJson(Map<String, dynamic> json) {
    return StrategicPlanningReport(
      reportId: json['report_id'] as String? ?? '',
      strategicRecommendations:
          (json['strategic_recommendations'] as List<dynamic>?)
              ?.map(
                (e) =>
                    StrategicRecommendation.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      competitiveAnalysis: json['competitive_analysis'] != null
          ? CompetitiveAnalysis.fromJson(
              json['competitive_analysis'] as Map<String, dynamic>,
            )
          : CompetitiveAnalysis.empty(),
      marketOpportunities:
          (json['market_opportunities'] as List<dynamic>?)
              ?.map(
                (e) => MarketOpportunity.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      riskAssessment: json['risk_assessment'] as Map<String, dynamic>? ?? {},
      growthProjections:
          json['growth_projections'] as Map<String, dynamic>? ?? {},
      keyPriorities:
          (json['key_priorities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      resourceAllocation:
          json['resource_allocation'] as Map<String, dynamic>? ?? {},
      analysisType: json['analysis_type'] as String? ?? 'comprehensive',
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert StrategicPlanningReport to JSON
  Map<String, dynamic> toJson() {
    return {
      'report_id': reportId,
      'strategic_recommendations': strategicRecommendations
          .map((e) => e.toJson())
          .toList(),
      'competitive_analysis': competitiveAnalysis.toJson(),
      'market_opportunities': marketOpportunities
          .map((e) => e.toJson())
          .toList(),
      'risk_assessment': riskAssessment,
      'growth_projections': growthProjections,
      'key_priorities': keyPriorities,
      'resource_allocation': resourceAllocation,
      'analysis_type': analysisType,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  StrategicPlanningReport copyWith({
    String? reportId,
    List<StrategicRecommendation>? strategicRecommendations,
    CompetitiveAnalysis? competitiveAnalysis,
    List<MarketOpportunity>? marketOpportunities,
    Map<String, dynamic>? riskAssessment,
    Map<String, dynamic>? growthProjections,
    List<String>? keyPriorities,
    Map<String, dynamic>? resourceAllocation,
    String? analysisType,
    DateTime? generatedAt,
  }) {
    return StrategicPlanningReport(
      reportId: reportId ?? this.reportId,
      strategicRecommendations:
          strategicRecommendations ?? this.strategicRecommendations,
      competitiveAnalysis: competitiveAnalysis ?? this.competitiveAnalysis,
      marketOpportunities: marketOpportunities ?? this.marketOpportunities,
      riskAssessment: riskAssessment ?? this.riskAssessment,
      growthProjections: growthProjections ?? this.growthProjections,
      keyPriorities: keyPriorities ?? this.keyPriorities,
      resourceAllocation: resourceAllocation ?? this.resourceAllocation,
      analysisType: analysisType ?? this.analysisType,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  String toString() {
    return 'StrategicPlanningReport(reportId: $reportId, recommendations: ${strategicRecommendations.length})';
  }
}

/// Strategic Recommendation Model
class StrategicRecommendation {
  final String recommendation;
  final String priority;
  final double expectedImpact;
  final String implementationTimeline;
  final List<String> resourcesRequired;

  StrategicRecommendation({
    required this.recommendation,
    required this.priority,
    required this.expectedImpact,
    required this.implementationTimeline,
    required this.resourcesRequired,
  });

  factory StrategicRecommendation.fromJson(Map<String, dynamic> json) {
    return StrategicRecommendation(
      recommendation: json['recommendation'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      expectedImpact: (json['expected_impact'] as num?)?.toDouble() ?? 0.0,
      implementationTimeline: json['implementation_timeline'] as String? ?? '',
      resourcesRequired:
          (json['resources_required'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendation': recommendation,
      'priority': priority,
      'expected_impact': expectedImpact,
      'implementation_timeline': implementationTimeline,
      'resources_required': resourcesRequired,
    };
  }
}

/// Competitive Analysis Model
class CompetitiveAnalysis {
  final List<String> threats;
  final List<String> opportunities;
  final Map<String, dynamic> marketPosition;
  final List<String> competitorStrengths;
  final List<String> competitorWeaknesses;

  CompetitiveAnalysis({
    required this.threats,
    required this.opportunities,
    required this.marketPosition,
    required this.competitorStrengths,
    required this.competitorWeaknesses,
  });

  factory CompetitiveAnalysis.fromJson(Map<String, dynamic> json) {
    return CompetitiveAnalysis(
      threats:
          (json['threats'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      opportunities:
          (json['opportunities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      marketPosition: json['market_position'] as Map<String, dynamic>? ?? {},
      competitorStrengths:
          (json['competitor_strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      competitorWeaknesses:
          (json['competitor_weaknesses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  factory CompetitiveAnalysis.empty() {
    return CompetitiveAnalysis(
      threats: [],
      opportunities: [],
      marketPosition: {},
      competitorStrengths: [],
      competitorWeaknesses: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'threats': threats,
      'opportunities': opportunities,
      'market_position': marketPosition,
      'competitor_strengths': competitorStrengths,
      'competitor_weaknesses': competitorWeaknesses,
    };
  }
}

/// Market Opportunity Model
class MarketOpportunity {
  final String name;
  final double potentialValue;
  final String timeframe;
  final String difficulty;
  final List<String> requirements;

  MarketOpportunity({
    required this.name,
    required this.potentialValue,
    required this.timeframe,
    required this.difficulty,
    required this.requirements,
  });

  factory MarketOpportunity.fromJson(Map<String, dynamic> json) {
    return MarketOpportunity(
      name: json['name'] as String? ?? '',
      potentialValue: (json['potential_value'] as num?)?.toDouble() ?? 0.0,
      timeframe: json['timeframe'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'medium',
      requirements:
          (json['requirements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'potential_value': potentialValue,
      'timeframe': timeframe,
      'difficulty': difficulty,
      'requirements': requirements,
    };
  }
}
