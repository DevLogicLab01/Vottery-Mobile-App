import './claude_service.dart';

class ContentQualityScoringService {
  static ContentQualityScoringService? _instance;
  static ContentQualityScoringService get instance =>
      _instance ??= ContentQualityScoringService._();

  ContentQualityScoringService._();

  final ClaudeService _claude = ClaudeService.instance;

  Future<Map<String, dynamic>> scoreContent({
    required String content,
    required String contentType,
  }) async {
    final moderation = await _claude.moderateContent(
      content: content,
      contentType: contentType,
    );

    final qualityScore =
        (moderation['content_quality_score'] as num?)?.toDouble() ?? 0.0;
    final riskScore = (moderation['risk_score'] as num?)?.toDouble() ?? 0.0;
    final neutralityScore = (100.0 - riskScore).clamp(0.0, 100.0);
    final engagementPrediction = (qualityScore * 0.82).clamp(0.0, 100.0);
    final suggestions = List<String>.from(moderation['violations'] ?? const [])
        .map((v) => 'Reduce or revise: $v')
        .toList();

    final rewritePrompt = '''
Rewrite this ${contentType.toLowerCase()} to improve neutrality, clarity, and engagement while preserving the original intent.

Content:
$content
''';
    final rewritten = await _claude.callClaudeAPI(rewritePrompt);

    return {
      'clarity_score': qualityScore,
      'neutrality_score': neutralityScore,
      'engagement_prediction': engagementPrediction,
      'suggestions': suggestions,
      'rewritten_version': rewritten.trim().isEmpty ? content : rewritten.trim(),
      'raw': moderation,
    };
  }
}
