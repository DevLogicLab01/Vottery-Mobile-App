import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './auth_service.dart';

class TopicPreferenceService {
  static TopicPreferenceService? _instance;
  static TopicPreferenceService get instance =>
      _instance ??= TopicPreferenceService._();

  TopicPreferenceService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get all topic categories
  Future<List<Map<String, dynamic>>> getTopicCategories() async {
    try {
      final response = await _client
          .from('topic_categories')
          .select()
          .eq('is_active', true)
          .order('display_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get topic categories error: $e');
      return [];
    }
  }

  /// Track swipe interaction
  Future<bool> trackSwipe({
    required String topicCategoryId,
    required String swipeDirection,
    required double swipeVelocity,
    required int dwellTimeMs,
    int hesitationCount = 0,
    int hoverDurationMs = 0,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('swipe_history').insert({
        'user_id': _auth.currentUser!.id,
        'topic_category_id': topicCategoryId,
        'swipe_direction': swipeDirection,
        'swipe_velocity': swipeVelocity,
        'dwell_time_ms': dwellTimeMs,
        'hesitation_count': hesitationCount,
        'hover_duration_ms': hoverDurationMs,
        'device_type': kIsWeb ? 'web' : 'mobile',
      });

      // Update user topic preferences
      await _updateTopicPreference(
        topicCategoryId,
        swipeDirection,
        swipeVelocity,
      );

      return true;
    } catch (e) {
      debugPrint('Track swipe error: $e');
      return false;
    }
  }

  /// Update topic preference based on swipe
  Future<void> _updateTopicPreference(
    String topicCategoryId,
    String swipeDirection,
    double swipeVelocity,
  ) async {
    try {
      // Calculate preference score
      double preferenceScore = 0.0;
      int positiveSwipes = 0;
      int negativeSwipes = 0;

      if (swipeDirection == 'right') {
        preferenceScore = swipeVelocity > 1000 ? 1.0 : 0.7;
        positiveSwipes = 1;
      } else if (swipeDirection == 'up') {
        preferenceScore = 1.0;
        positiveSwipes = 1;
      } else if (swipeDirection == 'left') {
        preferenceScore = -0.5;
        negativeSwipes = 1;
      } else if (swipeDirection == 'down') {
        preferenceScore = -1.0;
        negativeSwipes = 1;
      }

      // Upsert preference
      await _client.from('user_topic_preferences').upsert({
        'user_id': _auth.currentUser!.id,
        'topic_category_id': topicCategoryId,
        'preference_score': preferenceScore,
        'swipe_count': 1,
        'positive_swipes': positiveSwipes,
        'negative_swipes': negativeSwipes,
        'last_interaction_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,topic_category_id');
    } catch (e) {
      debugPrint('Update topic preference error: $e');
    }
  }

  /// Get user preference summary
  Future<Map<String, dynamic>?> getPreferenceSummary() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('preference_summaries')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get preference summary error: $e');
      return null;
    }
  }

  /// Update preference summary
  Future<bool> updatePreferenceSummary({
    required List<String> selectedCategories,
    required double completionPercentage,
    bool onboardingCompleted = false,
    String? personaCluster,
    double confidenceScore = 0.0,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('preference_summaries').upsert({
        'user_id': _auth.currentUser!.id,
        'selected_categories': selectedCategories,
        'completion_percentage': completionPercentage,
        'onboarding_completed': onboardingCompleted,
        'persona_cluster': personaCluster,
        'confidence_score': confidenceScore,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Update preference summary error: $e');
      return false;
    }
  }

  /// Track onboarding analytics
  Future<bool> trackOnboardingAnalytics({
    required String variant,
    int? completionTimeSeconds,
    int skipCount = 0,
    int backNavigationCount = 0,
    int totalInteractions = 0,
    bool completed = false,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('onboarding_analytics').insert({
        'user_id': _auth.currentUser!.id,
        'variant': variant,
        'completion_time_seconds': completionTimeSeconds,
        'skip_count': skipCount,
        'back_navigation_count': backNavigationCount,
        'total_interactions': totalInteractions,
        'completed': completed,
      });

      return true;
    } catch (e) {
      debugPrint('Track onboarding analytics error: $e');
      return false;
    }
  }

  /// Get user topic preferences
  Future<List<Map<String, dynamic>>> getUserTopicPreferences() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('user_topic_preferences')
          .select('*, topic_categories(*)')
          .eq('user_id', _auth.currentUser!.id)
          .order('preference_score', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user topic preferences error: $e');
      return [];
    }
  }

  /// Mark topic onboarding as completed (persist in user_profiles.preferences for Web/Mobile sync).
  Future<bool> markTopicOnboardingCompleted() async {
    try {
      if (!_auth.isAuthenticated) return false;
      final userId = _auth.currentUser!.id;
      final res = await _client
          .from('user_profiles')
          .select('preferences')
          .eq('id', userId)
          .maybeSingle();
      final Map<String, dynamic> prefs =
          Map<String, dynamic>.from(res != null && res['preferences'] != null
              ? res['preferences'] as Map
              : {});
      prefs['topic_onboarding_completed'] = true;
      await _client.from('user_profiles').update({'preferences': prefs}).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('markTopicOnboardingCompleted error: $e');
      return false;
    }
  }

  /// Whether the user has completed topic preference onboarding (from user_profiles.preferences).
  Future<bool> hasCompletedTopicOnboarding() async {
    try {
      if (!_auth.isAuthenticated) return false;
      final userId = _auth.currentUser!.id;
      final res = await _client
          .from('user_profiles')
          .select('preferences')
          .eq('id', userId)
          .maybeSingle();
      final prefs = res != null && res['preferences'] != null
          ? res['preferences'] as Map<String, dynamic>
          : <String, dynamic>{};
      return prefs['topic_onboarding_completed'] == true;
    } catch (e) {
      debugPrint('hasCompletedTopicOnboarding error: $e');
      return false;
    }
  }

  /// Calculate ML persona cluster (simplified)
  String calculatePersonaCluster(List<Map<String, dynamic>> preferences) {
    if (preferences.isEmpty) return 'explorer';

    final topCategories = preferences.take(3).toList();
    final categoryNames = topCategories
        .map((p) => p['topic_categories']?['name'] ?? '')
        .toList();

    // Simple clustering logic
    if (categoryNames.contains('politics') &&
        categoryNames.contains('business')) {
      return 'political_analyst';
    } else if (categoryNames.contains('sports') &&
        categoryNames.contains('entertainment')) {
      return 'entertainment_enthusiast';
    } else if (categoryNames.contains('technology') &&
        categoryNames.contains('education')) {
      return 'tech_learner';
    } else if (categoryNames.contains('health') &&
        categoryNames.contains('education')) {
      return 'wellness_advocate';
    } else {
      return 'diverse_explorer';
    }
  }
}
