import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import './ga4_analytics_service.dart';
import './supabase_service.dart';
import './auth_service.dart';

/// Comprehensive Analytics Service
/// Extends GA4 with cohort analysis, A/B testing, and revenue attribution
class ComprehensiveAnalyticsService {
  static ComprehensiveAnalyticsService? _instance;
  static ComprehensiveAnalyticsService get instance =>
      _instance ??= ComprehensiveAnalyticsService._();

  ComprehensiveAnalyticsService._();

  final GA4AnalyticsService _ga4 = GA4AnalyticsService.instance;
  final AuthService _auth = AuthService.instance;
  final Uuid _uuid = const Uuid();

  String? _currentScreenName;
  DateTime? _screenStartTime;
  String? _abTestVariant;
  String? _sessionId; // Add this line to track session ID

  /// Track screen view with comprehensive metrics
  Future<void> trackScreenView({
    required String screenName,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      // End previous screen session
      if (_currentScreenName != null && _screenStartTime != null) {
        final timeSpent = DateTime.now()
            .difference(_screenStartTime!)
            .inSeconds;
        await _trackScreenExit(
          screenName: _currentScreenName!,
          timeSpent: timeSpent,
        );
      }

      // Start new screen session
      _currentScreenName = screenName;
      _screenStartTime = DateTime.now();
      _sessionId ??= _uuid
          .v4(); // Add this line to generate session ID if not exists

      // Track in GA4
      await _ga4.trackScreenView(screenName: screenName);

      // Store in Supabase for cohort analysis
      await SupabaseService.instance.client.from('screen_analytics').insert({
        'user_id': _auth.currentUser?.id,
        'screen_name': screenName,
        'session_id': _sessionId, // Changed from _ga4.sessionId to _sessionId
        'ab_test_variant': _abTestVariant,
        'viewed_at': DateTime.now().toIso8601String(),
        ...?additionalParams,
      });
    } catch (e) {
      debugPrint('Track screen view error: $e');
    }
  }

  /// Track screen exit with time spent
  Future<void> _trackScreenExit({
    required String screenName,
    required int timeSpent,
  }) async {
    try {
      await SupabaseService.instance.client
          .from('screen_analytics')
          .update({
            'time_spent_seconds': timeSpent,
            'exited_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', _auth.currentUser!.id)
          .eq('screen_name', screenName)
          .order('viewed_at', ascending: false)
          .limit(1);
    } catch (e) {
      debugPrint('Track screen exit error: $e');
    }
  }

  /// Track user action with conversion funnel
  Future<void> trackUserAction({
    required String actionName,
    required String category,
    String? funnelStep,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      // Remove trackEvent call - method doesn't exist in GA4AnalyticsService
      // await _ga4.trackEvent(
      //   eventName: actionName,
      //   eventType: category,
      //   params: {
      //     'screen_name': _currentScreenName,
      //     'funnel_step': funnelStep,
      //     ...?additionalParams,
      //   },
      // );

      // Track conversion funnel
      if (funnelStep != null) {
        await _trackConversionFunnel(funnelName: category, step: funnelStep);
      }
    } catch (e) {
      debugPrint('Track user action error: $e');
    }
  }

  /// Track conversion funnel step
  Future<void> _trackConversionFunnel({
    required String funnelName,
    required String step,
  }) async {
    try {
      await SupabaseService.instance.client.from('conversion_funnels').insert({
        'user_id': _auth.currentUser?.id,
        'funnel_name': funnelName,
        'step': step,
        'screen_name': _currentScreenName,
        'ab_test_variant': _abTestVariant,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Track conversion funnel error: $e');
    }
  }

  /// Assign user to A/B test variant
  Future<String> assignABTestVariant({
    required String testName,
    required List<String> variants,
  }) async {
    try {
      // Check if user already has variant
      final existing = await SupabaseService.instance.client
          .from('ab_test_assignments')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .eq('test_name', testName)
          .maybeSingle();

      if (existing != null) {
        _abTestVariant = existing['variant'];
        return existing['variant'];
      }

      // Assign random variant
      final variant =
          variants[DateTime.now().millisecondsSinceEpoch % variants.length];

      await SupabaseService.instance.client.from('ab_test_assignments').insert({
        'user_id': _auth.currentUser!.id,
        'test_name': testName,
        'variant': variant,
        'assigned_at': DateTime.now().toIso8601String(),
      });

      _abTestVariant = variant;
      return variant;
    } catch (e) {
      debugPrint('Assign A/B test variant error: $e');
      return variants[0]; // Default to first variant
    }
  }

  /// Track revenue attribution
  Future<void> trackRevenueAttribution({
    required String featureName,
    required double amount,
    required String currency,
    String? transactionId,
  }) async {
    try {
      await SupabaseService.instance.client.from('revenue_attribution').insert({
        'user_id': _auth.currentUser?.id,
        'feature_name': featureName,
        'screen_name': _currentScreenName,
        'amount': amount,
        'currency': currency,
        'transaction_id': transactionId,
        'ab_test_variant': _abTestVariant,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Remove trackPurchase call - method doesn't exist in GA4AnalyticsService
      // await _ga4.trackPurchase(
      //   transactionId: transactionId ?? _uuid.v4(),
      //   value: amount,
      //   currency: currency,
      //   items: [
      //     {'item_name': featureName, 'price': amount},
      //   ],
      // );
    } catch (e) {
      debugPrint('Track revenue attribution error: $e');
    }
  }

  /// Get cohort analysis data
  Future<List<Map<String, dynamic>>> getCohortAnalysis({
    required String
    cohortType, // 'signup_date', 'acquisition_channel', 'behavior'
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await SupabaseService.instance.client.rpc(
        'get_cohort_analysis',
        params: {
          'p_cohort_type': cohortType,
          'p_start_date': startDate,
          'p_end_date': endDate,
        },
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get cohort analysis error: $e');
      return [];
    }
  }

  /// Get A/B test performance
  Future<Map<String, dynamic>> getABTestPerformance(String testName) async {
    try {
      final response = await SupabaseService.instance.client.rpc(
        'get_ab_test_performance',
        params: {'p_test_name': testName},
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Get A/B test performance error: $e');
      return {};
    }
  }

  /// Get feature adoption rates
  Future<List<Map<String, dynamic>>> getFeatureAdoptionRates() async {
    try {
      final response = await SupabaseService.instance.client.rpc(
        'get_feature_adoption_rates',
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get feature adoption rates error: $e');
      return [];
    }
  }

  /// Get screen analytics summary
  Future<Map<String, dynamic>> getScreenAnalyticsSummary(
    String screenName,
  ) async {
    try {
      final response = await SupabaseService.instance.client.rpc(
        'get_screen_analytics_summary',
        params: {'p_screen_name': screenName},
      );

      return response ?? {};
    } catch (e) {
      debugPrint('Get screen analytics summary error: $e');
      return {};
    }
  }

  /// Get user journey visualization
  Future<List<Map<String, dynamic>>> getUserJourneyVisualization(
    String userId,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('screen_analytics')
          .select()
          .eq('user_id', userId)
          .order('viewed_at', ascending: true)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user journey visualization error: $e');
      return [];
    }
  }

  /// Get revenue attribution model
  Future<List<Map<String, dynamic>>> getRevenueAttributionModel() async {
    try {
      final response = await SupabaseService.instance.client.rpc(
        'get_revenue_attribution_model',
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get revenue attribution model error: $e');
      return [];
    }
  }
}
