import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './ga4_analytics_service.dart';

/// Google Analytics Carousel Tracker
/// Comprehensive GA4 integration for carousel events, attribution, and funnel tracking
class GoogleAnalyticsCarouselTracker {
  static GoogleAnalyticsCarouselTracker? _instance;
  static GoogleAnalyticsCarouselTracker get instance =>
      _instance ??= GoogleAnalyticsCarouselTracker._();

  GoogleAnalyticsCarouselTracker._();

  final GA4AnalyticsService _ga4 = GA4AnalyticsService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================
  // CAROUSEL EVENT TRACKING
  // ============================================

  /// Track carousel impression
  Future<void> trackCarouselImpression({
    required String carouselType,
    required String contentType,
    required String contentId,
    String? userSegment,
    String? deviceType,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      // Track to GA4
      await _ga4.trackEvent(
        eventName: 'carousel_impression',
        eventParams: {
          'carousel_type': carouselType,
          'content_type': contentType,
          'content_id': contentId,
          'user_segment': userSegment ?? 'unknown',
          'device_type': deviceType ?? 'unknown',
        },
      );

      // Store impression for attribution
      if (userId != null) {
        await _supabase.from('ga4_event_log').insert({
          'user_id': userId,
          'event_name': 'carousel_impression',
          'event_parameters': jsonEncode({
            'carousel_type': carouselType,
            'content_type': contentType,
            'content_id': contentId,
            'user_segment': userSegment,
            'device_type': deviceType,
          }),
          'event_timestamp': DateTime.now().toIso8601String(),
          'synced_to_ga4': true,
        });
      }
    } catch (e) {
      debugPrint('Track carousel impression error: $e');
    }
  }

  /// Track carousel swipe
  Future<void> trackCarouselSwipe({
    required String carouselType,
    required String contentType,
    required String contentId,
    required String swipeDirection,
    required String swipeVelocity,
    required int positionInFeed,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      await _ga4.trackEvent(
        eventName: 'carousel_swipe',
        eventParams: {
          'carousel_type': carouselType,
          'content_type': contentType,
          'content_id': contentId,
          'swipe_direction': swipeDirection,
          'swipe_velocity': swipeVelocity,
          'position_in_feed': positionInFeed,
        },
      );

      if (userId != null) {
        await _supabase.from('ga4_event_log').insert({
          'user_id': userId,
          'event_name': 'carousel_swipe',
          'event_parameters': jsonEncode({
            'carousel_type': carouselType,
            'content_type': contentType,
            'content_id': contentId,
            'swipe_direction': swipeDirection,
            'swipe_velocity': swipeVelocity,
            'position_in_feed': positionInFeed,
          }),
          'event_timestamp': DateTime.now().toIso8601String(),
          'synced_to_ga4': true,
        });
      }
    } catch (e) {
      debugPrint('Track carousel swipe error: $e');
    }
  }

  /// Track carousel engagement
  Future<void> trackCarouselEngagement({
    required String carouselType,
    required String contentType,
    required String contentId,
    required String engagementType,
    required int engagementDurationMs,
    required bool ledToConversion,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      await _ga4.trackEvent(
        eventName: 'carousel_engagement',
        eventParams: {
          'carousel_type': carouselType,
          'content_type': contentType,
          'content_id': contentId,
          'engagement_type': engagementType,
          'engagement_duration_ms': engagementDurationMs,
          'led_to_conversion': ledToConversion,
        },
      );

      if (userId != null) {
        await _supabase.from('ga4_event_log').insert({
          'user_id': userId,
          'event_name': 'carousel_engagement',
          'event_parameters': jsonEncode({
            'carousel_type': carouselType,
            'content_type': contentType,
            'content_id': contentId,
            'engagement_type': engagementType,
            'engagement_duration_ms': engagementDurationMs,
            'led_to_conversion': ledToConversion,
          }),
          'event_timestamp': DateTime.now().toIso8601String(),
          'synced_to_ga4': true,
        });
      }
    } catch (e) {
      debugPrint('Track carousel engagement error: $e');
    }
  }

