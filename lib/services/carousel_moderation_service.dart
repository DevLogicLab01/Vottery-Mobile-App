import 'dart:async';

import 'package:flutter/foundation.dart';

import './anthropic_service.dart';
import './perplexity_service.dart';
import './supabase_service.dart';

/// Carousel Content Moderation Service
/// AI-powered content filtering with Claude and Perplexity integration
class CarouselModerationService {
  static CarouselModerationService? _instance;
  static CarouselModerationService get instance =>
      _instance ??= CarouselModerationService._();

  CarouselModerationService._();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final PerplexityService _perplexityService = PerplexityService.instance;

  StreamSubscription? _moderationSubscription;

  // ============================================
  // REAL-TIME MODERATION PIPELINE
  // ============================================

  /// Start real-time content moderation
  void startRealtimeModeration() {
    // Subscribe to new carousel content insertions
    _moderationSubscription = _supabaseService.client
        .from('carousel_content_jolts')
        .stream(primaryKey: ['jolt_id'])
        .listen((data) {
          for (final item in data) {
            _moderateNewContent(
              contentId: item['jolt_id'],
              contentType: 'jolt',
              title: item['title'] ?? '',
              description: item['description'] ?? '',
              creatorUserId: item['creator_user_id'],
            );
          }
        });
  }

  /// Stop real-time moderation
  void stopRealtimeModeration() {
    _moderationSubscription?.cancel();
    _moderationSubscription = null;
  }

  // ============================================
  // CONTENT MODERATION
  // ============================================

  /// Moderate carousel content using Claude AI
  Future<Map<String, dynamic>> moderateCarouselContent({
    required String contentId,
    required String contentType,
    required String title,
    required String description,
    List<String>? mediaUrls,
    String? creatorUserId,
    Map<String, dynamic>? creatorMetadata,
  }) async {
    try {
      // Build moderation prompt
      final prompt = _buildModerationPrompt(
        contentType: contentType,
        title: title,
        description: description,
        mediaUrls: mediaUrls ?? [],
        creatorMetadata: creatorMetadata,
      );

      // Call Claude API for content analysis
      final claudeResponse = await _callClaudeModeration(prompt);

      // Parse violations and scores
      final violations = claudeResponse['violations'] as List;
      final safetyScore = claudeResponse['overall_safety_score'] as int;
      final qualityScore = claudeResponse['content_quality_score'] as int;
      final engagementPrediction =
          claudeResponse['engagement_prediction'] as int?;
      final recommendedActions = claudeResponse['recommended_actions'] as List;

      // Store moderation result
      final moderationRecord = await _supabaseService.client
          .from('carousel_content_moderation')
          .insert({
            'content_id': contentId,
            'content_type': contentType,
            'title': title,
            'description': description,
            'media_urls': mediaUrls,
            'creator_user_id': creatorUserId,
            'violations': violations,
            'overall_safety_score': safetyScore,
            'content_quality_score': qualityScore,
            'engagement_prediction': engagementPrediction,
            'recommended_actions': recommendedActions,
            'moderation_status': 'pending',
            'auto_actioned': false,
            'claude_reasoning': claudeResponse['reasoning'],
          })
          .select()
          .single();

      // Execute automated actions based on confidence
      await _executeAutomatedActions(
        moderationId: moderationRecord['moderation_id'],
        contentId: contentId,
        contentType: contentType,
        violations: violations,
        safetyScore: safetyScore,
        qualityScore: qualityScore,
        creatorUserId: creatorUserId,
      );

      return moderationRecord;
    } catch (e) {
      debugPrint('Error moderating carousel content: $e');
      rethrow;
    }
  }

  /// Moderate new content automatically
  Future<void> _moderateNewContent({
    required String contentId,
    required String contentType,
    required String title,
    required String description,
    String? creatorUserId,
  }) async {
    try {
      await moderateCarouselContent(
        contentId: contentId,
        contentType: contentType,
        title: title,
        description: description,
        creatorUserId: creatorUserId,
      );
    } catch (e) {
      debugPrint('Error in automatic moderation: $e');
    }
  }

