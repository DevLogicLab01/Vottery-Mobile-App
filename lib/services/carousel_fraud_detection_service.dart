import 'package:flutter/foundation.dart';

import './perplexity_service.dart';
import './supabase_service.dart';

/// Carousel Fraud Detection Service
/// Implements automated security monitoring for carousel interactions
class CarouselFraudDetectionService {
  static CarouselFraudDetectionService? _instance;
  static CarouselFraudDetectionService get instance =>
      _instance ??= CarouselFraudDetectionService._();

  CarouselFraudDetectionService._();

  final SupabaseService _supabase = SupabaseService.instance;
  final PerplexityService _perplexity = PerplexityService.instance;

  // ============================================
  // BOT BEHAVIOR DETECTION
  // ============================================

  /// Detect bot-like rapid swipes
  Future<Map<String, dynamic>> detectBotBehavior(String userId) async {
    try {
      // Check swipes in last minute
      final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));
      final recentSwipes = await _supabase.client
          .from('carousel_interactions')
          .select('interaction_timestamp, view_duration_seconds')
          .eq('user_id', userId)
          .gte('interaction_timestamp', oneMinuteAgo.toIso8601String())
          .inFilter('interaction_type', ['swipe_left', 'swipe_right']);

      final swipeCount = recentSwipes.length;

      // Flag if > 100 swipes/minute
      if (swipeCount > 100) {
        return {
          'is_bot': true,
          'confidence': 0.95,
          'reason': 'Rapid swipes detected',
          'swipes_per_minute': swipeCount,
          'evidence': {'swipe_count': swipeCount, 'time_window': '1 minute'},
        };
      }

      // Calculate timing consistency
      if (recentSwipes.length >= 10) {
        final timestamps =
            recentSwipes
                .map(
                  (s) => DateTime.parse(s['interaction_timestamp'] as String),
                )
                .toList()
              ..sort();

        final intervals = <double>[];
        for (int i = 1; i < timestamps.length; i++) {
          intervals.add(
            timestamps[i]
                .difference(timestamps[i - 1])
                .inMilliseconds
                .toDouble(),
          );
        }

        final avgInterval =
            intervals.reduce((a, b) => a + b) / intervals.length;
        final variance =
            intervals
                .map((i) => (i - avgInterval) * (i - avgInterval))
                .reduce((a, b) => a + b) /
            intervals.length;
        final stdDev = variance;

        // Flag if stddev < 100ms (too consistent = bot)
        if (stdDev < 100) {
          return {
            'is_bot': true,
            'confidence': 0.85,
            'reason': 'Timing too consistent (automated script)',
            'timing_stddev': stdDev,
            'evidence': {'avg_interval_ms': avgInterval, 'stddev_ms': stdDev},
          };
        }
      }

      // Check view duration
      final avgViewDuration =
          recentSwipes
              .where((s) => s['view_duration_seconds'] != null)
              .map((s) => (s['view_duration_seconds'] as num).toDouble())
              .fold(0.0, (sum, duration) => sum + duration) /
          recentSwipes.length;

      if (avgViewDuration < 0.5) {
        return {
          'is_bot': true,
          'confidence': 0.75,
          'reason': 'No actual content viewing',
          'avg_view_duration': avgViewDuration,
          'evidence': {'avg_view_seconds': avgViewDuration, 'threshold': 0.5},
        };
      }