  /// Track carousel conversion
  Future<void> trackCarouselConversion({
    required String carouselType,
    required String contentType,
    required String contentId,
    required String conversionType,
    double? conversionValue,
    double? revenueAmount,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      await _ga4.trackEvent(
        eventName: 'carousel_conversion',
        eventParams: {
          'carousel_type': carouselType,
          'content_type': contentType,
          'content_id': contentId,
          'conversion_type': conversionType,
          'conversion_value': conversionValue ?? 0.0,
          'revenue_amount': revenueAmount ?? 0.0,
        },
      );

      if (userId != null) {
        final eventResponse = await _supabase
            .from('ga4_event_log')
            .insert({
              'user_id': userId,
              'event_name': 'carousel_conversion',
              'event_parameters': jsonEncode({
                'carousel_type': carouselType,
                'content_type': contentType,
                'content_id': contentId,
                'conversion_type': conversionType,
                'conversion_value': conversionValue,
                'revenue_amount': revenueAmount,
              }),
              'event_timestamp': DateTime.now().toIso8601String(),
              'synced_to_ga4': true,
            })
            .select()
            .single();

        // Create attribution record
        await _createAttributionRecord(
          userId: userId,
          conversionEventId: eventResponse['event_id'] as String,
          carouselType: carouselType,
          contentId: contentId,
        );

        // Update funnel tracking
        await _updateFunnelTracking(
          userId: userId,
          funnelName: 'Carousel View Funnel',
          stage: 'conversion',
          conversionValue: conversionValue,
        );
      }
    } catch (e) {
      debugPrint('Track carousel conversion error: $e');
    }
  }

  /// Track carousel session
  Future<void> trackCarouselSession({
    required String sessionId,
    required int sessionDurationSeconds,
    required int carouselsViewed,
    required int itemsEngaged,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      await _ga4.trackEvent(
        eventName: 'carousel_session_end',
        eventParams: {
          'session_id': sessionId,
          'session_duration_seconds': sessionDurationSeconds,
          'carousels_viewed': carouselsViewed,
          'items_engaged': itemsEngaged,
        },
      );

      if (userId != null) {
        await _supabase.from('ga4_event_log').insert({
          'user_id': userId,
          'event_name': 'carousel_session_end',
          'event_parameters': jsonEncode({
            'session_id': sessionId,
            'session_duration_seconds': sessionDurationSeconds,
            'carousels_viewed': carouselsViewed,
            'items_engaged': itemsEngaged,
          }),
          'event_timestamp': DateTime.now().toIso8601String(),
          'synced_to_ga4': true,
        });
      }
    } catch (e) {
      debugPrint('Track carousel session error: $e');
    }
  }

  // ============================================
  // CUSTOM EVENTS PER CAROUSEL TYPE
  // ============================================

  /// Track Horizontal Snap specific events
  Future<void> trackHorizontalSnapEvent({
    required String eventType,
    required String contentId,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      await _ga4.trackEvent(
        eventName: 'horizontal_snap_$eventType',
        eventParams: {'content_id': contentId, ...?additionalParams},
      );
    } catch (e) {
      debugPrint('Track horizontal snap event error: $e');
    }
  }

  /// Track Vertical Stack specific events
  Future<void> trackVerticalStackEvent({
    required String eventType,
    required String contentId,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      await _ga4.trackEvent(
        eventName: 'vertical_stack_$eventType',
        eventParams: {'content_id': contentId, ...?additionalParams},
      );
    } catch (e) {
      debugPrint('Track vertical stack event error: $e');
    }
  }

  /// Track Gradient Flow specific events
  Future<void> trackGradientFlowEvent({
    required String eventType,
    required String contentId,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      await _ga4.trackEvent(
        eventName: 'gradient_flow_$eventType',
        eventParams: {'content_id': contentId, ...?additionalParams},
      );
    } catch (e) {
      debugPrint('Track gradient flow event error: $e');
    }
  }

  // ============================================
  // CONVERSION ATTRIBUTION
  // ============================================

