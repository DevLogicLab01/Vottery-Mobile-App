import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

// Platform-specific imports

// Conditional import for google_mobile_ads (only on mobile)
class AdSenseService {
  static AdSenseService? _instance;
  static AdSenseService get instance => _instance ??= AdSenseService._();

  AdSenseService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // Ad frequency tracking
  final Map<String, int> _sessionAdCount = {};
  final Map<String, DateTime> _lastInterstitialTime = {};

  // Ad configuration
  static const int maxAdsPerSession = 3;
  static const Duration interstitialCooldown = Duration(minutes: 5);

  /// Initialize AdSense (mobile-only)
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('AdSense: Web platform - using fallback');
      return;
    }

    try {
      // Mobile initialization would go here
      debugPrint('AdSense: Initialized for mobile');
    } catch (e) {
      debugPrint('AdSense initialization error: $e');
    }
  }

  /// Check if user can see ads (frequency capping)
  bool canShowAd(String adType) {
    final userId = _auth.currentUser?.id ?? 'anonymous';
    final sessionKey = '$userId-$adType';

    // Check session limit
    final count = _sessionAdCount[sessionKey] ?? 0;
    if (count >= maxAdsPerSession) {
      return false;
    }

    // Check interstitial cooldown
    if (adType == 'interstitial') {
      final lastTime = _lastInterstitialTime[userId];
      if (lastTime != null) {
        final elapsed = DateTime.now().difference(lastTime);
        if (elapsed < interstitialCooldown) {
          return false;
        }
      }
    }

    return true;
  }

  /// Track ad impression
  Future<void> trackAdImpression({
    required String adType,
    required String placement,
    String? adUnitId,
  }) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;

    final sessionKey = '$userId-$adType';
    _sessionAdCount[sessionKey] = (_sessionAdCount[sessionKey] ?? 0) + 1;

    if (adType == 'interstitial') {
      _lastInterstitialTime[userId] = DateTime.now();
    }

    try {
      await _client.from('ad_impressions').insert({
        'user_id': userId,
        'ad_type': adType,
        'placement': placement,
        'ad_unit_id': adUnitId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Track ad impression error: $e');
    }
  }

  /// Track ad click
  Future<void> trackAdClick({
    required String adType,
    required String placement,
    String? adUnitId,
  }) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('ad_clicks').insert({
        'user_id': userId,
        'ad_type': adType,
        'placement': placement,
        'ad_unit_id': adUnitId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Track ad click error: $e');
    }
  }

  /// Get revenue analytics
  Future<Map<String, dynamic>> getRevenueAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _client.rpc(
        'get_ad_revenue_analytics',
        params: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );

      return response ?? _getDefaultAnalytics();
    } catch (e) {
      debugPrint('Get revenue analytics error: $e');
      return _getDefaultAnalytics();
    }
  }

  /// Get ad performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      final response = await _client.rpc('get_ad_performance_metrics');
      return response ?? _getDefaultMetrics();
    } catch (e) {
      debugPrint('Get performance metrics error: $e');
      return _getDefaultMetrics();
    }
  }

  /// Get ad placement performance
  Future<List<Map<String, dynamic>>> getPlacementPerformance() async {
    try {
      final response = await _client
          .from('ad_placement_performance')
          .select()
          .order('impressions', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get placement performance error: $e');
      return [];
    }
  }

  /// Update ad placement configuration
  Future<bool> updatePlacementConfig({
    required String placement,
    required Map<String, dynamic> config,
  }) async {
    try {
      await _client.from('ad_placement_config').upsert({
        'placement': placement,
        'config': config,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Update placement config error: $e');
      return false;
    }
  }

  /// Get GDPR consent status
  Future<bool> hasGdprConsent() async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _client
          .from('user_consent')
          .select('personalized_ads')
          .eq('user_id', userId)
          .maybeSingle();

      return response?['personalized_ads'] ?? false;
    } catch (e) {
      debugPrint('Get GDPR consent error: $e');
      return false;
    }
  }

  /// Update GDPR consent
  Future<bool> updateGdprConsent(bool consent) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _client.from('user_consent').upsert({
        'user_id': userId,
        'personalized_ads': consent,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Update GDPR consent error: $e');
      return false;
    }
  }

  /// Reset session ad count
  void resetSessionCount() {
    _sessionAdCount.clear();
    _lastInterstitialTime.clear();
  }

  Map<String, dynamic> _getDefaultAnalytics() {
    return {
      'total_revenue': 0.0,
      'daily_revenue': 0.0,
      'weekly_revenue': 0.0,
      'monthly_revenue': 0.0,
      'total_impressions': 0,
      'total_clicks': 0,
      'ctr': 0.0,
      'ecpm': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultMetrics() {
    return {
      'impression_rate': 0.0,
      'click_through_rate': 0.0,
      'viewability_percentage': 0.0,
      'fill_rate': 0.0,
    };
  }
}