      return {'is_bot': false, 'confidence': 0.0, 'reason': 'Normal behavior'};
    } catch (e) {
      print('Error detecting bot behavior: $e');
      return {'is_bot': false, 'confidence': 0.0, 'error': e.toString()};
    }
  }

  // ============================================
  // MANIPULATION DETECTION
  // ============================================

  /// Detect coordinated swipes (vote brigading)
  Future<Map<String, dynamic>> detectCoordinatedSwipes(String contentId) async {
    try {
      // Get swipes in last 5 minutes
      final fiveMinutesAgo = DateTime.now().subtract(
        const Duration(minutes: 5),
      );
      final recentSwipes = await _supabase.client
          .from('carousel_interactions')
          .select('user_id, interaction_timestamp, device_fingerprint')
          .eq('item_id', contentId)
          .eq('interaction_type', 'swipe_right')
          .gte('interaction_timestamp', fiveMinutesAgo.toIso8601String());

      if (recentSwipes.length < 10) {
        return {'is_coordinated': false, 'confidence': 0.0};
      }

      // Check for synchronized timing (within 1 second)
      final timestamps =
          recentSwipes
              .map((s) => DateTime.parse(s['interaction_timestamp'] as String))
              .toList()
            ..sort();

      int clusteredSwipes = 0;
      for (int i = 1; i < timestamps.length; i++) {
        if (timestamps[i].difference(timestamps[i - 1]).inSeconds <= 1) {
          clusteredSwipes++;
        }
      }

      final clusterRate = clusteredSwipes / timestamps.length;

      // Check IP clustering
      final uniqueUsers = recentSwipes
          .map((s) => s['user_id'] as String)
          .toSet()
          .length;
      final uniqueDevices = recentSwipes
          .map((s) => s['device_fingerprint'] as String?)
          .where((d) => d != null)
          .toSet()
          .length;

      final deviceUserRatio = uniqueDevices / uniqueUsers;

      if (clusterRate > 0.5 || deviceUserRatio < 0.3) {
        return {
          'is_coordinated': true,
          'confidence': 0.9,
          'reason': 'Synchronized swipes detected',
          'evidence': {
            'cluster_rate': clusterRate,
            'device_user_ratio': deviceUserRatio,
            'unique_users': uniqueUsers,
            'unique_devices': uniqueDevices,
            'total_swipes': recentSwipes.length,
          },
        };
      }

      return {'is_coordinated': false, 'confidence': 0.0};
    } catch (e) {
      print('Error detecting coordinated swipes: $e');
      return {
        'is_coordinated': false,
        'confidence': 0.0,
        'error': e.toString(),
      };
    }
  }

  // ============================================
  // PERPLEXITY THREAT ANALYSIS
  // ============================================

  /// Analyze suspicious activity with Perplexity AI
  Future<Map<String, dynamic>> analyzeWithPerplexity(
    Map<String, dynamic> suspiciousActivity,
  ) async {
    try {
      final prompt =
          '''
Analyze this carousel interaction pattern for fraud:

User Activity:
- Swipe Velocity: ${suspiciousActivity['swipes_per_minute'] ?? 'N/A'}/min
- Timing Consistency: ${suspiciousActivity['timing_stddev'] ?? 'N/A'}ms stddev
- View Duration: ${suspiciousActivity['avg_view_duration'] ?? 'N/A'}s avg
- Devices Used Today: ${suspiciousActivity['device_changes'] ?? 'N/A'}
- Location Changes: ${suspiciousActivity['location_changes'] ?? 'N/A'}

Platform Baseline:
- Normal Swipe Rate: 10/min
- Normal View Duration: 3s
- Normal Devices: 1-2

Detect fraud types:
1. Bot likelihood (0-1)
2. Click fraud
3. Account sharing
4. Manipulation intent

Provide JSON with: fraud_likelihood (0-1), confidence (0-1), threat_types (array), recommended_actions (array), reasoning (string).
''';

      final response = await _perplexity.callPerplexityAPI(
        prompt,
        model: 'sonar-reasoning',
        searchRecencyFilter: 'week',
      );

      final content = response['choices']?[0]?['message']?['content'] as String? ?? '';
      final analysis = _parsePerplexityResponse(content);

      return {
        'fraud_likelihood': analysis['fraud_likelihood'] ?? 0.5,
        'confidence': analysis['confidence'] ?? 0.5,
        'threat_types': analysis['threat_types'] ?? [],
        'recommended_actions': analysis['recommended_actions'] ?? [],
        'reasoning': analysis['reasoning'] ?? content,
        'raw_response': content,
      };
    } catch (e) {
      debugPrint('Error analyzing with Perplexity: $e');
      return {
        'fraud_likelihood': 0.5,
        'confidence': 0.0,
        'error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _parsePerplexityResponse(String response) {
    try {
      // Extract fraud likelihood
      final likelihoodMatch = RegExp(
        r'likelihood[:\s]+(\d+\.?\d*)',
      ).firstMatch(response);
      final fraudLikelihood = likelihoodMatch != null
          ? double.parse(likelihoodMatch.group(1)!)
          : 0.5;

      // Extract confidence
      final confidenceMatch = RegExp(
        r'confidence[:\s]+(\d+\.?\d*)',
      ).firstMatch(response);
      final confidence = confidenceMatch != null
          ? double.parse(confidenceMatch.group(1)!)
          : 0.5;

      // Extract threat types
      final threatTypes = <String>[];
      if (response.toLowerCase().contains('bot')) {
        threatTypes.add('bot_behavior');
      }
      if (response.toLowerCase().contains('click fraud')) {
        threatTypes.add('click_fraud');
      }
      if (response.toLowerCase().contains('account sharing')) {
        threatTypes.add('account_sharing');
      }
      if (response.toLowerCase().contains('manipulation')) {
        threatTypes.add('manipulation');
      }

      // Extract recommended actions
      final actions = <String>[];
      if (response.toLowerCase().contains('rate limit')) {
        actions.add('rate_limiting');
      }
      if (response.toLowerCase().contains('suspend')) {
        actions.add('temporary_suspension');
      }
      if (response.toLowerCase().contains('investigate')) {
        actions.add('manual_investigation');
      }

      return {
        'fraud_likelihood': fraudLikelihood,
        'confidence': confidence,
        'threat_types': threatTypes,
        'recommended_actions': actions,
        'reasoning': response,
      };
    } catch (e) {
      return {
        'fraud_likelihood': 0.5,
        'confidence': 0.0,
        'reasoning': response,
      };
    }
  }

  // ============================================
  // AUTOMATED RESPONSE
  // ============================================

  /// Take automated action based on fraud detection
  Future<void> takeAutomatedAction({
    required String userId,
    required String fraudType,
    required double confidence,
    required Map<String, dynamic> evidence,
  }) async {
    try {
      // Log fraud event
      await _supabase.client.from('carousel_fraud_events').insert({
        'user_id': userId,
        'fraud_type': fraudType,
        'confidence_score': confidence,
        'evidence': evidence,
        'detected_at': DateTime.now().toIso8601String(),
      });

      // Determine action based on confidence
      String action;
      if (confidence >= 0.9) {
        // Critical: Suspend account
        action = 'account_suspension';
        await _suspendAccount(userId, 'Critical fraud detected');
      } else if (confidence >= 0.7) {
        // High: Temporary restriction
        action = 'temporary_restriction';
        await _restrictCarouselAccess(userId, const Duration(hours: 24));
      } else if (confidence >= 0.5) {
        // Medium: Rate limiting
        action = 'rate_limiting';
        await _applyRateLimit(userId, 50);
      } else {
        // Low: Log only
        action = 'log_only';
      }

      // Update fraud event with action
      await _supabase.client
          .from('carousel_fraud_events')
          .update({'action_taken': action})
          .eq('user_id', userId);
    } catch (e) {
      print('Error taking automated action: $e');
    }
  }

  Future<void> _suspendAccount(String userId, String reason) async {
    // Implementation would call user suspension service
    print('Suspending account $userId: $reason');
  }

  Future<void> _restrictCarouselAccess(String userId, Duration duration) async {
    try {
      await _supabase.client.from('user_rate_limits').upsert({
        'user_id': userId,
        'carousel_access_suspended_until': DateTime.now()
            .add(duration)
            .toIso8601String(),
        'restriction_reason': 'Fraud detection',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error restricting carousel access: $e');
    }
  }

  Future<void> _applyRateLimit(String userId, int swipesPerHour) async {
    try {
      await _supabase.client.from('user_rate_limits').upsert({
        'user_id': userId,
        'carousel_swipes_per_hour': swipesPerHour,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error applying rate limit: $e');
    }
  }

  // ============================================
  // COMPREHENSIVE FRAUD CHECK
  // ============================================

  /// Run comprehensive fraud check on user
  Future<Map<String, dynamic>> runComprehensiveFraudCheck(String userId) async {
    try {
      // Run all detection methods
      final botCheck = await detectBotBehavior(userId);

      // Aggregate results
      final suspiciousActivity = {...botCheck, 'user_id': userId};

      // Analyze with Perplexity if suspicious
      Map<String, dynamic>? perplexityAnalysis;
      if (botCheck['is_bot'] == true || ((botCheck['confidence'] as num?) ?? 0) >= 0.5) {
        perplexityAnalysis = await analyzeWithPerplexity(suspiciousActivity);
      }

      // Determine overall fraud likelihood
      final overallLikelihood = (botCheck['confidence'] ?? 0.0);

      // Take action if needed
      if (overallLikelihood >= 0.5) {
        await takeAutomatedAction(
          userId: userId,
          fraudType: botCheck['is_bot'] == true
              ? 'bot_behavior'
              : 'suspicious_activity',
          confidence: overallLikelihood,
          evidence: suspiciousActivity,
        );
      }

      return {
        'user_id': userId,
        'fraud_detected': overallLikelihood >= 0.5,
        'fraud_likelihood': overallLikelihood,
        'bot_check': botCheck,
        'perplexity_analysis': perplexityAnalysis,
        'checked_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error running comprehensive fraud check: $e');
      return {
        'user_id': userId,
        'fraud_detected': false,
        'error': e.toString(),
      };
    }
  }
}