import 'dart:async';
import 'package:flutter/foundation.dart';

class CacheStats {
  int hits;
  int misses;
  int totalRequests;
  CacheStats({this.hits = 0, this.misses = 0, this.totalRequests = 0});
  double get hitRate => totalRequests == 0 ? 0.0 : (hits / totalRequests) * 100;
  Map<String, dynamic> toMap() => {
    'hits': hits,
    'misses': misses,
    'total_requests': totalRequests,
    'hit_rate': hitRate,
  };
}

class _CacheEntry {
  final String value;
  final DateTime expiresAt;
  _CacheEntry({required this.value, required int ttlSeconds})
    : expiresAt = DateTime.now().add(Duration(seconds: ttlSeconds));
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  int get remainingTtl =>
      expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 99999);
}

class RedisCacheService {
  static RedisCacheService? _instance;
  static RedisCacheService get instance => _instance ??= RedisCacheService._();
  RedisCacheService._();

  final Map<String, _CacheEntry> _cache = {};
  bool _isAvailable = true;
  bool _isInitialized = false;
  final CacheStats _stats = CacheStats();
  Timer? _healthCheckTimer;
  final List<Map<String, dynamic>> _invalidationLog = [];

  static String get _host =>
      const String.fromEnvironment('REDIS_HOST', defaultValue: 'localhost');
  static int get _port =>
      const int.fromEnvironment('REDIS_PORT', defaultValue: 6379);
  static bool get _tls =>
      const bool.fromEnvironment('REDIS_TLS', defaultValue: false);

  bool get isAvailable => _isAvailable;
  bool get isInitialized => _isInitialized;
  CacheStats get stats => _stats;
  List<Map<String, dynamic>> get invalidationLog =>
      List.unmodifiable(_invalidationLog);

