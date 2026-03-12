import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './redis_cache_service.dart';
import '../config/redis_cache_config.dart';

class DatabaseQueryOptimizer {
  static DatabaseQueryOptimizer? _instance;
  static DatabaseQueryOptimizer get instance =>
      _instance ??= DatabaseQueryOptimizer._();
  DatabaseQueryOptimizer._();

  SupabaseClient get _client => SupabaseService.instance.client;
  RedisCacheService get _cache => RedisCacheService.instance;

  int _cacheHitCount = 0;
  int _cacheMissCount = 0;
  int _databaseQueryCount = 0;

  int get cacheHitCount => _cacheHitCount;
  int get cacheMissCount => _cacheMissCount;
  int get databaseQueryCount => _databaseQueryCount;
  int get totalRequests => _cacheHitCount + _cacheMissCount;
  double get cacheHitRate =>
      totalRequests == 0 ? 0.0 : (_cacheHitCount / totalRequests) * 100;

  void _recordCacheHit() => _cacheHitCount++;
  void _recordCacheMiss() {
    _cacheMissCount++;
    _databaseQueryCount++;
  }

  Future<Map<String, Map<String, dynamic>>> getUserProfilesBatch(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    try {
      final response = await _client
          .from('user_profiles')
          .select('id, username, display_name, avatar_url, vp_balance, tier')
          .inFilter('id', userIds);
      final Map<String, Map<String, dynamic>> result = {};
      for (final profile in response as List) {
        result[profile['id'] as String] = Map<String, dynamic>.from(profile);
      }
      return result;
    } catch (e) {
      debugPrint('Batch user profiles error: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getElectionsWithVoteCounts({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final electionKey = '${status ?? 'active'}_${limit}_$offset';
    final cacheKey = CacheKeys.electionsWithVotes(
      electionKey,
      CacheKeys.fiveMinBucket,
    );
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      _recordCacheHit();
      try {
        return List<Map<String, dynamic>>.from(jsonDecode(cached) as List);
      } catch (_) {}
    }
    _recordCacheMiss();
    try {
      final response = await _client.rpc(
        'get_election_feed',
        params: {
          'p_limit': limit,
          'p_offset': offset,
          'p_status': status ?? 'active',
        },
      );
      final data = List<Map<String, dynamic>>.from(response as List);
      await _cache.set(
        cacheKey,
        jsonEncode(data),
        ttl: CacheTTL.electionsWithVoteCounts,
      );
      return data;
    } catch (e) {
      debugPrint('Elections with vote counts error: $e');
      return _getElectionsFallback(
        status: status,
        limit: limit,
        offset: offset,
      );
    }
  }

  Future<List<Map<String, dynamic>>> _getElectionsFallback({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('elections')
          .select('*, user_profiles!creator_id(username, avatar_url)');
      if (status != null) query = query.eq('status', status);
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Elections fallback error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserNotificationsBatch(
    String userId, {
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    try {
      var query = _client
          .from('notifications')
          .select('id, title, body, type, is_read, created_at, metadata')
          .eq('user_id', userId);
      if (unreadOnly) query = query.eq('is_read', false);
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Batch notifications error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getVPTransactionsSummary(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final transactions = await _client
          .from('vp_transactions')
          .select('id, amount, transaction_type, description, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      final txList = List<Map<String, dynamic>>.from(transactions as List);
      double totalEarned = 0;
      double totalSpent = 0;
      for (final tx in txList) {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
        final type = tx['transaction_type'] as String? ?? '';
        if (type == 'earn' || type == 'reward' || type == 'bonus') {
          totalEarned += amount;
        } else if (type == 'spend' || type == 'deduct') {
          totalSpent += amount.abs();
        }
      }
      return {
        'transactions': txList,
        'total_earned': totalEarned,
        'total_spent': totalSpent,
        'net_balance': totalEarned - totalSpent,
      };
    } catch (e) {
      debugPrint('VP transactions summary error: $e');
      return {
        'transactions': [],
        'total_earned': 0,
        'total_spent': 0,
        'net_balance': 0,
      };
    }
  }

  Future<Map<String, dynamic>> getCreatorAnalyticsSummary(
    String creatorId,
  ) async {
    final cacheKey = CacheKeys.creatorAnalytics(
      creatorId,
      CacheKeys.fiveMinBucket,
    );
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      _recordCacheHit();
      try {
        return Map<String, dynamic>.from(jsonDecode(cached) as Map);
      } catch (_) {}
    }
    _recordCacheMiss();
    try {
      final response = await _client.rpc(
        'get_creator_analytics_summary',
        params: {'p_creator_id': creatorId},
      );
      final data = Map<String, dynamic>.from(response as Map);
      await _cache.set(
        cacheKey,
        jsonEncode(data),
        ttl: CacheTTL.creatorAnalytics,
      );
      return data;
    } catch (e) {
      debugPrint('Creator analytics summary error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getUserDashboardData(String userId) async {
    final cacheKey = CacheKeys.userDashboard(userId, CacheKeys.threeMinBucket);
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      _recordCacheHit();
      try {
        return Map<String, dynamic>.from(jsonDecode(cached) as Map);
      } catch (_) {}
    }
    _recordCacheMiss();
    try {
      final response = await _client.rpc(
        'get_user_dashboard_data',
        params: {'p_user_id': userId},
      );
      final data = Map<String, dynamic>.from(response as Map);
      await _cache.set(cacheKey, jsonEncode(data), ttl: CacheTTL.userDashboard);
      return data;
    } catch (e) {
      debugPrint('User dashboard data error: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getSocialFeedBatch({
    int limit = 20,
    int offset = 0,
    String? userId,
  }) async {
    try {
      final response = await _client
          .from('social_posts')
          .select(
            'id, content, media_urls, created_at, likes_count, comments_count, '
            'user_profiles!user_id(id, username, avatar_url, tier)',
          )
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Social feed batch error: $e');
      return [];
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getElectionOptionsBatch(
    List<String> electionIds,
  ) async {
    if (electionIds.isEmpty) return {};
    try {
      final response = await _client
          .from('election_options')
          .select('id, election_id, option_text, display_order, vote_count')
          .inFilter('election_id', electionIds)
          .order('display_order', ascending: true);
      final Map<String, List<Map<String, dynamic>>> result = {};
      for (final option in response as List) {
        final electionId = option['election_id'] as String;
        result.putIfAbsent(electionId, () => []);
        result[electionId]!.add(Map<String, dynamic>.from(option));
      }
      return result;
    } catch (e) {
      debugPrint('Batch election options error: $e');
      return {};
    }
  }

  Future<Map<String, bool>> getUserVoteStatusBatch(
    String userId,
    List<String> electionIds,
  ) async {
    if (electionIds.isEmpty) return {};
    try {
      final response = await _client
          .from('votes')
          .select('election_id')
          .eq('user_id', userId)
          .inFilter('election_id', electionIds);
      final Map<String, bool> result = {};
      for (final id in electionIds) {
        result[id] = false;
      }
      for (final vote in response as List) {
        result[vote['election_id'] as String] = true;
      }
      return result;
    } catch (e) {
      debugPrint('Batch vote status error: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getCreatorLeaderboard({
    String sortBy = 'total_earnings',
    int limit = 50,
  }) async {
    final cacheKey = CacheKeys.leaderboardGlobal(CacheKeys.fiveMinBucket);
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      _recordCacheHit();
      try {
        return List<Map<String, dynamic>>.from(jsonDecode(cached) as List);
      } catch (_) {}
    }
    _recordCacheMiss();
    try {
      final response = await _client
          .from('mv_creator_leaderboard')
          .select()
          .order(sortBy, ascending: false)
          .limit(limit);
      final data = List<Map<String, dynamic>>.from(response as List);
      await _cache.set(
        cacheKey,
        jsonEncode(data),
        ttl: CacheTTL.leaderboardGlobal,
      );
      return data;
    } catch (e) {
      debugPrint('Creator leaderboard error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getElectionStats(String electionId) async {
    final cacheKey = CacheKeys.electionStats(
      electionId,
      CacheKeys.fiveMinBucket,
    );
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      _recordCacheHit();
      try {
        return Map<String, dynamic>.from(jsonDecode(cached) as Map);
      } catch (_) {}
    }
    _recordCacheMiss();
    try {
      final response = await _client
          .from('mv_election_stats')
          .select()
          .eq('election_id', electionId)
          .maybeSingle();
      if (response != null) {
        await _cache.set(
          cacheKey,
          jsonEncode(response),
          ttl: CacheTTL.electionStats,
        );
      }
      return response;
    } catch (e) {
      debugPrint('Election stats error: $e');
      return null;
    }
  }

  Future<void> invalidateElectionCache(String electionId) async {
    await _cache.clear('${CacheKeys.electionStatsPrefix}:$electionId:*');
    await _cache.clear('${CacheKeys.electionsVotesPrefix}:*');
    debugPrint('Cache invalidated for election: $electionId');
  }

  Future<void> invalidateUserCache(String userId) async {
    await _cache.clear('${CacheKeys.userDashboardPrefix}:$userId:*');
    debugPrint('Cache invalidated for user: $userId');
  }

  Future<void> invalidateLeaderboards() async {
    await _cache.clear('${CacheKeys.leaderboardGlobalPrefix}:*');
    await _cache.clear('${CacheKeys.leaderboardZonePrefix}:*');
    debugPrint('All leaderboard caches invalidated');
  }

  Future<void> invalidateCreatorAnalytics(String creatorId) async {
    await _cache.clear('${CacheKeys.creatorAnalyticsPrefix}:$creatorId:*');
    debugPrint('Creator analytics cache invalidated for: $creatorId');
  }

  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'cache_hit_count': _cacheHitCount,
      'cache_miss_count': _cacheMissCount,
      'database_query_count': _databaseQueryCount,
      'total_requests': totalRequests,
      'cache_hit_rate': cacheHitRate,
      'reduction_percentage': cacheHitRate,
      'target_reduction': 70.0,
      'target_met': cacheHitRate >= 70.0,
    };
  }
}
