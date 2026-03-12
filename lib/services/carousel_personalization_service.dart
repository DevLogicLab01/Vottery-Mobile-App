import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Carousel Personalization Service
/// ML-powered customization with user behavior tracking, segment-based sequencing,
/// device-adaptive content ordering, and carousel type prediction
class CarouselPersonalizationService {
  static CarouselPersonalizationService? _instance;
  static CarouselPersonalizationService get instance =>
      _instance ??= CarouselPersonalizationService._();

  CarouselPersonalizationService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Connectivity _connectivity = Connectivity();

  // ============================================
  // USER BEHAVIOR DATA COLLECTION
  // ============================================

  /// Track user interaction for behavior analysis
  Future<void> trackInteraction({
    required String carouselType,
    required String contentType,
    required String interactionType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get current behavior
      final behaviorResponse = await _supabase
          .from('user_carousel_behavior')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      Map<String, dynamic> swipePatterns = {};
      Map<String, dynamic> engagementPatterns = {};
      Map<String, dynamic> contentPreferences = {};

      if (behaviorResponse != null) {
        swipePatterns = jsonDecode(behaviorResponse['swipe_patterns'] ?? '{}');
        engagementPatterns = jsonDecode(
          behaviorResponse['engagement_patterns'] ?? '{}',
        );
        contentPreferences = jsonDecode(
          behaviorResponse['content_preferences'] ?? '{}',
        );
      }

      // Update patterns based on interaction type
      if (interactionType == 'swipe') {
        final direction = additionalData?['direction'] ?? 'unknown';
        swipePatterns[contentType] ??= {
          'right': 0,
          'left': 0,
          'up': 0,
          'down': 0,
        };
        swipePatterns[contentType][direction] =
            (swipePatterns[contentType][direction] ?? 0) + 1;
      } else if (interactionType == 'engagement') {
        engagementPatterns[carouselType] ??= {'count': 0, 'total_duration': 0};
        engagementPatterns[carouselType]['count'] =
            (engagementPatterns[carouselType]['count'] ?? 0) + 1;
        engagementPatterns[carouselType]['total_duration'] =
            (engagementPatterns[carouselType]['total_duration'] ?? 0) +
            (additionalData?['duration'] ?? 0);
      } else if (interactionType == 'conversion') {
        contentPreferences[contentType] ??= {'views': 0, 'conversions': 0};
        contentPreferences[contentType]['conversions'] =
            (contentPreferences[contentType]['conversions'] ?? 0) + 1;
      }

      // Calculate behavior score
      final behaviorScore = _calculateBehaviorScore(
        swipePatterns,
        engagementPatterns,
        contentPreferences,
      );

      // Upsert behavior data
      await _supabase.from('user_carousel_behavior').upsert({
        'user_id': userId,
        'swipe_patterns': jsonEncode(swipePatterns),
        'engagement_patterns': jsonEncode(engagementPatterns),
        'content_preferences': jsonEncode(contentPreferences),
        'last_interaction': DateTime.now().toIso8601String(),
        'behavior_score': behaviorScore,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Track interaction error: $e');
    }
  }

  double _calculateBehaviorScore(
    Map<String, dynamic> swipePatterns,
    Map<String, dynamic> engagementPatterns,
    Map<String, dynamic> contentPreferences,
  ) {
    double score = 0.0;

    // Swipe engagement (30%)
    int totalSwipes = 0;
    int rightSwipes = 0;
    swipePatterns.forEach((key, value) {
      if (value is Map) {
        totalSwipes +=
            ((value['right'] ?? 0) as int) +
            ((value['left'] ?? 0) as int) +
            ((value['up'] ?? 0) as int) +
            ((value['down'] ?? 0) as int);
        rightSwipes += (value['right'] ?? 0) as int;
      }
    });
    if (totalSwipes > 0) {
      score += (rightSwipes / totalSwipes) * 30;
    }

    // Engagement duration (40%)
    int totalEngagements = 0;
    int totalDuration = 0;
    engagementPatterns.forEach((key, value) {
      if (value is Map) {
        totalEngagements += (value['count'] ?? 0) as int;
        totalDuration += (value['total_duration'] ?? 0) as int;
      }
    });
    if (totalEngagements > 0) {
      final avgDuration = totalDuration / totalEngagements;
      score += (avgDuration.clamp(0, 60) / 60) * 40; // Max 60 seconds
    }

    // Conversion rate (30%)
    int totalViews = 0;
    int totalConversions = 0;
    contentPreferences.forEach((key, value) {
      if (value is Map) {
        totalViews += (value['views'] ?? 0) as int;
        totalConversions += (value['conversions'] ?? 0) as int;
      }
    });
    if (totalViews > 0) {
      score += (totalConversions / totalViews) * 30;
    }

    return score.clamp(0, 100);
  }

  // ============================================
  // SEGMENT-BASED SEQUENCING
  // ============================================

  /// Assign user to segments based on behavior
  Future<List<String>> assignUserSegments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get user behavior
      final behaviorResponse = await _supabase
          .from('user_carousel_behavior')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (behaviorResponse == null) return [];

      final behaviorScore = (behaviorResponse['behavior_score'] ?? 0.0) as num;
      final engagementPatterns = jsonDecode(
        behaviorResponse['engagement_patterns'] ?? '{}',
      );

      // Get user profile
      final profileResponse = await _supabase
          .from('user_profiles')
          .select('tier, created_at')
          .eq('id', userId)
          .maybeSingle();

      final tier = profileResponse?['tier'] ?? 'bronze';
      final accountAge = DateTime.now()
          .difference(
            DateTime.parse(
              profileResponse?['created_at'] ??
                  DateTime.now().toIso8601String(),
            ),
          )
          .inDays;

      List<String> segments = [];

      // High Engagement Users (engagement_rate > 60%)
      if (behaviorScore > 60) {
        segments.add('high_engagement');
      }

      // Content Creators (tier >= Silver)
      if (['silver', 'gold', 'platinum'].contains(tier.toLowerCase())) {
        segments.add('content_creators');
      }

      // Early Adopters (account_age < 30 days)
      if (accountAge < 30) {
        segments.add('early_adopters');
      }

      // Power Users (high activity)
      int totalEngagements = 0;
      engagementPatterns.forEach((key, value) {
        if (value is Map) {
          totalEngagements += (value['count'] ?? 0) as int;
        }
      });
      if (totalEngagements > 100) {
        segments.add('power_users');
      }

      // Casual Browsers (low engagement)
      if (behaviorScore < 30) {
        segments.add('casual_browsers');
      }

      // Store segments
      for (final segment in segments) {
        await _supabase.from('user_segments').upsert({
          'user_id': userId,
          'segment_name': segment,
          'segment_score': behaviorScore,
          'segment_features': jsonEncode({
            'tier': tier,
            'account_age': accountAge,
            'total_engagements': totalEngagements,
          }),
          'assigned_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now()
              .add(const Duration(days: 30))
              .toIso8601String(),
        });
      }

      return segments;
    } catch (e) {
      debugPrint('Assign user segments error: $e');
      return [];
    }
  }

