import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/supabase_service.dart';

enum CarouselContentType {
  jolts,
  moments,
  creatorSpotlights,
  recommendedGroups,
  recommendedElections,
  creatorServices,
  trendingTopics,
  topEarners,
  accuracyChampions,
}

/// Carousel Content Service
/// Manages fetching and caching of carousel content from Supabase
class CarouselContentService {
  static final _supabase = SupabaseService.instance.client;
  static final Map<String, List<Map<String, dynamic>>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const _cacheDuration = Duration(minutes: 5);

  // Fetch Jolts with pagination
  static Future<List<Map<String, dynamic>>> fetchJolts({
    int page = 0,
    int limit = 10,
  }) async {
    final cacheKey = 'jolts_$page';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _supabase
          .from('carousel_content_jolts')
          .select('''
            *,
            creator:user_profiles!creator_id(
              id,
              username,
              avatar_url,
              verified
            )
          ''')
          .eq('is_active', true)
          .order('trending_score', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      final data = (response as List)
          .map((item) {
            return {
              ...item,
              'creator': {
                'user_id': item['creator']['id'],
                'username': item['creator']['username'],
                'avatar': item['creator']['avatar_url'],
                'verified': item['creator']['verified'] ?? false,
              },
            };
          })
          .toList()
          .cast<Map<String, dynamic>>();

      _updateCache(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint('Error fetching jolts: $e');
      return [];
    }
  }

  // Fetch Moments with pagination
  static Future<List<Map<String, dynamic>>> fetchMoments({
    int page = 0,
    int limit = 10,
    String? userId,
  }) async {
    final cacheKey = 'moments_$page';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _supabase
          .from('carousel_content_moments')
          .select('''
            *,
            creator:user_profiles!creator_id(
              id,
              username,
              avatar_url
            )
          ''')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      final data = (response as List)
          .map((item) {
            return {
              ...item,
              'creator': {
                'username': item['creator']['username'],
                'avatar': item['creator']['avatar_url'],
              },
              'time_remaining': _calculateTimeRemaining(item['expires_at']),
            };
          })
          .toList()
          .cast<Map<String, dynamic>>();

      _updateCache(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint('Error fetching moments: $e');
      return [];
    }
  }

  // Fetch Creator Spotlights
  static Future<List<Map<String, dynamic>>> fetchCreatorSpotlights({
    int page = 0,
    int limit = 10,
  }) async {
    final cacheKey = 'creator_spotlights_$page';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _supabase
          .from('creator_spotlights')
          .select('''
            *,
            creator:user_profiles!creator_id(
              id,
              username,
              avatar_url,
              verified
            )
          ''')
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      final data = (response as List).cast<Map<String, dynamic>>();
      _updateCache(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint('Error fetching creator spotlights: $e');
      return [];
    }
  }

  // Fetch Recommended Groups
  static Future<List<Map<String, dynamic>>> fetchRecommendedGroups({
    int page = 0,
    int limit = 10,
    String? userId,
  }) async {
    final cacheKey = 'recommended_groups_$page';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _supabase
          .from('carousel_content_groups')
          .select('*')
          .eq('is_active', true)
          .order('trending_score', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      final data = (response as List).cast<Map<String, dynamic>>();
      _updateCache(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint('Error fetching recommended groups: $e');
      return [];
    }
  }

  // Fetch Recommended Elections
  static Future<List<Map<String, dynamic>>> fetchRecommendedElections({
    int page = 0,
    int limit = 10,
    String? userId,
  }) async {
    final cacheKey = 'recommended_elections_$page';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _supabase
          .from('carousel_content_elections_recommended')
          .select('*')
          .eq('is_active', true)
          .order('match_score', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      final data = (response as List).cast<Map<String, dynamic>>();
      _updateCache(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint('Error fetching recommended elections: $e');
      return [];
    }
  }

  // Fetch Creator Services
  static Future<List<Map<String, dynamic>>> fetchCreatorServices({
    int page = 0,
    int limit = 10,
  }) async {
    final cacheKey = 'creator_services_$page';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _supabase
          .from('creator_marketplace_services')
          .select('''
            *,
            creator:user_profiles!creator_id(
              id,
              username,
              avatar_url,
              verified
            )
          ''')
          .eq('is_active', true)
          .order('rating', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      final data = (response as List).cast<Map<String, dynamic>>();
      _updateCache(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint('Error fetching creator services: $e');
      return [];
    }
  }

  // Fetch Trending Topics
  static Future<List<Map<String, dynamic>>> fetchTrendingTopics({
    int page = 0,
    int limit = 10,
  }) async {
    final cacheKey = 'trending_topics_$page';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _supabase
          .from('carousel_content_trending_topics')
          .select('*')
          .eq('is_active', true)
          .order('trend_score', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      final data = (response as List).cast<Map<String, dynamic>>();
      _updateCache(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint('Error fetching trending topics: $e');
      return [];
    }
  }

  // Fetch Top Earners
  static Future<List<Map<String, dynamic>>> fetchTopEarners({
    int page = 0,
    int limit = 10,
  }) async {
    final cacheKey = 'top_earners_$page';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _supabase
          .from('carousel_content_top_earners')
          .select('''
            *,
            user:user_profiles!user_id(
              id,
              username,
              avatar_url,
              verified
            )
          ''')
          .eq('is_active', true)
          .order('rank', ascending: true)
          .range(page * limit, (page + 1) * limit - 1);

      final data = (response as List).cast<Map<String, dynamic>>();
      _updateCache(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint('Error fetching top earners: $e');
      return [];
    }
  }

  // Fetch Accuracy Champions
  static Future<List<Map<String, dynamic>>> fetchAccuracyChampions({
    int page = 0,
    int limit = 10,
  }) async {
    final cacheKey = 'accuracy_champions_$page';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _supabase
          .from('prediction_champions')
          .select('''
            *,
            user:user_profiles!user_id(
              id,
              username,
              avatar_url,
              verified
            )
          ''')
          .eq('is_active', true)
          .order('accuracy_score', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      final data = (response as List).cast<Map<String, dynamic>>();
      _updateCache(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint('Error fetching accuracy champions: $e');
      return [];
    }
  }

  // Join Group Action
  static Future<bool> joinGroup(String groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error joining group: $e');
      return false;
    }
  }

  // Cache management
  static bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  static void _updateCache(String key, List<Map<String, dynamic>> data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  static String _calculateTimeRemaining(String? expiresAt) {
    if (expiresAt == null) return '24h';
    final expiry = DateTime.parse(expiresAt);
    final now = DateTime.now();
    final difference = expiry.difference(now);

    if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Expired';
    }
  }

  // Real-time subscription for content updates
  static Stream<List<Map<String, dynamic>>> subscribeToContentUpdates(
    CarouselContentType contentType,
  ) {
    final tableName = _getTableName(contentType);
    return _supabase
        .from(tableName)
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .map((data) => data.cast<Map<String, dynamic>>());
  }

  static String _getTableName(CarouselContentType contentType) {
    switch (contentType) {
      case CarouselContentType.jolts:
        return 'carousel_content_jolts';
      case CarouselContentType.moments:
        return 'carousel_content_moments';
      case CarouselContentType.creatorSpotlights:
        return 'creator_spotlights';
      case CarouselContentType.recommendedGroups:
        return 'carousel_content_groups';
      case CarouselContentType.recommendedElections:
        return 'carousel_content_elections_recommended';
      case CarouselContentType.creatorServices:
        return 'creator_marketplace_services';
      case CarouselContentType.trendingTopics:
        return 'carousel_content_trending_topics';
      case CarouselContentType.topEarners:
        return 'carousel_content_top_earners';
      case CarouselContentType.accuracyChampions:
        return 'prediction_champions';
    }
  }
}
