import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  int hitCount;

  CacheEntry({required this.data, required this.expiresAt, this.hitCount = 0});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get ttlRemaining => expiresAt.difference(DateTime.now());
}

class InvalidationRule {
  final String tableName;
  final List<String> affectedPatterns;

  const InvalidationRule({
    required this.tableName,
    required this.affectedPatterns,
  });
}

class BatchRequestQueue {
  final Map<String, List<Completer<dynamic>>> _pendingBatches = {};
  final Map<String, List<String>> _batchIds = {};
  Timer? _flushTimer;
  static const int _maxBatchSize = 10;
  static const Duration _flushInterval = Duration(milliseconds: 50);

  void addRequest(String batchKey, String id, Completer<dynamic> completer) {
    _pendingBatches[batchKey] ??= [];
    _batchIds[batchKey] ??= [];
    _pendingBatches[batchKey]!.add(completer);
    _batchIds[batchKey]!.add(id);

    if (_pendingBatches[batchKey]!.length >= _maxBatchSize) {
      _flushBatch(batchKey);
    } else {
      _flushTimer?.cancel();
      _flushTimer = Timer(_flushInterval, () => _flushAllBatches());
    }
  }

  void _flushAllBatches() {
    for (final key in _pendingBatches.keys.toList()) {
      _flushBatch(key);
    }
  }

  void _flushBatch(String batchKey) {
    _pendingBatches.remove(batchKey);
    _batchIds.remove(batchKey);
  }

  List<String>? getAndClearBatch(String batchKey) {
    final ids = _batchIds.remove(batchKey);
    _pendingBatches.remove(batchKey);
    return ids;
  }

  List<Completer<dynamic>>? getCompleters(String batchKey) {
    return _pendingBatches[batchKey];
  }

  void dispose() {
    _flushTimer?.cancel();
  }
}

class SupabaseQueryCacheService {
  static SupabaseQueryCacheService? _instance;
  static SupabaseQueryCacheService get instance =>
      _instance ??= SupabaseQueryCacheService._();

  final Map<String, CacheEntry> _cache = {};
  final Map<String, Future<dynamic>> _inFlightRequests = {};
  final BatchRequestQueue _batchQueue = BatchRequestQueue();

  int _totalRequests = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _staleServed = 0;
  int _backgroundRefreshes = 0;
  bool _backgroundRefreshEnabled = true;
  Duration _backgroundRefreshInterval = const Duration(minutes: 1);
  Timer? _pruneTimer;
  final List<Map<String, dynamic>> _invalidationLog = [];

  static const Duration defaultTtl = Duration(minutes: 5);

  static const List<InvalidationRule> _invalidationRules = [
    InvalidationRule(
      tableName: 'votes',
      affectedPatterns: [
        'election_feed:*',
        'election_stats:*',
        'user_dashboard:*',
      ],
    ),
    InvalidationRule(
      tableName: 'user_profiles',
      affectedPatterns: ['user_profile:*'],
    ),
    InvalidationRule(
      tableName: 'vp_transactions',
      affectedPatterns: ['user_dashboard:*', 'leaderboard:*'],
    ),
    InvalidationRule(
      tableName: 'elections',
      affectedPatterns: ['election_feed:*', 'election_stats:*'],
    ),
  ];

  SupabaseQueryCacheService._() {
    _startPruneScheduler();
  }

  SupabaseClient get _supabase => Supabase.instance.client;

  double get hitRate => _totalRequests == 0 ? 0 : _cacheHits / _totalRequests;
  int get totalRequests => _totalRequests;
  int get cacheHits => _cacheHits;
  int get cacheMisses => _cacheMisses;
  int get staleServed => _staleServed;
  int get backgroundRefreshes => _backgroundRefreshes;
  int get cachedEntries => _cache.length;
  List<Map<String, dynamic>> get invalidationLog =>
      List.unmodifiable(_invalidationLog);

  // ─── Core Cache Operations ───────────────────────────────────────────────

