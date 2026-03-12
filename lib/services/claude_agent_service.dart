import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './claude_service.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './fraud_detection_service.dart';
import './enhanced_analytics_service.dart';
import './ai_feature_adoption_analytics_service.dart';

class ClaudeAgentService {
  static ClaudeAgentService? _instance;
  static ClaudeAgentService get instance =>
      _instance ??= ClaudeAgentService._();

  ClaudeAgentService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  ClaudeService get _claude => ClaudeService.instance;
  FraudDetectionService get _fraudService => FraudDetectionService.instance;
  EnhancedAnalyticsService get _analytics => EnhancedAnalyticsService.instance;

  /// Get confidence thresholds for action types
  Future<Map<String, dynamic>> getConfidenceThresholds() async {
    try {
      final response = await _client
          .from('claude_confidence_thresholds')
          .select();

      final thresholds = <String, Map<String, double>>{};
      for (var threshold in response) {
        thresholds[threshold['action_type']] = {
          'automation_threshold': (threshold['automation_threshold'] as num)
              .toDouble(),
          'review_threshold': (threshold['review_threshold'] as num).toDouble(),
        };
      }

      return thresholds;
    } catch (e) {
      debugPrint('Get confidence thresholds error: $e');
      return {
        'fraud_response': {
          'automation_threshold': 90.0,
          'review_threshold': 70.0,
        },
        'content_moderation': {
          'automation_threshold': 95.0,
          'review_threshold': 70.0,
        },
        'winner_verification': {
          'automation_threshold': 90.0,
          'review_threshold': 75.0,
        },
      };
    }
  }

  /// Update confidence threshold
  Future<bool> updateConfidenceThreshold({
    required String actionType,
    required double automationThreshold,
    required double reviewThreshold,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('claude_confidence_thresholds')
          .update({
            'automation_threshold': automationThreshold,
            'review_threshold': reviewThreshold,
            'updated_at': DateTime.now().toIso8601String(),
            'updated_by': _auth.currentUser!.id,
          })
          .eq('action_type', actionType);

      return true;
    } catch (e) {
      debugPrint('Update confidence threshold error: $e');
      return false;
    }
  }

