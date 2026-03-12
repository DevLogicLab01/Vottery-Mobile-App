import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/redis_cache_config.dart';
import './database_query_optimizer.dart';
import './redis_cache_service.dart';

class CacheWarmingService {
  static CacheWarmingService? _instance;
  static CacheWarmingService get instance =>
      _instance ??= CacheWarmingService._();
  CacheWarmingService._();

  Timer? _warmingTimer;
  bool _isWarming = false;
  DateTime? _lastWarmTime;

  RedisCacheService get _cache => RedisCacheService.instance;
  DatabaseQueryOptimizer get _optimizer => DatabaseQueryOptimizer.instance;

  void startWarming() {
    _warmingTimer?.cancel();
    _warmingTimer = Timer.periodic(
      const Duration(minutes: 4),
      (_) => warmAll(),
    );
    warmAll();
    debugPrint('CacheWarmingService: Started periodic warming every 4 minutes');
  }

  void stopWarming() {
    _warmingTimer?.cancel();
    _warmingTimer = null;
    debugPrint('CacheWarmingService: Stopped');
  }

  Future<void> warmAll() async {
    if (_isWarming) return;
    _isWarming = true;
    try {
      debugPrint('CacheWarmingService: Starting cache warm cycle...');
      await Future.wait([
        warmGlobalLeaderboard(),
        warmActiveElections(),
        warmTopCreators(),
      ]);
      _lastWarmTime = DateTime.now();
      debugPrint('CacheWarmingService: Warm cycle completed at $_lastWarmTime');
    } catch (e) {
      debugPrint('CacheWarmingService: Warm cycle error: $e');
    } finally {
      _isWarming = false;
    }
  }

  Future<void> warmGlobalLeaderboard() async {
    try {
      final data = await _optimizer.getCreatorLeaderboard(limit: 100);
      if (data.isNotEmpty) {
        final cacheKey = CacheKeys.leaderboardGlobal(CacheKeys.fiveMinBucket);
        await _cache.set(
          cacheKey,
          jsonEncode(data),
          ttl: CacheTTL.leaderboardGlobal,
        );
        debugPrint(
          'CacheWarmingService: Warmed global leaderboard (${data.length} entries)',
        );
      }
    } catch (e) {
      debugPrint('CacheWarmingService: warmGlobalLeaderboard error: $e');
    }
  }

  Future<void> warmActiveElections() async {
    try {
      final elections = await _optimizer.getElectionsWithVoteCounts(
        status: 'active',
        limit: 50,
      );
      if (elections.isNotEmpty) {
        final cacheKey = CacheKeys.electionsWithVotes(
          'active_top50',
          CacheKeys.fiveMinBucket,
        );
        await _cache.set(
          cacheKey,
          jsonEncode(elections),
          ttl: CacheTTL.electionFeed,
        );
        debugPrint(
          'CacheWarmingService: Warmed active elections (${elections.length} entries)',
        );
      }
    } catch (e) {
      debugPrint('CacheWarmingService: warmActiveElections error: $e');
    }
  }

  Future<void> warmTopCreators() async {
    try {
      final leaderboard = await _optimizer.getCreatorLeaderboard(limit: 100);
      if (leaderboard.isNotEmpty) {
        debugPrint(
          'CacheWarmingService: Warmed top ${leaderboard.length} creators',
        );
      }
    } catch (e) {
      debugPrint('CacheWarmingService: warmTopCreators error: $e');
    }
  }

  bool get isWarming => _isWarming;
  DateTime? get lastWarmTime => _lastWarmTime;

  void dispose() => stopWarming();
}