  /// Get personalized carousel sequence for user
  Future<List<String>> getPersonalizedCarouselSequence() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return ['horizontal_snap', 'vertical_stack', 'gradient_flow'];
      }

      // Get user segments
      final segmentsResponse = await _supabase
          .from('user_segments')
          .select()
          .eq('user_id', userId)
          .order('segment_score', ascending: false);

      if (segmentsResponse.isEmpty) {
        return ['horizontal_snap', 'vertical_stack', 'gradient_flow'];
      }

      final primarySegment = segmentsResponse.first['segment_name'] as String;

      // Segment-specific sequences
      final Map<String, List<String>> segmentSequences = {
        'high_engagement': [
          'horizontal_snap',
          'vertical_stack',
          'gradient_flow',
        ],
        'content_creators': [
          'vertical_stack',
          'horizontal_snap',
          'gradient_flow',
        ],
        'price_sensitive': [
          'gradient_flow',
          'vertical_stack',
          'horizontal_snap',
        ],
        'early_adopters': [
          'horizontal_snap',
          'gradient_flow',
          'vertical_stack',
        ],
        'power_users': ['vertical_stack', 'gradient_flow', 'horizontal_snap'],
        'casual_browsers': [
          'horizontal_snap',
          'vertical_stack',
          'gradient_flow',
        ],
      };

      return segmentSequences[primarySegment] ??
          ['horizontal_snap', 'vertical_stack', 'gradient_flow'];
    } catch (e) {
      debugPrint('Get personalized carousel sequence error: $e');
      return ['horizontal_snap', 'vertical_stack', 'gradient_flow'];
    }
  }

  // ============================================
  // DEVICE-ADAPTIVE CONTENT ORDERING
  // ============================================

  /// Detect and store device capabilities
  Future<void> detectDeviceCapabilities() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      String deviceType = 'unknown';
      String deviceTier = 'mid_range';
      double totalMemoryGb = 4.0;
      int screenWidth = 1080;
      int screenHeight = 1920;
      double pixelRatio = 2.0;

      if (kIsWeb) {
        deviceType = 'web';
        deviceTier = 'high_end';
      } else {
        try {
          if (defaultTargetPlatform == TargetPlatform.android) {
            final androidInfo = await _deviceInfo.androidInfo;
            deviceType = 'android';
            // Estimate memory (not directly available)
            totalMemoryGb = 4.0; // Default estimate

            // Classify device tier based on Android version and hardware
            if (androidInfo.version.sdkInt >= 30) {
              deviceTier = 'high_end';
              totalMemoryGb = 8.0;
            } else if (androidInfo.version.sdkInt >= 26) {
              deviceTier = 'mid_range';
              totalMemoryGb = 4.0;
            } else {
              deviceTier = 'low_end';
              totalMemoryGb = 2.0;
            }
          } else if (defaultTargetPlatform == TargetPlatform.iOS) {
            final iosInfo = await _deviceInfo.iosInfo;
            deviceType = 'ios';
            deviceTier = 'high_end'; // iOS devices generally high-end
            totalMemoryGb = 6.0;
          }
        } catch (e) {
          debugPrint('Device info error: $e');
        }
      }

      // Store device info
      await _supabase.from('user_devices').upsert({
        'user_id': userId,
        'device_type': deviceType,
        'device_tier': deviceTier,
        'total_memory_gb': totalMemoryGb,
        'screen_width': screenWidth,
        'screen_height': screenHeight,
        'pixel_ratio': pixelRatio,
        'capabilities': jsonEncode({
          'supports_high_res': deviceTier == 'high_end',
          'supports_animations': deviceTier != 'low_end',
          'supports_video': true,
        }),
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Detect device capabilities error: $e');
    }
  }

  /// Get device-adaptive content ordering
  Future<Map<String, dynamic>> getDeviceAdaptiveSettings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'resolution': 'medium',
          'animations': true,
          'preload_videos': false,
          'carousel_priority': [
            'horizontal_snap',
            'vertical_stack',
            'gradient_flow',
          ],
        };
      }

      // Get device info
      final deviceResponse = await _supabase
          .from('user_devices')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (deviceResponse == null) {
        return {
          'resolution': 'medium',
          'animations': true,
          'preload_videos': false,
          'carousel_priority': [
            'horizontal_snap',
            'vertical_stack',
            'gradient_flow',
          ],
        };
      }

      final deviceTier = deviceResponse['device_tier'] as String?;

      // Get network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isWifi = connectivityResult.contains(ConnectivityResult.wifi);

      Map<String, dynamic> settings = {};

      if (deviceTier == 'high_end') {
        settings = {
          'resolution': 'high',
          'animations': true,
          'preload_videos': isWifi,
          'carousel_priority': [
            'horizontal_snap',
            'gradient_flow',
            'vertical_stack',
          ],
        };
      } else if (deviceTier == 'mid_range') {
        settings = {
          'resolution': 'medium',
          'animations': true,
          'preload_videos': false,
          'carousel_priority': [
            'vertical_stack',
            'horizontal_snap',
            'gradient_flow',
          ],
        };
      } else {
        settings = {
          'resolution': 'low',
          'animations': false,
          'preload_videos': false,
          'carousel_priority': [
            'vertical_stack',
            'gradient_flow',
            'horizontal_snap',
          ],
        };
      }

      return settings;
    } catch (e) {
      debugPrint('Get device adaptive settings error: $e');
      return {
        'resolution': 'medium',
        'animations': true,
        'preload_videos': false,
        'carousel_priority': [
          'horizontal_snap',
          'vertical_stack',
          'gradient_flow',
        ],
      };
    }
  }

  // ============================================
  // ML-POWERED CAROUSEL TYPE SELECTION
  // ============================================

  /// Predict best carousel type for user (simplified without TFLite for now)
  Future<String> predictCarouselType() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 'horizontal_snap';

      // Get user features
      final behaviorResponse = await _supabase
          .from('user_carousel_behavior')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final deviceResponse = await _supabase
          .from('user_devices')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (behaviorResponse == null) return 'horizontal_snap';

      final engagementPatterns = jsonDecode(
        behaviorResponse['engagement_patterns'] ?? '{}',
      );
      final deviceTier = deviceResponse?['device_tier'] ?? 'mid_range';

      // Simple rule-based prediction (placeholder for ML model)
      Map<String, int> carouselEngagement = {
        'horizontal_snap': 0,
        'vertical_stack': 0,
        'gradient_flow': 0,
      };

      engagementPatterns.forEach((key, value) {
        if (value is Map && carouselEngagement.containsKey(key)) {
          carouselEngagement[key] = value['count'] ?? 0;
        }
      });

      // Find most engaged carousel
      String predictedType = 'horizontal_snap';
      int maxEngagement = 0;
      carouselEngagement.forEach((type, count) {
        if (count > maxEngagement) {
          maxEngagement = count;
          predictedType = type;
        }
      });

      // Store prediction
      await _supabase.from('carousel_ml_predictions').insert({
        'user_id': userId,
        'input_features': jsonEncode({
          'device_tier': deviceTier,
          'engagement_patterns': engagementPatterns,
        }),
        'predicted_carousel_type': predictedType,
        'confidence_score': 0.75,
        'predicted_at': DateTime.now().toIso8601String(),
      });

      return predictedType;
    } catch (e) {
      debugPrint('Predict carousel type error: $e');
      return 'horizontal_snap';
    }
  }

  // ============================================
  // ANALYTICS
  // ============================================

  /// Get segment distribution
  Future<Map<String, int>> getSegmentDistribution() async {
    try {
      final response = await _supabase
          .from('user_segments')
          .select('segment_name')
          .gte('expires_at', DateTime.now().toIso8601String());

      Map<String, int> distribution = {};
      for (final record in response) {
        final segment = record['segment_name'] as String;
        distribution[segment] = (distribution[segment] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      debugPrint('Get segment distribution error: $e');
      return {};
    }
  }

  /// Get ML model performance metrics
  Future<Map<String, dynamic>> getMLModelPerformance() async {
    try {
      final response = await _supabase
          .from('carousel_ml_predictions')
          .select()
          .not('was_accurate', 'is', null)
          .order('predicted_at', ascending: false)
          .limit(1000);

      if (response.isEmpty) {
        return {'total_predictions': 0, 'accuracy': 0.0, 'confidence_avg': 0.0};
      }

      int totalPredictions = response.length;
      int accuratePredictions = 0;
      double totalConfidence = 0.0;

      for (final record in response) {
        if (record['was_accurate'] == true) accuratePredictions++;
        totalConfidence += ((record['confidence_score'] ?? 0.0) as num)
            .toDouble();
      }

      return {
        'total_predictions': totalPredictions,
        'accuracy': (accuratePredictions / totalPredictions) * 100,
        'confidence_avg': totalConfidence / totalPredictions,
      };
    } catch (e) {
      debugPrint('Get ML model performance error: $e');
      return {'total_predictions': 0, 'accuracy': 0.0, 'confidence_avg': 0.0};
    }
  }
}