  /// Autonomous fraud response workflow
  Future<Map<String, dynamic>> handleFraudResponse({
    required String voteId,
    required Map<String, dynamic> fraudData,
  }) async {
    try {
      final fraudScore = fraudData['fraud_score'] as double? ?? 0.0;
      final thresholds = await getConfidenceThresholds();
      final fraudThreshold =
          thresholds['fraud_response']?['automation_threshold'] ?? 90.0;
      final reviewThreshold =
          thresholds['fraud_response']?['review_threshold'] ?? 70.0;

      // Analyze with Claude
      final claudeAnalysis = await _claude.analyzeSecurityIncident(
        incidentData: {
          'incident_type': 'vote_fraud',
          'vote_id': voteId,
          'fraud_score': fraudScore,
          ...fraudData,
        },
      );

      final confidence =
          (claudeAnalysis['confidence_score'] as num?)?.toDouble() ?? 0.0;
      final recommendedAction =
          claudeAnalysis['recommended_action'] ?? 'manual_review';
      final reasoning =
          claudeAnalysis['reasoning'] ?? 'Claude security analysis';

      // Determine if automated action should be taken
      final automated = confidence >= fraudThreshold;
      final requiresReview =
          confidence >= reviewThreshold && confidence < fraudThreshold;

      String actionTaken = 'no_action';
      if (automated) {
        // Execute automated actions
        if (fraudScore >= 95) {
          await _flagTransactionAndFreezeAccount(voteId, fraudData);
          actionTaken = 'account_frozen';
        } else if (fraudScore >= 90) {
          await _flagTransaction(voteId);
          actionTaken = 'transaction_flagged';
        } else {
          await _notifySecurityTeam(voteId, fraudData);
          actionTaken = 'security_notified';
        }
      }

      // Log autonomous action
      await _logAutonomousAction(
        actionType: 'fraud_response',
        targetId: voteId,
        targetType: 'vote',
        actionTaken: actionTaken,
        confidenceScore: confidence,
        reasoning: reasoning,
        automated: automated,
        requiresReview: requiresReview,
      );

      return {
        'vote_id': voteId,
        'action_taken': actionTaken,
        'confidence': confidence,
        'automated': automated,
        'requires_review': requiresReview,
        'reasoning': reasoning,
      };
    } catch (e) {
      debugPrint('Handle fraud response error: $e');
      return {
        'vote_id': voteId,
        'action_taken': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Content moderation escalation workflow
  Future<Map<String, dynamic>> handleContentModeration({
    required String contentId,
    required String contentType,
    required String contentText,
  }) async {
    try {
      final thresholds = await getConfidenceThresholds();
      final moderationThreshold =
          thresholds['content_moderation']?['automation_threshold'] ?? 95.0;
      final reviewThreshold =
          thresholds['content_moderation']?['review_threshold'] ?? 70.0;

      // Analyze with Claude
      final claudeAnalysis = await _claude.moderateContent(
        content: contentText,
        contentType: contentType,
      );

      final confidence =
          (claudeAnalysis['confidence'] as num?)?.toDouble() ?? 0.0;
      final decision = claudeAnalysis['decision'] ?? 'approved';
      final violations = List<String>.from(claudeAnalysis['violations'] ?? []);
      final reasoning =
          claudeAnalysis['reasoning'] ?? 'Claude content analysis';

      // Determine action
      final automated = confidence >= moderationThreshold;
      final requiresReview =
          confidence >= reviewThreshold && confidence < moderationThreshold;

      String actionTaken = 'approved';
      if (automated && decision == 'rejected') {
        await _removeContent(contentId, contentType);
        await _notifyUser(contentId, violations);
        actionTaken = 'content_removed';
      } else if (requiresReview) {
        await _addToModerationQueue(
          contentId: contentId,
          contentType: contentType,
          contentText: contentText,
          claudeAnalysis: claudeAnalysis,
          confidenceScore: confidence,
          violations: violations,
        );
        actionTaken = 'queued_for_review';
      }

      // Log autonomous action
      await _logAutonomousAction(
        actionType: 'content_moderation',
        targetId: contentId,
        targetType: contentType,
        actionTaken: actionTaken,
        confidenceScore: confidence,
        reasoning: reasoning,
        automated: automated,
        requiresReview: requiresReview,
      );

      return {
        'content_id': contentId,
        'action_taken': actionTaken,
        'confidence': confidence,
        'automated': automated,
        'requires_review': requiresReview,
        'violations': violations,
        'reasoning': reasoning,
      };
    } catch (e) {
      debugPrint('Handle content moderation error: $e');
      return {
        'content_id': contentId,
        'action_taken': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Autonomous content moderation workflow
  Future<Map<String, dynamic>> moderateContent({
    required String contentId,
    required String contentType,
    required String content,
    String? userId,
  }) async {
    try {
      final claudeAnalysis = await _claude.moderateContent(
        content: content,
        contentType: contentType,
      );

      final confidence =
          (claudeAnalysis['confidence_score'] as num?)?.toDouble() ?? 0.0;
      final action = claudeAnalysis['action'] as String? ?? 'approved';

      // Store moderation result
      await _client.from('content_moderation_log').insert({
        'content_id': contentId,
        'content_type': contentType,
        'moderation_action': action,
        'confidence_score': confidence,
        'moderator': 'claude_ai',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Fire GA4 ai_content_moderation event
      await AIFeatureAdoptionAnalyticsService.instance.logAIContentModeration(
        contentType: contentType,
        moderationAction: action,
        confidenceScore: confidence,
        userId: userId,
      );

      return claudeAnalysis;
    } catch (e) {
      debugPrint('Moderate content error: $e');
      return {'action': 'approved', 'confidence_score': 0.0};
    }
  }

  /// Winner verification workflow
  Future<Map<String, dynamic>> handleWinnerVerification({
    required String winnerId,
    required String electionId,
    required Map<String, dynamic> winnerData,
  }) async {
    try {
      final thresholds = await getConfidenceThresholds();
      final verificationThreshold =
          thresholds['winner_verification']?['automation_threshold'] ?? 90.0;
      final reviewThreshold =
          thresholds['winner_verification']?['review_threshold'] ?? 75.0;

      // Check eligibility criteria
      final eligibilityChecks = await _performEligibilityChecks(
        winnerId,
        winnerData,
      );

      // Analyze with Claude
      final claudeAnalysis = await _claude.analyzeSecurityIncident(
        incidentData: {
          'incident_type': 'winner_verification',
          'winner_id': winnerId,
          'election_id': electionId,
          'eligibility_checks': eligibilityChecks,
          ...winnerData,
        },
      );

      final confidence =
          (claudeAnalysis['confidence_score'] as num?)?.toDouble() ?? 0.0;
      final reasoning =
          claudeAnalysis['reasoning'] ?? 'Claude verification analysis';

      // Determine action
      final automated = confidence >= verificationThreshold;
      final requiresReview =
          confidence >= reviewThreshold && confidence < verificationThreshold;

      String actionTaken = 'pending';
      if (automated && eligibilityChecks['all_passed'] == true) {
        await _approveWinner(winnerId, electionId);
        actionTaken = 'winner_approved';
      } else if (requiresReview || eligibilityChecks['all_passed'] == false) {
        await _flagForManualReview(winnerId, electionId, eligibilityChecks);
        actionTaken = 'flagged_for_review';
      }

      // Log autonomous action
      await _logAutonomousAction(
        actionType: 'winner_verification',
        targetId: winnerId,
        targetType: 'winner',
        actionTaken: actionTaken,
        confidenceScore: confidence,
        reasoning: reasoning,
        automated: automated,
        requiresReview: requiresReview,
      );

      return {
        'winner_id': winnerId,
        'action_taken': actionTaken,
        'confidence': confidence,
        'automated': automated,
        'requires_review': requiresReview,
        'eligibility_checks': eligibilityChecks,
        'reasoning': reasoning,
      };
    } catch (e) {
      debugPrint('Handle winner verification error: $e');
      return {
        'winner_id': winnerId,
        'action_taken': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Get autonomous actions history
  Future<List<Map<String, dynamic>>> getAutonomousActions({
    String? actionType,
    bool? requiresReview,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('claude_autonomous_actions').select();

      if (actionType != null) {
        query = query.eq('action_type', actionType);
      }

      if (requiresReview != null) {
        query = query.eq('requires_review', requiresReview);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get autonomous actions error: $e');
      return [];
    }
  }

  /// Get moderation queue
  Future<List<Map<String, dynamic>>> getModerationQueue({
    String? status,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('claude_moderation_queue').select();

      if (status != null) {
        query = query.eq('status', status);
      } else {
        query = query.eq('status', 'pending');
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get moderation queue error: $e');
      return [];
    }
  }

  /// Review moderation queue item
  Future<bool> reviewModerationItem({
    required String itemId,
    required String decision,
    String? feedback,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('claude_moderation_queue')
          .update({
            'status': decision,
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': _auth.currentUser!.id,
            'moderator_feedback': feedback,
          })
          .eq('id', itemId);

      return true;
    } catch (e) {
      debugPrint('Review moderation item error: $e');
      return false;
    }
  }

  /// Override autonomous action
  Future<bool> overrideAutonomousAction({
    required String actionId,
    required String overrideAction,
    required String overrideReason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('claude_autonomous_actions')
          .update({
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': _auth.currentUser!.id,
            'override_action': overrideAction,
            'override_reason': overrideReason,
          })
          .eq('id', actionId);

      return true;
    } catch (e) {
      debugPrint('Override autonomous action error: $e');
      return false;
    }
  }

  /// Get autonomous action metrics
  Future<Map<String, dynamic>> getAutonomousActionMetrics() async {
    try {
      final response = await _client
          .from('claude_autonomous_actions')
          .select()
          .gte(
            'created_at',
            DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          );

      final actions = List<Map<String, dynamic>>.from(response);

      final totalActions = actions.length;
      final automatedActions = actions
          .where((a) => a['automated'] == true)
          .length;
      final reviewActions = actions
          .where((a) => a['requires_review'] == true)
          .length;
      final overriddenActions = actions
          .where((a) => a['override_action'] != null)
          .length;

      final avgConfidence = actions.isEmpty
          ? 0.0
          : actions
                    .map((a) => (a['confidence_score'] as num).toDouble())
                    .reduce((a, b) => a + b) /
                actions.length;

      return {
        'total_actions': totalActions,
        'automated_actions': automatedActions,
        'review_actions': reviewActions,
        'overridden_actions': overriddenActions,
        'automation_rate': totalActions > 0
            ? automatedActions / totalActions
            : 0.0,
        'override_rate': automatedActions > 0
            ? overriddenActions / automatedActions
            : 0.0,
        'average_confidence': avgConfidence,
      };
    } catch (e) {
      debugPrint('Get autonomous action metrics error: $e');
      return {};
    }
  }

  // Private helper methods

  Future<void> _logAutonomousAction({
    required String actionType,
    required String targetId,
    required String targetType,
    required String actionTaken,
    required double confidenceScore,
    required String reasoning,
    required bool automated,
    required bool requiresReview,
  }) async {
    try {
      await _client.from('claude_autonomous_actions').insert({
        'action_type': actionType,
        'target_id': targetId,
        'target_type': targetType,
        'action_taken': actionTaken,
        'confidence_score': confidenceScore,
        'reasoning': reasoning,
        'automated': automated,
        'requires_review': requiresReview,
      });
    } catch (e) {
      debugPrint('Log autonomous action error: $e');
    }
  }

  Future<void> _flagTransactionAndFreezeAccount(
    String voteId,
    Map<String, dynamic> fraudData,
  ) async {
    try {
      await _client
          .from('votes')
          .update({'status': 'flagged'})
          .eq('id', voteId);

      final userId = fraudData['user_id'];
      if (userId != null) {
        await _client
            .from('user_profiles')
            .update({'account_status': 'frozen'})
            .eq('id', userId);
      }
    } catch (e) {
      debugPrint('Flag transaction and freeze account error: $e');
    }
  }

  Future<void> _flagTransaction(String voteId) async {
    try {
      await _client
          .from('votes')
          .update({'status': 'flagged'})
          .eq('id', voteId);
    } catch (e) {
      debugPrint('Flag transaction error: $e');
    }
  }

  Future<void> _notifySecurityTeam(
    String voteId,
    Map<String, dynamic> fraudData,
  ) async {
    try {
      await _client.from('security_alerts').insert({
        'alert_type': 'fraud_detection',
        'target_id': voteId,
        'alert_data': fraudData,
        'severity': 'high',
      });
    } catch (e) {
      debugPrint('Notify security team error: $e');
    }
  }

  Future<void> _removeContent(String contentId, String contentType) async {
    try {
      final table = contentType == 'post'
          ? 'social_posts'
          : 'election_comments';
      await _client
          .from(table)
          .update({'status': 'removed'})
          .eq('id', contentId);
    } catch (e) {
      debugPrint('Remove content error: $e');
    }
  }

  Future<void> _notifyUser(String contentId, List<String> violations) async {
    try {
      // Notification would be sent via notification service
      debugPrint(
        'User notified about content removal: $contentId, violations: $violations',
      );
    } catch (e) {
      debugPrint('Notify user error: $e');
    }
  }

  Future<void> _addToModerationQueue({
    required String contentId,
    required String contentType,
    required String contentText,
    required Map<String, dynamic> claudeAnalysis,
    required double confidenceScore,
    required List<String> violations,
  }) async {
    try {
      await _client.from('claude_moderation_queue').insert({
        'content_id': contentId,
        'content_type': contentType,
        'content_text': contentText,
        'claude_analysis': claudeAnalysis,
        'confidence_score': confidenceScore,
        'flagged_violations': violations,
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('Add to moderation queue error: $e');
    }
  }

  Future<Map<String, dynamic>> _performEligibilityChecks(
    String winnerId,
    Map<String, dynamic> winnerData,
  ) async {
    try {
      final userProfile = await _client
          .from('user_profiles')
          .select()
          .eq('id', winnerId)
          .maybeSingle();

      if (userProfile == null) {
        return {'all_passed': false, 'reason': 'User profile not found'};
      }

      final accountAge = DateTime.now()
          .difference(DateTime.parse(userProfile['created_at']))
          .inDays;
      final emailVerified = userProfile['email_verified'] ?? false;
      final fraudHistory = await _fraudService.getFraudHistory(limit: 10);
      final hasFraudHistory = fraudHistory.any((f) => f['user_id'] == winnerId);

      final checks = {
        'account_age_check': accountAge >= 30,
        'email_verified': emailVerified,
        'no_fraud_history': !hasFraudHistory,
        'account_age_days': accountAge,
      };

      checks['all_passed'] =
          checks['account_age_check'] == true &&
          checks['email_verified'] == true &&
          checks['no_fraud_history'] == true;

      return checks;
    } catch (e) {
      debugPrint('Perform eligibility checks error: $e');
      return {'all_passed': false, 'error': e.toString()};
    }
  }

  Future<void> _approveWinner(String winnerId, String electionId) async {
    try {
      await _client
          .from('lottery_winners')
          .update({
            'verification_status': 'approved',
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', winnerId)
          .eq('election_id', electionId);
    } catch (e) {
      debugPrint('Approve winner error: $e');
    }
  }

  Future<void> _flagForManualReview(
    String winnerId,
    String electionId,
    Map<String, dynamic> checks,
  ) async {
    try {
      await _client
          .from('lottery_winners')
          .update({
            'verification_status': 'pending_review',
            'verification_notes': checks.toString(),
          })
          .eq('user_id', winnerId)
          .eq('election_id', electionId);
    } catch (e) {
      debugPrint('Flag for manual review error: $e');
    }
  }
}
