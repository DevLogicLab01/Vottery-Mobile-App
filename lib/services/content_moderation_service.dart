import 'package:flutter/foundation.dart';
import 'dart:convert';
import './claude_service.dart';
import './supabase_service.dart';
import './auth_service.dart';

class ContentModerationService {
  static ContentModerationService? _instance;
  static ContentModerationService get instance =>
      _instance ??= ContentModerationService._();

  ContentModerationService._();

  final ClaudeService _claudeService = ClaudeService.instance;
  final _client = SupabaseService.instance.client;
  final AuthService _auth = AuthService.instance;

  /// Moderate content using Claude AI
  Future<Map<String, dynamic>> moderateContent({
    required String contentText,
    required String contentType,
    required String contentId,
    List<String>? mediaUrls,
    String? userId,
  }) async {
    try {
      // Build moderation prompt
      final prompt = _buildModerationPrompt(
        contentText,
        contentType,
        mediaUrls ?? [],
      );

      // Call Claude API
      final claudeResponse = await _claudeService.callClaudeAPI(prompt);
      final analysis = _parseClaudeResponse(claudeResponse);

      // Calculate overall safety
      final isSafe = _calculateSafety(analysis['violations'] as List);
      final confidenceScore = _calculateConfidence(
        analysis['violations'] as List,
      );

      // Log moderation result
      await _logModerationResult(
        contentId: contentId,
        contentType: contentType,
        contentText: contentText,
        mediaUrls: mediaUrls ?? [],
        violations: analysis['violations'] as List,
        isSafe: isSafe,
        confidenceScore: confidenceScore,
        claudeReasoning: analysis['reasoning'] as String,
        userId: userId,
      );

      // Check for auto-removal
      if (!isSafe) {
        await _checkAutoRemoval(
          contentId: contentId,
          contentType: contentType,
          violations: analysis['violations'] as List,
          confidenceScore: confidenceScore,
          userId: userId,
        );
      }

      return {
        'is_safe': isSafe,
        'confidence_score': confidenceScore,
        'violation_categories': analysis['violations'],
        'reasoning': analysis['reasoning'],
      };
    } catch (e) {
      debugPrint('Content moderation error: $e');
      return {
        'is_safe': true,
        'confidence_score': 0.0,
        'violation_categories': [],
        'reasoning': 'Moderation service unavailable',
      };
    }
  }

  String _buildModerationPrompt(
    String content,
    String contentType,
    List<String> mediaUrls,
  ) {
    return '''
Analyze this user-generated content for policy violations.

Content Type: $contentType
Content: $content
Media URLs: ${mediaUrls.join(', ')}

Detect the following violation categories:
1. Hate speech/harassment
2. Violence/graphic content
3. Sexual content
4. Spam/manipulation
5. Misinformation
6. Copyright infringement
7. Minor safety concerns

For each violation found, provide:
- Category (from list above)
- Severity (low/medium/high/critical)
- Confidence score (0.0-1.0)
- Specific evidence from the content
- Recommended action (warn/remove/ban)

Return your analysis in this JSON format:
{
  "violations": [
    {
      "category": "hate_speech",
      "severity": "high",
      "confidence": 0.85,
      "evidence": "specific text or description",
      "action": "remove"
    }
  ],
  "reasoning": "Overall explanation of the analysis"
}

If no violations found, return empty violations array.
''';
  }

  Map<String, dynamic> _parseClaudeResponse(String response) {
    try {
      // Extract JSON from Claude response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd == 0) {
        return {'violations': [], 'reasoning': 'No violations detected'};
      }

      final jsonStr = response.substring(jsonStart, jsonEnd);
      final data = Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);

