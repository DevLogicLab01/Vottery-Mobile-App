class FraudAnalysisResult {
  final String analysisId;
  final String userId;
  final String voteId;
  final double riskScore;
  final String riskLevel;
  final List<FraudIndicator> indicators;
  final Map<String, dynamic> analysis;
  final bool requiresReview;
  final String recommendation;
  final DateTime timestamp;

  FraudAnalysisResult({
    required this.analysisId,
    required this.userId,
    required this.voteId,
    required this.riskScore,
    required this.riskLevel,
    required this.indicators,
    required this.analysis,
    required this.requiresReview,
    required this.recommendation,
    required this.timestamp,
  });

  factory FraudAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FraudAnalysisResult(
      analysisId: json['analysis_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      voteId: json['vote_id'] as String? ?? '',
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['risk_level'] as String? ?? 'low',
      indicators: (json['indicators'] as List<dynamic>? ?? [])
          .map((e) => FraudIndicator.fromJson(e as Map<String, dynamic>))
          .toList(),
      analysis: json['analysis'] as Map<String, dynamic>? ?? {},
      requiresReview: json['requires_review'] as bool? ?? false,
      recommendation: json['recommendation'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis_id': analysisId,
      'user_id': userId,
      'vote_id': voteId,
      'risk_score': riskScore,
      'risk_level': riskLevel,
      'indicators': indicators.map((e) => e.toJson()).toList(),
      'analysis': analysis,
      'requires_review': requiresReview,
      'recommendation': recommendation,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isHighRisk => riskScore >= 70;
  bool get isMediumRisk => riskScore >= 40 && riskScore < 70;
  bool get isLowRisk => riskScore < 40;
}

class FraudIndicator {
  final String type;
  final String description;
  final double severity;
  final Map<String, dynamic> details;

  FraudIndicator({
    required this.type,
    required this.description,
    required this.severity,
    required this.details,
  });

  factory FraudIndicator.fromJson(Map<String, dynamic> json) {
    return FraudIndicator(
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      severity: (json['severity'] as num?)?.toDouble() ?? 0.0,
      details: json['details'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'severity': severity,
      'details': details,
    };
  }
}