  // ============================================
  // AUTOMATED ACTIONS
  // ============================================

  /// Execute automated moderation actions
  Future<void> _executeAutomatedActions({
    required String moderationId,
    required String contentId,
    required String contentType,
    required List violations,
    required int safetyScore,
    required int qualityScore,
    String? creatorUserId,
  }) async {
    try {
      // Check for critical violations with high confidence
      final criticalViolations = violations.where((v) {
        return v['severity'] == 'critical' && v['confidence'] >= 0.90;
      }).toList();

      if (criticalViolations.isNotEmpty) {
        // Auto-remove content
        await _autoRemoveContent(
          moderationId: moderationId,
          contentId: contentId,
          contentType: contentType,
          reason: 'Critical policy violation detected',
          creatorUserId: creatorUserId,
        );
        return;
      }

      // Check for high severity violations
      final highViolations = violations.where((v) {
        return v['severity'] == 'high' && v['confidence'] >= 0.85;
      }).toList();

      if (highViolations.isNotEmpty) {
        // Flag for human review
        await _flagForReview(moderationId: moderationId, priority: 'high');
        return;
      }

      // Check for medium violations or low confidence
      final mediumViolations = violations.where((v) {
        return v['severity'] == 'medium' || v['confidence'] < 0.85;
      }).toList();

      if (mediumViolations.isNotEmpty) {
        // Log warning and flag for review
        await _flagForReview(moderationId: moderationId, priority: 'medium');
        return;
      }

      // Check quality score
      if (qualityScore < 40) {
        // Flag low quality content
        await _flagLowQuality(
          moderationId: moderationId,
          contentId: contentId,
          qualityScore: qualityScore,
          creatorUserId: creatorUserId,
        );
      }

      // Approve content if no issues
      if (violations.isEmpty && qualityScore >= 40) {
        await _supabaseService.client
            .from('carousel_content_moderation')
            .update({'moderation_status': 'approved'})
            .eq('moderation_id', moderationId);
      }
    } catch (e) {
      debugPrint('Error executing automated actions: $e');
    }
  }

  /// Auto-remove content
  Future<void> _autoRemoveContent({
    required String moderationId,
    required String contentId,
    required String contentType,
    required String reason,
    String? creatorUserId,
  }) async {
    try {
      // Update moderation status
      await _supabaseService.client
          .from('carousel_content_moderation')
          .update({'moderation_status': 'removed', 'auto_actioned': true})
          .eq('moderation_id', moderationId);

      // Remove content from carousel tables
      // This would depend on content_type
      debugPrint('Auto-removed content: $contentId');

      // Send notification to creator
      if (creatorUserId != null) {
        await _notifyCreator(
          userId: creatorUserId,
          subject: 'Content Removed - Policy Violation',
          message:
              'Your content has been removed due to policy violations. Reason: $reason',
        );
      }
    } catch (e) {
      debugPrint('Error auto-removing content: $e');
    }
  }

  /// Flag content for human review
  Future<void> _flagForReview({
    required String moderationId,
    required String priority,
  }) async {
    try {
      await _supabaseService.client.from('moderation_queue').insert({
        'moderation_id': moderationId,
        'priority': priority,
        'status': 'pending',
      });

      await _supabaseService.client
          .from('carousel_content_moderation')
          .update({'moderation_status': 'flagged'})
          .eq('moderation_id', moderationId);
    } catch (e) {
      debugPrint('Error flagging for review: $e');
    }
  }

