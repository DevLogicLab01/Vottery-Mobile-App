/// Model class for MCQ optimization suggestions from Claude AI
class MCQOptimizationSuggestion {
  final String originalQuestionText;
  final String improvedQuestionText;
  final List<String> originalOptions;
  final List<String> improvedOptions;
  final String difficultyRecommendation;
  final String alternativeQuestionText;
  final List<String> alternativeOptions;
  final double projectedAccuracyImprovement;
  final double currentAccuracy;
  final String reasoning;
  final double confidenceScore;

  MCQOptimizationSuggestion({
    required this.originalQuestionText,
    required this.improvedQuestionText,
    required this.originalOptions,
    required this.improvedOptions,
    required this.difficultyRecommendation,
    required this.alternativeQuestionText,
    required this.alternativeOptions,
    required this.projectedAccuracyImprovement,
    required this.currentAccuracy,
    this.reasoning = '',
    this.confidenceScore = 75.0,
  });

  factory MCQOptimizationSuggestion.fromJson(
    Map<String, dynamic> json, {
    required String originalQuestionText,
    required List<String> originalOptions,
    required double currentAccuracy,
  }) {
    List<String> parseOptions(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return MCQOptimizationSuggestion(
      originalQuestionText: originalQuestionText,
      improvedQuestionText:
          json['improved_question_text'] as String? ?? originalQuestionText,
      originalOptions: originalOptions,
      improvedOptions: parseOptions(json['improved_options']).isNotEmpty
          ? parseOptions(json['improved_options'])
          : originalOptions,
      difficultyRecommendation:
          json['difficulty_recommendation'] as String? ?? 'maintain',
      alternativeQuestionText:
          json['alternative_question_text'] as String? ?? originalQuestionText,
      alternativeOptions: parseOptions(json['alternative_options']).isNotEmpty
          ? parseOptions(json['alternative_options'])
          : originalOptions,
      projectedAccuracyImprovement:
          (json['projected_accuracy_improvement'] as num?)?.toDouble() ?? 10.0,
      currentAccuracy: currentAccuracy,
      reasoning: json['reasoning'] as String? ?? '',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 75.0,
    );
  }
}
