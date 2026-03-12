/// Security Analysis Result Model
/// Represents the result of a security incident analysis by Anthropic Claude
class SecurityAnalysisResult {
  final String incidentId;
  final String threatLevel;
  final double confidenceScore;
  final List<String> threatVectors;
  final String severity;
  final String recommendation;
  final Map<String, dynamic> incidentDetails;
  final List<String> affectedSystems;
  final String rootCause;
  final List<String> mitigationSteps;
  final DateTime analyzedAt;

  SecurityAnalysisResult({
    required this.incidentId,
    required this.threatLevel,
    required this.confidenceScore,
    required this.threatVectors,
    required this.severity,
    required this.recommendation,
    required this.incidentDetails,
    required this.affectedSystems,
    required this.rootCause,
    required this.mitigationSteps,
    required this.analyzedAt,
  });

  /// Create SecurityAnalysisResult from JSON
  factory SecurityAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SecurityAnalysisResult(
      incidentId: json['incident_id'] as String? ?? '',
      threatLevel: json['threat_level'] as String? ?? 'unknown',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      threatVectors:
          (json['threat_vectors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      severity: json['severity'] as String? ?? 'medium',
      recommendation: json['recommendation'] as String? ?? '',
      incidentDetails: json['incident_details'] as Map<String, dynamic>? ?? {},
      affectedSystems:
          (json['affected_systems'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rootCause: json['root_cause'] as String? ?? 'Unknown',
      mitigationSteps:
          (json['mitigation_steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert SecurityAnalysisResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'incident_id': incidentId,
      'threat_level': threatLevel,
      'confidence_score': confidenceScore,
      'threat_vectors': threatVectors,
      'severity': severity,
      'recommendation': recommendation,
      'incident_details': incidentDetails,
      'affected_systems': affectedSystems,
      'root_cause': rootCause,
      'mitigation_steps': mitigationSteps,
      'analyzed_at': analyzedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  SecurityAnalysisResult copyWith({
    String? incidentId,
    String? threatLevel,
    double? confidenceScore,
    List<String>? threatVectors,
    String? severity,
    String? recommendation,
    Map<String, dynamic>? incidentDetails,
    List<String>? affectedSystems,
    String? rootCause,
    List<String>? mitigationSteps,
    DateTime? analyzedAt,
  }) {
    return SecurityAnalysisResult(
      incidentId: incidentId ?? this.incidentId,
      threatLevel: threatLevel ?? this.threatLevel,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      threatVectors: threatVectors ?? this.threatVectors,
      severity: severity ?? this.severity,
      recommendation: recommendation ?? this.recommendation,
      incidentDetails: incidentDetails ?? this.incidentDetails,
      affectedSystems: affectedSystems ?? this.affectedSystems,
      rootCause: rootCause ?? this.rootCause,
      mitigationSteps: mitigationSteps ?? this.mitigationSteps,
      analyzedAt: analyzedAt ?? this.analyzedAt,
    );
  }

  @override
  String toString() {
    return 'SecurityAnalysisResult(incidentId: $incidentId, threatLevel: $threatLevel, confidenceScore: $confidenceScore, severity: $severity)';
  }
}
