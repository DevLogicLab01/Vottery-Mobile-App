import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Enhanced Analytics Service with comprehensive tracking
/// Tracks user engagement, AI feature adoption, consensus analysis usage
class EnhancedAnalyticsService {
  static EnhancedAnalyticsService? _instance;
  static EnhancedAnalyticsService get instance =>
      _instance ??= EnhancedAnalyticsService._();
  EnhancedAnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ============================================================
  // VOTE PARTICIPATION TRACKING
  // ============================================================

  Future<void> trackVoteParticipation({
    required String electionId,
    required String electionTitle,
    required String category,
    required String votingMethod,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'vote_participation',
        parameters: {
          'election_id': electionId,
          'election_title': electionTitle,
          'category': category,
          'voting_method': votingMethod,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track vote participation error: $e');
    }
  }

  Future<void> trackVoteSubmission({
    required String electionId,
    required String electionTitle,
    required String category,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'vote_submission',
        parameters: {
          'election_id': electionId,
          'election_title': electionTitle,
          'category': category,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track vote submission error: $e');
    }
  }

  // ============================================================
  // QUEST COMPLETION TRACKING
  // ============================================================

  Future<void> trackQuestCompletion({
    required String questId,
    required String questType,
    required int vpReward,
    required String difficulty,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'quest_completion',
        parameters: {
          'quest_id': questId,
          'quest_type': questType,
          'vp_reward': vpReward,
          'difficulty': difficulty,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track quest completion error: $e');
    }
  }

  Future<void> trackQuestStart({
    required String questId,
    required String questType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'quest_start',
        parameters: {
          'quest_id': questId,
          'quest_type': questType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track quest start error: $e');
    }
  }

  // ============================================================
  // VP EARNING TRACKING
  // ============================================================

  Future<void> trackVPEarning({
    required String source,
    required int amount,
    required String action,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'vp_earning',
        parameters: {
          'source': source,
          'amount': amount,
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track VP earning error: $e');
    }
  }

  Future<void> trackVPSpending({
    required String category,
    required int amount,
    required String item,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'vp_spending',
        parameters: {
          'category': category,
          'amount': amount,
          'item': item,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track VP spending error: $e');
    }
  }

  // ============================================================
  // AI FEATURE ADOPTION TRACKING
  // ============================================================

  Future<void> trackAIFeatureUsage({
    required String featureName,
    required String aiProvider,
    required String action,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ai_feature_usage',
        parameters: {
          'feature_name': featureName,
          'ai_provider': aiProvider,
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track AI feature usage error: $e');
    }
  }

  Future<void> trackConsensusAnalysisUsage({
    required String analysisType,
    required List<String> providers,
    required double confidence,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'consensus_analysis_usage',
        parameters: {
          'analysis_type': analysisType,
          'providers': providers.join(','),
          'confidence': confidence,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track consensus analysis usage error: $e');
    }
  }

  Future<void> trackAIQuestGeneration({
    required String questType,
    required String difficulty,
    required String aiProvider,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ai_quest_generation',
        parameters: {
          'quest_type': questType,
          'difficulty': difficulty,
          'ai_provider': aiProvider,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track AI quest generation error: $e');
    }
  }

  // ============================================================
  // SOCIAL INTERACTION TRACKING
  // ============================================================

  Future<void> trackSocialInteraction({
    required String interactionType,
    required String contentType,
    required String contentId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'social_interaction',
        parameters: {
          'interaction_type': interactionType,
          'content_type': contentType,
          'content_id': contentId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track social interaction error: $e');
    }
  }

  Future<void> trackPostCreation({
    required String postType,
    required bool hasMedia,
    required int hashtagCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'post_creation',
        parameters: {
          'post_type': postType,
          'has_media': hasMedia,
          'hashtag_count': hashtagCount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track post creation error: $e');
    }
  }

  // ============================================================
  // SCREEN VIEW TRACKING
  // ============================================================

  Future<void> trackScreenView({
    required String screenName,
    required String screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Track screen view error: $e');
    }
  }

  // ============================================================
  // USER ENGAGEMENT TRACKING
  // ============================================================

  Future<void> trackUserEngagement({
    required String action,
    required String screen,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'user_engagement',
        parameters: {
          'action': action,
          'screen': screen,
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalParams,
        },
      );
    } catch (e) {
      debugPrint('Track user engagement error: $e');
    }
  }

  // ============================================================
  // SESSION ANALYTICS
  // ============================================================

  Future<void> trackSessionStart() async {
    try {
      await _analytics.logEvent(
        name: 'session_start',
        parameters: {'timestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      debugPrint('Track session start error: $e');
    }
  }

  Future<void> trackSessionEnd({required Duration sessionDuration}) async {
    try {
      await _analytics.logEvent(
        name: 'session_end',
        parameters: {
          'duration_seconds': sessionDuration.inSeconds,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track session end error: $e');
    }
  }

  // ============================================================
  // USER PROPERTIES
  // ============================================================

  Future<void> setUserProperties({
    required String userId,
    String? userTier,
    int? vpBalance,
    int? questsCompleted,
  }) async {
    try {
      await _analytics.setUserId(id: userId);
      if (userTier != null) {
        await _analytics.setUserProperty(name: 'user_tier', value: userTier);
      }
      if (vpBalance != null) {
        await _analytics.setUserProperty(
          name: 'vp_balance',
          value: vpBalance.toString(),
        );
      }
      if (questsCompleted != null) {
        await _analytics.setUserProperty(
          name: 'quests_completed',
          value: questsCompleted.toString(),
        );
      }
    } catch (e) {
      debugPrint('Set user properties error: $e');
    }
  }

  // ============================================================
  // FRAUD & SECURITY TRACKING
  // ============================================================

  Future<void> trackFraudAlert({
    required String alertType,
    required double fraudScore,
    required String severity,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'fraud_alert',
        parameters: {
          'alert_type': alertType,
          'fraud_score': fraudScore,
          'severity': severity,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track fraud alert error: $e');
    }
  }
}
