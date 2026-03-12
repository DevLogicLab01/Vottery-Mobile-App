import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import './ga4_analytics_service.dart';

/// Google Analytics Full Integration Service
/// Extends GA4AnalyticsService with comprehensive event tracking, screen views,
/// user properties, conversion tracking, custom dimensions, and audience segmentation
class GoogleAnalyticsService {
  static GoogleAnalyticsService? _instance;
  static GoogleAnalyticsService get instance =>
      _instance ??= GoogleAnalyticsService._();
  GoogleAnalyticsService._();

  final GA4AnalyticsService _ga4 = GA4AnalyticsService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  String? _userId;
  final Map<String, String> _userProperties = {};

  /// Initialize Google Analytics
  Future<void> initialize() async {
    try {
      await _ga4.initialize();
      await _ga4.startSession();
      debugPrint('Google Analytics initialized successfully');
    } catch (e) {
      debugPrint('Google Analytics initialization error: $e');
    }
  }

  /// Set user ID
  Future<void> setUserId(String userId) async {
    try {
      _userId = userId;
      await _ga4.trackEvent(
        eventName: 'user_id_set',
        eventParams: {'user_id': userId, 'event_type': 'user_property'},
      );
    } catch (e) {
      debugPrint('Set user ID error: $e');
    }
  }

  /// Set user property
  Future<void> setUserProperty(String propertyName, String value) async {
    try {
      _userProperties[propertyName] = value;
      await _ga4.trackEvent(
        eventName: 'user_property_set',
        eventParams: {
          'property_name': propertyName,
          'property_value': value,
          'event_type': 'user_property',
        },
      );

      // Store in database
      if (_userId != null) {
        await _supabase.from('analytics_attribution').upsert({
          'user_id': _userId,
          'user_properties': jsonEncode(_userProperties),
          'last_touch_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Set user property error: $e');
    }
  }

  // ============================================================
  // CUSTOM EVENT TRACKING
  // ============================================================

  /// Track Vote Submitted event
  Future<void> trackVoteSubmitted({
    required String electionId,
    required String voteOption,
    required int vpEarned,
    required String userTier,
  }) async {
    await _ga4.trackEvent(
      eventName: 'vote_submitted',
      eventParams: {
        'election_id': electionId,
        'vote_option': voteOption,
        'vp_earned': vpEarned,
        'user_tier': userTier,
        'event_type': 'voting',
      },
    );
    await _storeEvent('vote_submitted', {
      'election_id': electionId,
      'vote_option': voteOption,
      'vp_earned': vpEarned,
      'user_tier': userTier,
    });
  }

  /// Track Election Created event
  Future<void> trackElectionCreated({
    required String electionType,
    required double prizeAmount,
    required String category,
    required bool gamified,
  }) async {
    await _ga4.trackEvent(
      eventName: 'election_created',
      eventParams: {
        'election_type': electionType,
        'prize_amount': prizeAmount,
        'category': category,
        'gamified': gamified,
        'event_type': 'content_creation',
      },
    );
    await _storeEvent('election_created', {
      'election_type': electionType,
      'prize_amount': prizeAmount,
      'category': category,
      'gamified': gamified,
    });
  }

  /// Track Quest Completed event
  Future<void> trackQuestCompleted({
    required String questId,
    required int vpEarned,
    required int completionTime,
  }) async {
    await _ga4.trackEvent(
      eventName: 'quest_completed',
      eventParams: {
        'quest_id': questId,
        'vp_earned': vpEarned,
        'completion_time': completionTime,
        'event_type': 'engagement',
      },
    );
    await _storeEvent('quest_completed', {
      'quest_id': questId,
      'vp_earned': vpEarned,
      'completion_time': completionTime,
    });
  }

  /// Track Marketplace Purchase event
  Future<void> trackMarketplacePurchase({
    required String serviceId,
    required double amount,
    required String sellerId,
  }) async {
    await _ga4.trackEvent(
      eventName: 'marketplace_purchase',
      eventParams: {
        'service_id': serviceId,
        'amount': amount,
        'seller_id': sellerId,
        'event_type': 'ecommerce',
      },
    );
    await _storeEvent('marketplace_purchase', {
      'service_id': serviceId,
      'amount': amount,
      'seller_id': sellerId,
    });
  }

  /// Track Creator Payout event
  Future<void> trackCreatorPayout({
    required double payoutAmount,
    required String payoutMethod,
    required String creatorTier,
  }) async {
    await _ga4.trackEvent(
      eventName: 'creator_payout',
      eventParams: {
        'payout_amount': payoutAmount,
        'payout_method': payoutMethod,
        'creator_tier': creatorTier,
        'event_type': 'monetization',
      },
    );
    await _storeEvent('creator_payout', {
      'payout_amount': payoutAmount,
      'payout_method': payoutMethod,
      'creator_tier': creatorTier,
    });
  }

  // ============================================================
  // SCREEN VIEW TRACKING
  // ============================================================

  /// Track screen view
  Future<void> logScreenView(String screenName) async {
    await _ga4.trackEvent(
      eventName: 'screen_view',
      eventParams: {'screen_name': screenName, 'event_type': 'screen_view'},
    );
  }

  // ============================================================
  // CONVERSION TRACKING
  // ============================================================

  /// Track first vote conversion
  Future<void> trackFirstVote(String userId) async {
    await _ga4.trackEvent(
      eventName: 'first_vote',
      eventParams: {'user_id': userId, 'event_type': 'conversion'},
    );
    await _storeEvent('first_vote', {'user_id': userId});
  }

  /// Track first purchase conversion
  Future<void> trackFirstPurchase(String userId, double amount) async {
    await _ga4.trackEvent(
      eventName: 'first_purchase',
      eventParams: {
        'user_id': userId,
        'amount': amount,
        'event_type': 'conversion',
      },
    );
    await _storeEvent('first_purchase', {'user_id': userId, 'amount': amount});
  }

  /// Track creator signup conversion
  Future<void> trackCreatorSignup(String userId) async {
    await _ga4.trackEvent(
      eventName: 'creator_signup',
      eventParams: {'user_id': userId, 'event_type': 'conversion'},
    );
    await _storeEvent('creator_signup', {'user_id': userId});
  }

  /// Track tier upgrade conversion
  Future<void> trackTierUpgrade(String userId, String newTier) async {
    await _ga4.trackEvent(
      eventName: 'tier_upgrade',
      eventParams: {
        'user_id': userId,
        'new_tier': newTier,
        'event_type': 'conversion',
      },
    );
    await _storeEvent('tier_upgrade', {'user_id': userId, 'new_tier': newTier});
  }

  // ============================================================
  // REVENUE TRACKING
  // ============================================================

  /// Track purchase with revenue
  Future<void> logPurchase({
    required String transactionId,
    required double value,
    required String currency,
    required List<Map<String, dynamic>> items,
  }) async {
    await _ga4.trackEvent(
      eventName: 'purchase',
      eventParams: {
        'transaction_id': transactionId,
        'value': value,
        'currency': currency,
        'items': jsonEncode(items),
        'event_type': 'ecommerce',
      },
    );
    await _storeEvent('purchase', {
      'transaction_id': transactionId,
      'value': value,
      'currency': currency,
      'items': items,
    });
  }

  /// Track item view
  Future<void> logViewItem({
    required String itemId,
    required String itemName,
    required double price,
  }) async {
    await _ga4.trackEvent(
      eventName: 'view_item',
      eventParams: {
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'event_type': 'ecommerce',
      },
    );
  }

  /// Track add to cart
  Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required double price,
  }) async {
    await _ga4.trackEvent(
      eventName: 'add_to_cart',
      eventParams: {
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'event_type': 'ecommerce',
      },
    );
  }