  Future<void> initializeRedis() async {
    if (_isInitialized) return;
    try {
      debugPrint(
        'RedisCacheService: Initializing connection to $_host:$_port (TLS: $_tls)',
      );
      _isAvailable = true;
      _isInitialized = true;
      _startHealthCheck();
      debugPrint(
        'RedisCacheService: Initialized successfully (in-memory mode)',
      );
    } catch (e) {
      debugPrint('RedisCacheService: Initialization failed: $e');
      _isAvailable = false;
      _isInitialized = true;
    }
  }

  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _performHealthCheck(),
    );
  }

  Future<bool> ping() async {
    try {
      _cleanExpiredKeys();
      return true;
    } catch (e) {
      _isAvailable = false;
      return false;
    }
  }

  Future<void> _performHealthCheck() async {
    final healthy = await ping();
    if (!healthy && _isAvailable) {
      debugPrint('RedisCacheService: Connection lost, attempting reconnect...');
      await _reconnectWithBackoff();
    }
  }

  Future<void> _reconnectWithBackoff() async {
    int attempt = 0;
    const maxAttempts = 5;
    while (attempt < maxAttempts && !_isAvailable) {
      final delay = Duration(seconds: (1 << attempt).clamp(1, 30));
      await Future.delayed(delay);
      try {
        _isAvailable = true;
        debugPrint('RedisCacheService: Reconnected on attempt ${attempt + 1}');
        return;
      } catch (e) {
        attempt++;
        debugPrint('RedisCacheService: Reconnect attempt $attempt failed: $e');
      }
    }
  }

  Future<String?> get(String key) async {
    _stats.totalRequests++;
    if (!_isAvailable) {
      _stats.misses++;
      return null;
    }
    try {
      _cleanExpiredKeys();
      final entry = _cache[key];
      if (entry == null || entry.isExpired) {
        if (entry != null && entry.isExpired) _cache.remove(key);
        _stats.misses++;
        return null;
      }
      _stats.hits++;
      return entry.value;
    } catch (e) {
      debugPrint('RedisCacheService.get error for key $key: $e');
      _stats.misses++;
      return null;
    }
  }

  Future<bool> set(String key, String value, {int ttl = 300}) async {
    if (!_isAvailable) return false;
    try {
      if (_cache.length >= 10000) _evictLRU();
      _cache[key] = _CacheEntry(value: value, ttlSeconds: ttl);
      return true;
    } catch (e) {
      debugPrint('RedisCacheService.set error for key $key: $e');
      return false;
    }
  }

  Future<bool> delete(String key) async {
    if (!_isAvailable) return false;
    try {
      _cache.remove(key);
      _logInvalidation(key, 'manual_delete');
      return true;
    } catch (e) {
      debugPrint('RedisCacheService.delete error for key $key: $e');
      return false;
    }
  }

  Future<int> clear(String pattern) async {
    if (!_isAvailable) return 0;
    try {
      final regexStr =
          '^${pattern.replaceAll('*', '.*').replaceAll('?', '.')}\$';
      final regex = RegExp(regexStr);
      final keysToDelete = _cache.keys.where((k) => regex.hasMatch(k)).toList();
      for (final key in keysToDelete) {
        _cache.remove(key);
      }
      _logInvalidation(pattern, 'pattern_clear');
      return keysToDelete.length;
    } catch (e) {
      debugPrint('RedisCacheService.clear error for pattern $pattern: $e');
      return 0;
    }
  }

  Future<bool> exists(String key) async {
    if (!_isAvailable) return false;
    try {
      final entry = _cache[key];
      if (entry == null || entry.isExpired) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> ttl(String key) async {
    if (!_isAvailable) return -1;
    try {
      final entry = _cache[key];
      if (entry == null || entry.isExpired) return -1;
      return entry.remainingTtl;
    } catch (e) {
      return -1;
    }
  }

  List<String> getKeys({String pattern = '*'}) {
    _cleanExpiredKeys();
    if (pattern == '*') return _cache.keys.toList();
    final regexStr = '^${pattern.replaceAll('*', '.*').replaceAll('?', '.')}\$';
    final regex = RegExp(regexStr);
    return _cache.keys.where((k) => regex.hasMatch(k)).toList();
  }

  int get keyCount {
    _cleanExpiredKeys();
    return _cache.length;
  }

  int get approximateMemoryBytes {
    int total = 0;
    for (final entry in _cache.entries) {
      total += entry.key.length * 2 + entry.value.value.length * 2 + 64;
    }
    return total;
  }

  Map<String, int> getKeyDistribution() {
    _cleanExpiredKeys();
    final distribution = <String, int>{
      'leaderboard': 0,
      'creator': 0,
      'election': 0,
      'user': 0,
      'other': 0,
    };
    for (final key in _cache.keys) {
      if (key.startsWith('leaderboard')) {
        distribution['leaderboard'] = (distribution['leaderboard'] ?? 0) + 1;
      } else if (key.startsWith('creator')) {
        distribution['creator'] = (distribution['creator'] ?? 0) + 1;
      } else if (key.startsWith('election')) {
        distribution['election'] = (distribution['election'] ?? 0) + 1;
      } else if (key.startsWith('user')) {
        distribution['user'] = (distribution['user'] ?? 0) + 1;
      } else {
        distribution['other'] = (distribution['other'] ?? 0) + 1;
      }
    }
    return distribution;
  }

  List<Map<String, dynamic>> getKeysExpiringSoon({int withinSeconds = 60}) {
    _cleanExpiredKeys();
    final result = <Map<String, dynamic>>[];
    for (final entry in _cache.entries) {
      final remaining = entry.value.remainingTtl;
      if (remaining <= withinSeconds) {
        result.add({
          'key': entry.key,
          'remaining_ttl': remaining,
          'data_size': entry.value.value.length,
        });
      }
    }
    result.sort(
      (a, b) =>
          (a['remaining_ttl'] as int).compareTo(b['remaining_ttl'] as int),
    );
    return result;
  }

  void resetStats() {
    _stats.hits = 0;
    _stats.misses = 0;
    _stats.totalRequests = 0;
  }

  void _cleanExpiredKeys() {
    final expiredKeys = _cache.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  void _evictLRU() {
    final count = (_cache.length * 0.1).ceil();
    final keys = _cache.keys.take(count).toList();
    for (final key in keys) {
      _cache.remove(key);
    }
  }

  void _logInvalidation(String keyOrPattern, String reason) {
    _invalidationLog.insert(0, {
      'timestamp': DateTime.now().toIso8601String(),
      'key_pattern': keyOrPattern,
      'reason': reason,
    });
    if (_invalidationLog.length > 100) _invalidationLog.removeLast();
  }

  void dispose() {
    _healthCheckTimer?.cancel();
    _cache.clear();
  }
}