      return {
        'violations': data['violations'] ?? [],
        'reasoning': data['reasoning'] ?? 'Analysis completed',
      };
    } catch (e) {
      debugPrint('Parse Claude response error: $e');
      return {'violations': [], 'reasoning': 'Parse error'};
    }
  }

  bool _calculateSafety(List violations) {
    if (violations.isEmpty) return true;

    // Check for critical violations
    for (final violation in violations) {
      final severity = violation['severity'] as String?;
      final confidence = (violation['confidence'] as num?)?.toDouble() ?? 0.0;

      if (severity == 'critical' && confidence >= 0.6) {
        return false;
      }
      if (severity == 'high' && confidence >= 0.7) {
        return false;
      }
    }

    return true;
  }

  double _calculateConfidence(List violations) {
    if (violations.isEmpty) return 1.0;

    double totalConfidence = 0.0;
    for (final violation in violations) {
      totalConfidence += (violation['confidence'] as num?)?.toDouble() ?? 0.0;
    }

    return totalConfidence / violations.length;
  }

  Future<void> _logModerationResult({
    required String contentId,
    required String contentType,
    required String contentText,
    required List<String> mediaUrls,
    required List violations,
    required bool isSafe,
    required double confidenceScore,
    required String claudeReasoning,
    String? userId,
  }) async {
    try {
      await _client.from('moderation_log').insert({
        'content_id': contentId,
        'content_type': contentType,
        'content_text': contentText,
        'media_urls': mediaUrls,
        'violation_categories': violations,
        'is_safe': isSafe,
        'confidence_score': confidenceScore,
        'action_taken': isSafe ? 'approved' : 'flagged',
        'claude_reasoning': claudeReasoning,
      });
    } catch (e) {
      debugPrint('Log moderation result error: $e');
    }
  }

  Future<void> _checkAutoRemoval({
    required String contentId,
    required String contentType,
    required List violations,
    required double confidenceScore,
    String? userId,
  }) async {
    try {
      for (final violation in violations) {
        final category = violation['category'] as String;
        final violationConfidence = (violation['confidence'] as num).toDouble();

        // Get config for this content type and violation
        final config = await _client
            .from('moderation_config')
            .select()
            .eq('content_type', contentType)
            .eq('violation_category', category)
            .maybeSingle();

        if (config != null) {
          final threshold = (config['confidence_threshold'] as num).toDouble();
          final autoRemoveEnabled = config['auto_remove_enabled'] as bool;

          if (autoRemoveEnabled && violationConfidence >= threshold) {
            // Auto-remove content
            await _executeAutoRemoval(
              contentId: contentId,
              contentType: contentType,
              reason: category,
              userId: userId,
            );
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Check auto-removal error: $e');
    }
  }

  Future<void> _executeAutoRemoval({
    required String contentId,
    required String contentType,
    required String reason,
    String? userId,
  }) async {
    try {
      // Update moderation log
      await _client
          .from('moderation_log')
          .update({'action_taken': 'removed', 'removed_automatically': true})
          .eq('content_id', contentId);

      // Add to user moderation history
      if (userId != null) {
        await _client.from('user_moderation_history').insert({
          'user_id': userId,
          'violation_type': reason,
          'action_taken': 'warned',
        });
      }

      debugPrint('Content auto-removed: $contentId');
    } catch (e) {
      debugPrint('Execute auto-removal error: $e');
    }
  }

  /// Submit appeal for removed content (shared schema: content_appeals needs flag_id).
  /// Prefer ModerationSharedService.submitAppealByContent which finds flag_id by content_id.
  Future<bool> submitAppeal({
    required String contentId,
    required String reason,
    String? flagId,
    String? contentType,
    List<String>? evidenceUrls,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      String? resolvedFlagId = flagId;
      if (resolvedFlagId == null && contentType != null) {
        final flag = await _client
            .from('content_flags')
            .select('id')
            .eq('content_id', contentId)
            .eq('content_type', contentType)
            .inFilter('status', ['auto_removed', 'content_removed'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        resolvedFlagId = flag?['id'] as String?;
      }
      if (resolvedFlagId == null) {
        debugPrint('submitAppeal: no flag found for content_id=$contentId');
        return false;
      }

      await _client.from('content_appeals').insert({
        'flag_id': resolvedFlagId,
        'content_type': contentType ?? 'post',
        'content_id': contentId,
        'appellant_id': _auth.currentUser!.id,
        'reason': reason,
        'status': 'pending',
      });

      return true;
    } catch (e) {
      debugPrint('Submit appeal error: $e');
      return false;
    }
  }

  /// Get moderation statistics
  Future<Map<String, int>> getModerationStats() async {
    try {
      final flaggedCount = await _client
          .from('moderation_log')
          .select('id')
          .eq('action_taken', 'flagged')
          .count();

      final pendingCount = await _client
          .from('moderation_reviews')
          .select('id')
          .eq('status', 'pending_review')
          .count();

      final appealCount = await _client
          .from('content_appeals')
          .select('id')
          .eq('status', 'pending')
          .count();

      return {
        'flagged': flaggedCount.count,
        'pending': pendingCount.count,
        'appeals': appealCount.count,
      };
    } catch (e) {
      debugPrint('Get moderation stats error: $e');
      return {'flagged': 0, 'pending': 0, 'appeals': 0};
    }
  }
}