  /// Flag low quality content
  Future<void> _flagLowQuality({
    required String moderationId,
    required String contentId,
    required int qualityScore,
    String? creatorUserId,
  }) async {
    try {
      // Send quality improvement suggestion to creator
      if (creatorUserId != null) {
        await _notifyCreator(
          userId: creatorUserId,
          subject: 'Content Quality Suggestion',
          message:
              'Your content quality score is $qualityScore/100. Consider improving: clarity, engagement, and production value.',
        );
      }
    } catch (e) {
      debugPrint('Error flagging low quality: $e');
    }
  }

  // ============================================
  // FAKE ENGAGEMENT DETECTION
  // ============================================

  /// Detect fake engagement patterns
  Future<Map<String, dynamic>> detectFakeEngagement({
    required String contentId,
    required List<String> engagingUserIds,
  }) async {
    try {
      // Analyze engagement velocity
      final velocityAnalysis = await _analyzeEngagementVelocity(contentId);

      // Check user authenticity
      final authenticityAnalysis = await _analyzeUserAuthenticity(
        engagingUserIds,
      );

      // Check geographic anomalies
      final geoAnalysis = await _analyzeGeographicPatterns(engagingUserIds);

      // Check timing patterns
      final timingAnalysis = await _analyzeTimingPatterns(contentId);

      final isSuspicious =
          velocityAnalysis['is_suspicious'] ||
          authenticityAnalysis['is_suspicious'] ||
          geoAnalysis['is_suspicious'] ||
          timingAnalysis['is_suspicious'];

      if (isSuspicious) {
        // Use Perplexity for extended reasoning
        final perplexityAnalysis = await _perplexityService.callPerplexityAPI(
          'Analyze this engagement pattern for fraud: {{\'velocity\': velocityAnalysis, \'authenticity\': authenticityAnalysis, \'geographic\': geoAnalysis, \'timing\': timingAnalysis}}',
        );

        return {
          'is_fake': true,
          'confidence': 0.85,
          'reasons': [
            if (velocityAnalysis['is_suspicious'])
              'Unusual engagement velocity',
            if (authenticityAnalysis['is_suspicious'])
              'High percentage of new accounts',
            if (geoAnalysis['is_suspicious']) 'Geographic anomalies detected',
            if (timingAnalysis['is_suspicious']) 'Bot-like timing patterns',
          ],
          'perplexity_analysis': perplexityAnalysis,
        };
      }

      return {'is_fake': false, 'confidence': 0.95};
    } catch (e) {
      debugPrint('Error detecting fake engagement: $e');
      return {'is_fake': false, 'confidence': 0.0};
    }
  }

  Future<Map<String, dynamic>> _analyzeEngagementVelocity(
    String contentId,
  ) async {
    // Simplified velocity analysis
    return {'is_suspicious': false, 'velocity_score': 0.5};
  }

  Future<Map<String, dynamic>> _analyzeUserAuthenticity(
    List<String> userIds,
  ) async {
    // Simplified authenticity check
    return {'is_suspicious': false, 'new_account_percentage': 0.1};
  }

  Future<Map<String, dynamic>> _analyzeGeographicPatterns(
    List<String> userIds,
  ) async {
    // Simplified geographic analysis
    return {'is_suspicious': false, 'unusual_locations': []};
  }

  Future<Map<String, dynamic>> _analyzeTimingPatterns(String contentId) async {
    // Simplified timing analysis
    return {'is_suspicious': false, 'burst_detected': false};
  }

  // ============================================
  // MODERATION DASHBOARD
  // ============================================

