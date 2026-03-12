/// Content Moderation Result Model
/// Represents the result of content moderation by Anthropic Claude
class ContentModerationResult {
  final String contentId;
  final String decision;
  final double confidence;
  final List<String> violations;
  final String contentType;
  final String reasoning;
  final Map<String, dynamic> categories;
  final bool requiresHumanReview;
  final String severity;
  final List<String> suggestedActions;
  final DateTime moderatedAt;

  ContentModerationResult({
    required this.contentId,
    required this.decision,
    required this.confidence,
    required this.violations,
    required this.contentType,
    required this.reasoning,
    required this.categories,
    required this.requiresHumanReview,
    required this.severity,
    required this.suggestedActions,
    required this.moderatedAt,
  });

  /// Create ContentModerationResult from JSON
  factory ContentModerationResult.fromJson(Map<String, dynamic> json) {
    return ContentModerationResult(
      contentId: json['content_id'] as String? ?? '',
      decision: json['decision'] as String? ?? 'pending',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      violations:
          (json['violations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      contentType: json['content_type'] as String? ?? 'unknown',
      reasoning: json['reasoning'] as String? ?? '',
      categories: json['categories'] as Map<String, dynamic>? ?? {},
      requiresHumanReview: json['requires_human_review'] as bool? ?? false,
      severity: json['severity'] as String? ?? 'low',
      suggestedActions:
          (json['suggested_actions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      moderatedAt: json['moderated_at'] != null
          ? DateTime.parse(json['moderated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert ContentModerationResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'content_id': contentId,
      'decision': decision,
      'confidence': confidence,
      'violations': violations,
      'content_type': contentType,
      'reasoning': reasoning,
      'categories': categories,
      'requires_human_review': requiresHumanReview,
      'severity': severity,
      'suggested_actions': suggestedActions,
      'moderated_at': moderatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  ContentModerationResult copyWith({
    String? contentId,
    String? decision,
    double? confidence,
    List<String>? violations,
    String? contentType,
    String? reasoning,
    Map<String, dynamic>? categories,
    bool? requiresHumanReview,
    String? severity,
    List<String>? suggestedActions,
    DateTime? moderatedAt,
  }) {
    return ContentModerationResult(
      contentId: contentId ?? this.contentId,
      decision: decision ?? this.decision,
      confidence: confidence ?? this.confidence,
      violations: violations ?? this.violations,
      contentType: contentType ?? this.contentType,
      reasoning: reasoning ?? this.reasoning,
      categories: categories ?? this.categories,
      requiresHumanReview: requiresHumanReview ?? this.requiresHumanReview,
      severity: severity ?? this.severity,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      moderatedAt: moderatedAt ?? this.moderatedAt,
    );
  }

  @override
  String toString() {
    return 'ContentModerationResult(contentId: $contentId, decision: $decision, confidence: $confidence, severity: $severity)';
  }
}