  Future<void> _createAttributionRecord({
    required String userId,
    required String conversionEventId,
    required String carouselType,
    required String contentId,
  }) async {
    try {
      // Find last impression within 7-day window
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final impressionResponse = await _supabase
          .from('ga4_event_log')
          .select()
          .eq('user_id', userId)
          .eq('event_name', 'carousel_impression')
          .gte('event_timestamp', sevenDaysAgo.toIso8601String())
          .order('event_timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      if (impressionResponse == null) return;

      final impressionTimestamp = DateTime.parse(
        impressionResponse['event_timestamp'] as String,
      );
      final conversionTimestamp = DateTime.now();

      // Calculate attribution using last-touch model
      await _supabase.from('carousel_attribution').insert({
        'user_id': userId,
        'conversion_event_id': conversionEventId,
        'attributed_carousel_type': carouselType,
        'attributed_content_id': contentId,
        'impression_timestamp': impressionTimestamp.toIso8601String(),
        'conversion_timestamp': conversionTimestamp.toIso8601String(),
        'attribution_model': 'last_touch',
        'contribution_percentage': 100.0,
      });
    } catch (e) {
      debugPrint('Create attribution record error: $e');
    }
  }

  /// Get attribution analysis
  Future<Map<String, dynamic>> getAttributionAnalysis({
    required String attributionModel,
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabase
          .from('carousel_attribution')
          .select()
          .eq('attribution_model', attributionModel)
          .gte('conversion_timestamp', startDate.toIso8601String());

      Map<String, int> attributionByCarousel = {};
      double totalContribution = 0.0;

      for (final record in response) {
        final carouselType = record['attributed_carousel_type'] as String;
        final contribution = ((record['contribution_percentage'] ?? 0.0) as num)
            .toDouble();

        attributionByCarousel[carouselType] =
            (attributionByCarousel[carouselType] ?? 0) + 1;
        totalContribution += contribution;
      }

      return {
        'attribution_model': attributionModel,
        'total_conversions': response.length,
        'attribution_by_carousel': attributionByCarousel,
        'avg_contribution': response.isNotEmpty
            ? totalContribution / response.length
            : 0.0,
      };
    } catch (e) {
      debugPrint('Get attribution analysis error: $e');
      return {};
    }
  }

  // ============================================
  // FUNNEL ANALYSIS
  // ============================================

  Future<void> _updateFunnelTracking({
    required String userId,
    required String funnelName,
    required String stage,
    double? conversionValue,
  }) async {
    try {
      // Get or create funnel tracking
      final funnelResponse = await _supabase
          .from('carousel_funnel_tracking')
          .select()
          .eq('user_id', userId)
          .eq('funnel_name', funnelName)
          .eq('completed', false)
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (funnelResponse == null) {
        // Create new funnel
        await _supabase.from('carousel_funnel_tracking').insert({
          'user_id': userId,
          'funnel_name': funnelName,
          'current_stage': stage,
          'stage_timestamps': jsonEncode({
            stage: DateTime.now().toIso8601String(),
          }),
          'completed': stage == 'conversion',
          'conversion_value': conversionValue,
          'started_at': DateTime.now().toIso8601String(),
          'completed_at': stage == 'conversion'
              ? DateTime.now().toIso8601String()
              : null,
        });
      } else {
        // Update existing funnel
        final stageTimestamps = jsonDecode(
          funnelResponse['stage_timestamps'] ?? '{}',
        );
        stageTimestamps[stage] = DateTime.now().toIso8601String();

        await _supabase
            .from('carousel_funnel_tracking')
            .update({
              'current_stage': stage,
              'stage_timestamps': jsonEncode(stageTimestamps),
              'completed': stage == 'conversion',
              'conversion_value': conversionValue,
              'completed_at': stage == 'conversion'
                  ? DateTime.now().toIso8601String()
                  : null,
            })
            .eq('tracking_id', funnelResponse['tracking_id']);
      }
    } catch (e) {
      debugPrint('Update funnel tracking error: $e');
    }
  }

  /// Get funnel metrics
  Future<Map<String, dynamic>> getFunnelMetrics({
    required String funnelName,
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabase
          .from('carousel_funnel_tracking')
          .select()
          .eq('funnel_name', funnelName)
          .gte('started_at', startDate.toIso8601String());

      int totalFunnels = response.length;
      int completedFunnels = 0;
      Map<String, int> stageReached = {};

      for (final record in response) {
        if (record['completed'] == true) completedFunnels++;

        final stageTimestamps = jsonDecode(record['stage_timestamps'] ?? '{}');
        stageTimestamps.forEach((stage, timestamp) {
          stageReached[stage] = (stageReached[stage] ?? 0) + 1;
        });
      }

      return {
        'funnel_name': funnelName,
        'total_funnels': totalFunnels,
        'completed_funnels': completedFunnels,
        'completion_rate': totalFunnels > 0
            ? (completedFunnels / totalFunnels) * 100
            : 0.0,
        'stage_reached': stageReached,
      };
    } catch (e) {
      debugPrint('Get funnel metrics error: $e');
      return {};
    }
  }

  // ============================================
  // COHORT SEGMENTATION
  // ============================================

  /// Get cohort analysis
  Future<Map<String, dynamic>> getCohortAnalysis({
    required String cohortType,
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabase
          .from('ga4_event_log')
          .select('user_id, event_name, event_parameters, event_timestamp')
          .gte('event_timestamp', startDate.toIso8601String())
          .order('event_timestamp', ascending: true);

      Map<String, Map<String, dynamic>> cohorts = {};

      for (final record in response) {
        final userId = record['user_id'] as String?;
        if (userId == null) continue;

        final eventParams = jsonDecode(record['event_parameters'] ?? '{}');
        final cohortKey = cohortType == 'acquisition_date'
            ? DateTime.parse(
                record['event_timestamp'] as String,
              ).toIso8601String().substring(0, 10)
            : eventParams['carousel_type'] ?? 'unknown';

        cohorts[cohortKey] ??= {
          'users': <String>{},
          'events': 0,
          'conversions': 0,
        };

        (cohorts[cohortKey]!['users'] as Set<String>).add(userId);
        cohorts[cohortKey]!['events'] =
            (cohorts[cohortKey]!['events'] as int) + 1;

        if (record['event_name'] == 'carousel_conversion') {
          cohorts[cohortKey]!['conversions'] =
              (cohorts[cohortKey]!['conversions'] as int) + 1;
        }
      }

      // Convert to list format
      List<Map<String, dynamic>> cohortList = [];
      cohorts.forEach((key, value) {
        final users = (value['users'] as Set<String>).length;
        final events = value['events'] as int;
        final conversions = value['conversions'] as int;

        cohortList.add({
          'cohort_key': key,
          'user_count': users,
          'total_events': events,
          'total_conversions': conversions,
          'conversion_rate': users > 0 ? (conversions / users) * 100 : 0.0,
          'events_per_user': users > 0 ? events / users : 0.0,
        });
      });

      return {'cohort_type': cohortType, 'cohorts': cohortList};
    } catch (e) {
      debugPrint('Get cohort analysis error: $e');
      return {};
    }
  }

  // ============================================
  // REAL-TIME METRICS
  // ============================================

  /// Get real-time event feed
  Future<List<Map<String, dynamic>>> getRealTimeEventFeed({
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('ga4_event_log')
          .select()
          .order('event_timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get real-time event feed error: $e');
      return [];
    }
  }

  /// Get event volume by type
  Future<Map<String, int>> getEventVolumeByType({int hours = 24}) async {
    try {
      final startTime = DateTime.now().subtract(Duration(hours: hours));

      final response = await _supabase
          .from('ga4_event_log')
          .select('event_name')
          .gte('event_timestamp', startTime.toIso8601String());

      Map<String, int> volumeByType = {};
      for (final record in response) {
        final eventName = record['event_name'] as String;
        volumeByType[eventName] = (volumeByType[eventName] ?? 0) + 1;
      }

      return volumeByType;
    } catch (e) {
      debugPrint('Get event volume by type error: $e');
      return {};
    }
  }
}