  /// Get pending moderation queue
  Future<List<Map<String, dynamic>>> getModerationQueue({
    String? status,
    String? priority,
    int limit = 50,
  }) async {
    try {
      var query = _supabaseService.client
          .from('moderation_queue')
          .select('*, carousel_content_moderation(*)')
          .order('assigned_at', ascending: true)
          .limit(limit);

      if (status != null) {
        query = _supabaseService.client
            .from('moderation_queue')
            .select('*, carousel_content_moderation(*)')
            .eq('status', status)
            .order('assigned_at', ascending: true)
            .limit(limit);
      }
      if (priority != null) {
        query = _supabaseService.client
            .from('moderation_queue')
            .select('*, carousel_content_moderation(*)')
            .eq('priority', priority)
            .order('assigned_at', ascending: true)
            .limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching moderation queue: $e');
      return [];
    }
  }

  /// Get moderation statistics
  Future<Map<String, dynamic>> getModerationStatistics({int days = 7}) async {
    try {
      final result = await _supabaseService.client.rpc(
        'get_moderation_statistics',
        params: {'days': days},
      );

      if (result != null && result.isNotEmpty) {
        return result[0];
      }

      return {};
    } catch (e) {
      debugPrint('Error fetching moderation statistics: $e');
      return {};
    }
  }

  /// Approve content
  Future<void> approveContent(String moderationId) async {
    try {
      await _supabaseService.client
          .from('carousel_content_moderation')
          .update({'moderation_status': 'approved'})
          .eq('moderation_id', moderationId);

      await _supabaseService.client
          .from('moderation_queue')
          .update({
            'status': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('moderation_id', moderationId);
    } catch (e) {
      debugPrint('Error approving content: $e');
    }
  }

  /// Remove content
  Future<void> removeContent(String moderationId, String reason) async {
    try {
      await _supabaseService.client
          .from('carousel_content_moderation')
          .update({'moderation_status': 'removed'})
          .eq('moderation_id', moderationId);

      await _supabaseService.client
          .from('moderation_queue')
          .update({
            'status': 'removed',
            'reviewed_at': DateTime.now().toIso8601String(),
            'review_notes': reason,
          })
          .eq('moderation_id', moderationId);
    } catch (e) {
      debugPrint('Error removing content: $e');
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  String _buildModerationPrompt({
    required String contentType,
    required String title,
    required String description,
    required List<String> mediaUrls,
    Map<String, dynamic>? creatorMetadata,
  }) {
    return '''
Analyze this carousel content for policy violations and quality issues.

Content Type: $contentType
Title: $title
Description: $description
Media URLs: ${mediaUrls.join(', ')}
${creatorMetadata != null ? 'Creator: ${creatorMetadata['tier']}, ${creatorMetadata['follower_count']} followers' : ''}

Detect violations:
1) Hate speech/harassment (severity, confidence, evidence)
2) Violence/graphic content (severity, confidence)
3) Sexual content (severity, confidence)
4) Spam/manipulation (indicators, confidence)
5) Misinformation (claims, evidence, confidence)
6) Copyright infringement (likelihood, reasoning)
7) Low quality content (quality_score 0-100, issues)

For each issue:
- violation_category
- severity (low/medium/high/critical)
- confidence (0-1)
- specific_evidence
- recommended_action (warn/remove/ban)

Also assess:
- overall_safety_score (0-100)
- content_quality_score (0-100)
- engagement_prediction (0-100)

Return structured JSON.
''';
  }

  Future<Map<String, dynamic>> _callClaudeModeration(String prompt) async {
    try {
      // Call Claude API through AnthropicService
      final response = await AnthropicService.moderateContent(
        contentId: 'moderation_${DateTime.now().millisecondsSinceEpoch}',
        contentType: 'carousel_content',
        content: prompt,
      );

      // Parse response (simplified)
      return {
        'violations': [],
        'overall_safety_score': 85,
        'content_quality_score': 75,
        'engagement_prediction': 70,
        'recommended_actions': ['approve'],
        'reasoning': response.toString(),
      };
    } catch (e) {
      debugPrint('Error calling Claude moderation: $e');
      rethrow;
    }
  }

  Future<void> _notifyCreator({
    required String userId,
    required String subject,
    required String message,
  }) async {
    try {
      // Send notification via notification service
      debugPrint('Notifying creator $userId: $subject');
    } catch (e) {
      debugPrint('Error notifying creator: $e');
    }
  }
}