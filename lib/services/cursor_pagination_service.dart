import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class CursorModel {
  final DateTime timestamp;
  final String id;
  final String direction;

  CursorModel({
    required this.timestamp,
    required this.id,
    this.direction = 'forward',
  });

  String encode() {
    final json = {
      'timestamp': timestamp.toIso8601String(),
      'id': id,
      'direction': direction,
    };
    return base64Url.encode(utf8.encode(jsonEncode(json)));
  }

  static CursorModel? decode(String cursor) {
    try {
      final decoded = utf8.decode(base64Url.decode(cursor));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return CursorModel(
        timestamp: DateTime.parse(json['timestamp'] as String),
        id: json['id'] as String,
        direction: json['direction'] as String? ?? 'forward',
      );
    } catch (e) {
      debugPrint('Decode cursor error: $e');
      return null;
    }
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final String? nextCursor;
  final String? previousCursor;
  final bool hasMore;
  final int? totalCount;

  PaginatedResponse({
    required this.data,
    this.nextCursor,
    this.previousCursor,
    required this.hasMore,
    this.totalCount,
  });
}

class CursorPaginationService {
  static CursorPaginationService? _instance;
  static CursorPaginationService get instance =>
      _instance ??= CursorPaginationService._();

  CursorPaginationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // LRU Cache for prefetched pages
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const _cacheDuration = Duration(minutes: 5);
  static const _maxCacheSize = 50;

  /// Fetch Jolts with cursor pagination
  Future<PaginatedResponse<Map<String, dynamic>>> fetchJolts({
    String? cursor,
    int pageSize = 20,
  }) async {
    return _fetchContent(
      tableName: 'carousel_content_jolts',
      idColumn: 'jolt_id',
      cursor: cursor,
      pageSize: pageSize,
      selectQuery: '''*, creator:user_profiles!creator_id(
        id, username, avatar_url, verified
      )''',
    );
  }

  /// Fetch Moments with cursor pagination
  Future<PaginatedResponse<Map<String, dynamic>>> fetchMoments({
    String? cursor,
    int pageSize = 20,
  }) async {
    return _fetchContent(
      tableName: 'carousel_content_moments',
      idColumn: 'moment_id',
      cursor: cursor,
      pageSize: pageSize,
      selectQuery: '''*, creator:user_profiles!creator_id(
        id, username, avatar_url
      )''',
    );
  }

  /// Fetch Groups with cursor pagination
  Future<PaginatedResponse<Map<String, dynamic>>> fetchGroups({
    String? cursor,
    int pageSize = 20,
  }) async {
    return _fetchContent(
      tableName: 'groups',
      idColumn: 'group_id',
      cursor: cursor,
      pageSize: pageSize,
      selectQuery: '*',
    );
  }

  /// Fetch Elections with cursor pagination
  Future<PaginatedResponse<Map<String, dynamic>>> fetchElections({
    String? cursor,
    int pageSize = 20,
  }) async {
    return _fetchContent(
      tableName: 'elections',
      idColumn: 'election_id',
      cursor: cursor,
      pageSize: pageSize,
      selectQuery: '*',
    );
  }

  /// Fetch Posts with cursor pagination
  Future<PaginatedResponse<Map<String, dynamic>>> fetchPosts({
    String? cursor,
    int pageSize = 20,
  }) async {
    return _fetchContent(
      tableName: 'posts',
      idColumn: 'post_id',
      cursor: cursor,
      pageSize: pageSize,
      selectQuery: '*',
      additionalFilters: {'is_active': true},
    );
  }

  /// Generic fetch content with cursor pagination
  Future<PaginatedResponse<Map<String, dynamic>>> _fetchContent({
    required String tableName,
    required String idColumn,
    String? cursor,
    required int pageSize,
    required String selectQuery,
    Map<String, dynamic>? additionalFilters,
  }) async {
    try {
      final cacheKey = '$tableName:$cursor:$pageSize';

      // Check cache first
      if (_isCacheValid(cacheKey)) {
        final cachedData = _cache[cacheKey]!;
        return PaginatedResponse(
          data: cachedData.take(pageSize).toList(),
          nextCursor: cachedData.length > pageSize
              ? _createCursor(cachedData[pageSize - 1], idColumn)
              : null,
          hasMore: cachedData.length > pageSize,
        );
      }

      dynamic query = _client.from(tableName).select(selectQuery);

      // Apply additional filters
      if (additionalFilters != null) {
        additionalFilters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Apply cursor if provided
      if (cursor != null) {
        final cursorModel = CursorModel.decode(cursor);
        if (cursorModel != null) {
          if (cursorModel.direction == 'forward') {
            query = query
                .lt('created_at', cursorModel.timestamp.toIso8601String())
                .order('created_at', ascending: false)
                .order(idColumn, ascending: false);
          } else {
            query = query
                .gt('created_at', cursorModel.timestamp.toIso8601String())
                .order('created_at', ascending: true)
                .order(idColumn, ascending: true);
          }
        }
      } else {
        // Initial load
        query = query
            .order('created_at', ascending: false)
            .order(idColumn, ascending: false);
      }

      // Fetch one extra to determine if there are more results
      query = query.limit(pageSize + 1);

      final response = await query;
      final results = List<Map<String, dynamic>>.from(response);

      // Determine if there are more results
      final hasMore = results.length > pageSize;
      final data = hasMore ? results.take(pageSize).toList() : results;

      // Create next cursor
      String? nextCursor;
      if (hasMore && data.isNotEmpty) {
        nextCursor = _createCursor(data.last, idColumn);
      }

      // Update cache
      _updateCache(cacheKey, results);

      // Track analytics
      _trackPaginationAnalytics(contentType: tableName, cacheHit: false);

      return PaginatedResponse(
        data: data,
        nextCursor: nextCursor,
        hasMore: hasMore,
      );
    } catch (e) {
      debugPrint('Fetch content error: $e');
      return PaginatedResponse(data: [], hasMore: false);
    }
  }

  /// Create cursor from item
  String _createCursor(Map<String, dynamic> item, String idColumn) {
    final timestamp = DateTime.parse(item['created_at'] as String);
    final id = item[idColumn] as String;
    return CursorModel(timestamp: timestamp, id: id).encode();
  }

  /// Check if cache is valid
  bool _isCacheValid(String cacheKey) {
    if (!_cache.containsKey(cacheKey)) return false;

    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  /// Update cache with LRU eviction
  void _updateCache(String cacheKey, List<Map<String, dynamic>> data) {
    // Evict oldest entries if cache is full
    if (_cache.length >= _maxCacheSize) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _cache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }

    _cache[cacheKey] = data;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Prefetch next page
  Future<void> prefetchNextPage({
    required String tableName,
    required String idColumn,
    required String? nextCursor,
    required int pageSize,
  }) async {
    if (nextCursor == null) return;

    final cacheKey = '$tableName:$nextCursor:$pageSize';
    if (_isCacheValid(cacheKey)) return; // Already cached

    // Fetch in background
    _fetchContent(
      tableName: tableName,
      idColumn: idColumn,
      cursor: nextCursor,
      pageSize: pageSize,
      selectQuery: '*',
    );
  }

  /// Track pagination analytics
  Future<void> _trackPaginationAnalytics({
    required String contentType,
    required bool cacheHit,
    int? scrollDepth,
  }) async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client.from('pagination_analytics').insert({
        'user_id': _auth.currentUser!.id,
        'content_type': contentType,
        'cache_hit': cacheHit,
        'scroll_depth_percent': scrollDepth,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Track pagination analytics error: $e');
    }
  }

  /// Get pagination statistics
  Future<Map<String, dynamic>> getPaginationStats({
    required String contentType,
  }) async {
    try {
      final response = await _client
          .from('pagination_analytics')
          .select()
          .eq('content_type', contentType)
          .gte(
            'recorded_at',
            DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
          );

      final analytics = List<Map<String, dynamic>>.from(response);

      if (analytics.isEmpty) {
        return {
          'avg_scroll_depth': 0.0,
          'cache_hit_rate': 0.0,
          'total_requests': 0,
        };
      }

      final totalRequests = analytics.length;
      final cacheHits = analytics.where((a) => a['cache_hit'] == true).length;
      final avgScrollDepth =
          analytics
              .where((a) => a['scroll_depth_percent'] != null)
              .map((a) => a['scroll_depth_percent'] as int)
              .fold<int>(0, (sum, depth) => sum + depth) /
          totalRequests;

      return {
        'avg_scroll_depth': avgScrollDepth,
        'cache_hit_rate': (cacheHits / totalRequests) * 100,
        'total_requests': totalRequests,
      };
    } catch (e) {
      debugPrint('Get pagination stats error: $e');
      return {
        'avg_scroll_depth': 0.0,
        'cache_hit_rate': 0.0,
        'total_requests': 0,
      };
    }
  }
}