  /// Track begin checkout
  Future<void> logBeginCheckout({required double value}) async {
    await _ga4.trackEvent(
      eventName: 'begin_checkout',
      eventParams: {'value': value, 'event_type': 'ecommerce'},
    );
  }

  // ============================================================
  // CUSTOM DIMENSIONS
  // ============================================================

  /// Set custom dimension
  Future<void> setCustomDimension(String dimensionName, String value) async {
    await _ga4.trackEvent(
      eventName: 'custom_dimension',
      eventParams: {
        'dimension_name': dimensionName,
        'dimension_value': value,
        'event_type': 'custom_dimension',
      },
    );
  }

  // ============================================================
  // CAMPAIGN ATTRIBUTION
  // ============================================================

  /// Track campaign attribution
  Future<void> trackCampaignAttribution({
    required String utmSource,
    required String utmMedium,
    required String utmCampaign,
    String? utmContent,
  }) async {
    if (_userId == null) return;

    await _supabase.from('analytics_attribution').upsert({
      'user_id': _userId,
      'utm_source': utmSource,
      'utm_medium': utmMedium,
      'utm_campaign': utmCampaign,
      'utm_content': utmContent,
      'first_touch_at': DateTime.now().toIso8601String(),
      'last_touch_at': DateTime.now().toIso8601String(),
    });
  }

  // ============================================================
  // JOLTS VIDEO ANALYTICS TRACKING
  // ============================================================

