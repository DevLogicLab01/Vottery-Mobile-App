import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service for Google Analytics event tracking
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Track vote submission
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

  /// Track quest completion
  Future<void> trackQuestCompletion({
    required String questId,
    required String questType,
    required int vpReward,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'quest_completion',
        parameters: {
          'quest_id': questId,
          'quest_type': questType,
          'vp_reward': vpReward,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track quest completion error: $e');
    }
  }

  /// Track fraud alert
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

  /// Track VP purchase
  Future<void> trackVPPurchase({
    required int vpAmount,
    required double priceUsd,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'vp_purchase',
        parameters: {
          'vp_amount': vpAmount,
          'price_usd': priceUsd,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Track VP purchase error: $e');
    }
  }

  /// Track user engagement
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

  /// Set user properties
  Future<void> setUserProperties({
    required String userId,
    String? userTier,
    int? vpBalance,
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
    } catch (e) {
      debugPrint('Set user properties error: $e');
    }
  }
}