  Future<T> getOrFetch<T>({
    required String cacheKey,
    required Future<T> Function() fetcher,
    Duration? ttl,
  }) async {
    _totalRequests++;

    // Check cache
    final entry = _cache[cacheKey];
    if (entry != null && !entry.isExpired) {
      _cacheHits++;
      entry.hitCount++;
      return entry.data as T;
    }

    // Stale-while-revalidate behavior parity with Web cache service.
    if (entry != null &&
        entry.isExpired &&
        _backgroundRefreshEnabled &&
        !_inFlightRequests.containsKey(cacheKey)) {
      _staleServed++;
      _backgroundRefreshes++;
      entry.hitCount++;
      _refreshInBackground<T>(
        cacheKey: cacheKey,
        fetcher: fetcher,
        ttl: ttl ?? defaultTtl,
      );
      return entry.data as T;
    }

    _cacheMisses++;

    // Query deduplication — return shared future if in-flight
    if (_inFlightRequests.containsKey(cacheKey)) {
      return await _inFlightRequests[cacheKey]! as T;
    }

    final future = fetcher();
    _inFlightRequests[cacheKey] = future;

    try {
      final result = await future;
      _cache[cacheKey] = CacheEntry(
        data: result,
        expiresAt: DateTime.now().add(ttl ?? defaultTtl),
      );
      return result;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  // ─── Cached Query Methods ─────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return getOrFetch<Map<String, dynamic>?>(
      cacheKey: 'user_profile:$userId',
      fetcher: () async {
        final res = await _supabase
            .from('user_profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        return res;
      },
    );
  }

  Future<List<Map<String, dynamic>>> getElectionFeed({
    Map<String, dynamic>? filters,
    int limit = 20,
  }) async {
    final filterHash = filters?.hashCode ?? 0;
    return getOrFetch<List<Map<String, dynamic>>>(
      cacheKey: 'election_feed:$filterHash',
      fetcher: () async {
        var query = _supabase.from('elections').select();
        if (filters != null) {
          if (filters['status'] != null) {
            query = query.eq('status', filters['status']);
          }
        }
        final res = await query.limit(limit);
        return List<Map<String, dynamic>>.from(res);
      },
    );
  }

  Future<Map<String, dynamic>?> getCreatorAnalytics(String userId) async {
    return getOrFetch<Map<String, dynamic>?>(
      cacheKey: 'creator_analytics:$userId',
      fetcher: () async {
        final res = await _supabase
            .from('creator_analytics')
            .select()
            .eq('creator_id', userId)
            .maybeSingle();
        return res;
      },
    );
  }

  // ─── Batch Methods (N+1 Prevention) ──────────────────────────────────────

  Future<List<Map<String, dynamic>>> batchGetUserProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return [];
    try {
      final res = await _supabase
          .from('user_profiles')
          .select()
          .inFilter('id', userIds);
      final results = List<Map<String, dynamic>>.from(res);
      // Cache individual results
      for (final profile in results) {
        final id = profile['id'] as String?;
        if (id != null) {
          _cache['user_profile:$id'] = CacheEntry(
            data: profile,
            expiresAt: DateTime.now().add(defaultTtl),
          );
        }
      }
      return results;
    } catch (e) {
      debugPrint('batchGetUserProfiles error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> batchGetElections(
    List<String> electionIds,
  ) async {
    if (electionIds.isEmpty) return [];
    try {
      final res = await _supabase
          .from('elections')
          .select()
          .inFilter('id', electionIds);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('batchGetElections error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> batchGetVoteCounts(
    List<String> electionIds,
  ) async {
    if (electionIds.isEmpty) return [];
    try {
      final res = await _supabase.rpc(
        'get_elections_batch',
        params: {'election_ids': electionIds},
      );
      return List<Map<String, dynamic>>.from(res ?? []);
    } catch (e) {
      debugPrint('batchGetVoteCounts error: $e');
      return [];
    }
  }

  // ─── Cache Invalidation ───────────────────────────────────────────────────

  void invalidatePattern(String pattern) {
    final prefix = pattern.replaceAll('*', '');
    final keysToRemove = _cache.keys
        .where((k) => k.startsWith(prefix))
        .toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    _invalidationLog.add({
      'pattern': pattern,
      'keysRemoved': keysToRemove.length,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (_invalidationLog.length > 100) {
      _invalidationLog.removeAt(0);
    }
    debugPrint('Cache invalidated: $pattern (${keysToRemove.length} keys)');
  }

  void onMutation(String tableName) {
    final rule = _invalidationRules
        .where((r) => r.tableName == tableName)
        .firstOrNull;
    if (rule != null) {
      for (final pattern in rule.affectedPatterns) {
        invalidatePattern(pattern);
      }
    }
  }

  /// High-level invalidation hooks for parity with Web analytics cache invalidation.
  void onAlertLifecycleChanged({String? alertId}) {
    invalidatePattern('election_stats:*');
    invalidatePattern('user_dashboard:*');
    if (alertId != null && alertId.isNotEmpty) {
      invalidateKey('alert:$alertId');
    }
  }

  void onExecutiveReportSent({String? reportType}) {
    invalidatePattern('user_dashboard:*');
    invalidatePattern('creator_analytics:*');
    if (reportType != null && reportType.isNotEmpty) {
      invalidateKey('executive_report:$reportType');
    }
  }

  void onWebhookDeliveryLogged({String? webhookId}) {
    invalidatePattern('election_stats:*');
    if (webhookId != null && webhookId.isNotEmpty) {
      invalidateKey('webhook:$webhookId');
    }
  }

  void invalidateKey(String key) {
    _cache.remove(key);
  }

  void clearAll() {
    _cache.clear();
    _inFlightRequests.clear();
  }

  // ─── Cache Analytics ──────────────────────────────────────────────────────

  Future<void> _refreshInBackground<T>({
    required String cacheKey,
    required Future<T> Function() fetcher,
    required Duration ttl,
  }) async {
    final future = fetcher();
    _inFlightRequests[cacheKey] = future;
    try {
      final result = await future;
      _cache[cacheKey] = CacheEntry(
        data: result,
        expiresAt: DateTime.now().add(ttl),
      );
    } catch (error) {
      debugPrint('Background refresh failed for $cacheKey: $error');
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  void configureBackgroundRefresh({bool? enabled, Duration? interval}) {
    if (enabled != null) {
      _backgroundRefreshEnabled = enabled;
    }
    if (interval != null && interval.inSeconds > 0) {
      _backgroundRefreshInterval = interval;
    }
    _startPruneScheduler();
  }

  Map<String, dynamic> getConfig() {
    return {
      'backgroundRefreshEnabled': _backgroundRefreshEnabled,
      'backgroundRefreshIntervalSeconds': _backgroundRefreshInterval.inSeconds,
      'defaultTtlSeconds': defaultTtl.inSeconds,
    };
  }

  void pruneExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  void _startPruneScheduler() {
    _pruneTimer?.cancel();
    _pruneTimer = Timer.periodic(_backgroundRefreshInterval, (_) {
      pruneExpired();
    });
  }

  int _estimateMemoryBytes() {
    int total = 0;
    for (final entry in _cache.entries) {
      total += entry.key.length;
      total += entry.value.data.toString().length;
    }
    return total;
  }

  List<Map<String, dynamic>> getCacheEntries() {
    return _cache.entries
        .map(
          (e) => {
            'key': e.key,
            'hitCount': e.value.hitCount,
            'ttlRemaining': e.value.ttlRemaining.inSeconds,
            'expired': e.value.isExpired,
          },
        )
        .toList();
  }

  Map<String, dynamic> getStats() {
    final totalCacheResolutions = _cacheHits + _cacheMisses + _staleServed;
    return {
      'totalRequests': _totalRequests,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'staleServed': _staleServed,
      'backgroundRefreshes': _backgroundRefreshes,
      'hitRate': hitRate,
      'staleRate': totalCacheResolutions == 0
          ? 0.0
          : _staleServed / totalCacheResolutions,
      'cachedEntries': cachedEntries,
      'inFlightRequests': _inFlightRequests.length,
      'memoryEstimateBytes': _estimateMemoryBytes(),
      'invalidationCount': _invalidationLog.length,
    };
  }

  void dispose() {
    _pruneTimer?.cancel();
    _batchQueue.dispose();
  }
}