  /// Log Jolt Video View
  Future<void> logJoltVideoView({
    required String joltId,
    required String videoTitle,
    required int durationSeconds,
    required String creatorId,
  }) async {
    await _ga4.trackEvent(
      eventName: 'jolt_video_view',
      eventParams: {
        'jolt_id': joltId,
        'video_title': videoTitle,
        'duration_seconds': durationSeconds,
        'creator_id': creatorId,
        'event_type': 'video_engagement',
      },
    );
    await _storeEvent('jolt_video_view', {
      'jolt_id': joltId,
      'video_title': videoTitle,
      'duration_seconds': durationSeconds,
      'creator_id': creatorId,
    });
  }

  /// Log Jolt Watch Time
  Future<void> logJoltWatchTime({
    required String joltId,
    required int watchTimeSeconds,
    required double completionPercentage,
    Map<String, dynamic>? viewerDemographics,
  }) async {
    await _ga4.trackEvent(
      eventName: 'jolt_watch_time',
      eventParams: {
        'jolt_id': joltId,
        'watch_time_seconds': watchTimeSeconds,
        'completion_percentage': completionPercentage,
        'event_type': 'video_engagement',
        ...?viewerDemographics,
      },
    );
    await _storeEvent('jolt_watch_time', {
      'jolt_id': joltId,
      'watch_time_seconds': watchTimeSeconds,
      'completion_percentage': completionPercentage,
    });
  }

  /// Log Jolt Engagement (like, share, comment)
  Future<void> logJoltEngagement({
    required String joltId,
    required String engagementType,
    required String timestamp,
  }) async {
    await _ga4.trackEvent(
      eventName: 'jolt_engagement',
      eventParams: {
        'jolt_id': joltId,
        'engagement_type': engagementType,
        'timestamp': timestamp,
        'event_type': 'video_engagement',
      },
    );
    await _storeEvent('jolt_engagement', {
      'jolt_id': joltId,
      'engagement_type': engagementType,
    });
  }

  /// Log Jolt Viewer Demographics
  Future<void> logJoltViewerDemographics({
    required String joltId,
    required String viewerAgeGroup,
    required String viewerGender,
    required String viewerLocation,
  }) async {
    await _ga4.trackEvent(
      eventName: 'jolt_viewer_demographics',
      eventParams: {
        'jolt_id': joltId,
        'viewer_age_group': viewerAgeGroup,
        'viewer_gender': viewerGender,
        'viewer_location': viewerLocation,
        'event_type': 'demographics',
      },
    );
    try {
      await _supabase.from('jolts_video_analytics').upsert({
        'jolt_id': joltId,
        'viewer_demographics': {
          'age_group': viewerAgeGroup,
          'gender': viewerGender,
          'location': viewerLocation,
        },
        'recorded_date': DateTime.now().toIso8601String().substring(0, 10),
      });
    } catch (e) {
      debugPrint('Log jolt demographics error: $e');
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Store event in database
  Future<void> _storeEvent(
    String eventName,
    Map<String, dynamic> params,
  ) async {
    try {
      if (_userId == null) return;

      await _supabase.from('google_analytics_events').insert({
        'event_id': _uuid.v4(),
        'user_id': _userId,
        'event_name': eventName,
        'event_parameters': jsonEncode(params),
        'timestamp': DateTime.now().toIso8601String(),
        'synced_to_ga4': false,
      });
    } catch (e) {
      debugPrint('Store event error: $e');
    }
  }

  /// Log AI Feature Adoption - wired to AI content moderation, consensus, quests
  Future<void> logAIFeatureAdoption(
    String featureName, {
    String? userId,
  }) async {
    await _ga4.trackEvent(
      eventName: 'ai_feature_adoption',
      eventParams: {
        'feature_name': featureName,
        'user_id': userId ?? _userId ?? 'anonymous',
        'timestamp': DateTime.now().toIso8601String(),
        'event_type': 'ai_adoption',
      },
    );
    await _storeEvent('ai_feature_adoption', {
      'feature_name': featureName,
      'user_id': userId ?? _userId,
    });
  }

  /// Log VP Earning event
  Future<void> logVPEarning({
    required double amount,
    required String source,
    String? userId,
  }) async {
    await _ga4.trackEvent(
      eventName: 'vp_earned',
      eventParams: {
        'amount': amount,
        'source': source,
        'user_id': userId ?? _userId ?? 'anonymous',
        'timestamp': DateTime.now().toIso8601String(),
        'event_type': 'vp_economy',
      },
    );
    await _storeEvent('vp_earned', {
      'amount': amount,
      'source': source,
      'user_id': userId ?? _userId,
    });
  }
}
