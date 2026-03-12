import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_consensus_result.dart';
import '../models/quest.dart';
import './ai/ai_service_base.dart';

/// AI Cache Service for Offline AI Result Caching
/// Uses SharedPreferences for persistent storage of AI results
class AICacheService {
  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  // Cache keys
  static const String _consensusPrefix = 'consensus_';
  static const String _questsPrefix = 'quests_';
  static const String _pendingRequestsKey = 'pending_requests';

  /// Initialize the cache service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      debugPrint('AICacheService initialized successfully');

      // Start background sync on initialization
      syncPendingAIRequests();
    } catch (e) {
      debugPrint('Failed to initialize AICacheService: $e');
      rethrow;
    }
  }

  /// Cache AI consensus results for offline access
  static Future<void> cacheConsensusResult({
    required String analysisId,
    required AIConsensusResult result,
  }) async {
    if (_prefs == null) await initialize();

    try {
      final cacheData = {
        'result': result.toJson(),
        'cached_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      };

      await _prefs!.setString(
        '$_consensusPrefix$analysisId',
        jsonEncode(cacheData),
      );

      debugPrint('Cached consensus result for analysis: $analysisId');
    } catch (e) {
      debugPrint('Failed to cache consensus result: $e');
    }
  }

  /// Get cached AI consensus results when offline
  static AIConsensusResult? getCachedConsensusResult(String analysisId) {
    if (_prefs == null) return null;

    try {
      final cachedString = _prefs!.getString('$_consensusPrefix$analysisId');
      if (cachedString == null) return null;

      final cached = jsonDecode(cachedString) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(cached['expires_at'] as String);

      if (DateTime.now().isBefore(expiresAt)) {
        return AIConsensusResult.fromJson(
          cached['result'] as Map<String, dynamic>,
        );
      } else {
        // Remove expired cache
        _prefs!.remove('$_consensusPrefix$analysisId');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to get cached consensus result: $e');
      return null;
    }
  }

  /// Cache personalized quests
  static Future<void> cacheQuests({
    required String userId,
    required List<Quest> quests,
  }) async {
    if (_prefs == null) await initialize();

    try {
      final cacheData = {
        'quests': quests.map((q) => q.toJson()).toList(),
        'cached_at': DateTime.now().toIso8601String(),
      };

      await _prefs!.setString('$_questsPrefix$userId', jsonEncode(cacheData));

      debugPrint('Cached ${quests.length} quests for user: $userId');
    } catch (e) {
      debugPrint('Failed to cache quests: $e');
    }
  }

  /// Get cached quests
  static List<Quest>? getCachedQuests(String userId) {
    if (_prefs == null) return null;

    try {
      final cachedString = _prefs!.getString('$_questsPrefix$userId');
      if (cachedString == null) return null;

      final cached = jsonDecode(cachedString) as Map<String, dynamic>;
      final questsList = cached['quests'] as List<dynamic>;

      return questsList
          .map((e) => Quest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to get cached quests: $e');
      return null;
    }
  }

  /// Add pending AI request for later sync
  static Future<void> addPendingRequest({
    required String functionName,
    required Map<String, dynamic> params,
  }) async {
    if (_prefs == null) await initialize();

    try {
      final pendingRequestsString = _prefs!.getString(_pendingRequestsKey);
      final pendingRequests = pendingRequestsString != null
          ? jsonDecode(pendingRequestsString) as List<dynamic>
          : [];

      pendingRequests.add({
        'function_name': functionName,
        'params': params,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _prefs!.setString(_pendingRequestsKey, jsonEncode(pendingRequests));

      debugPrint('Added pending AI request: $functionName');
    } catch (e) {
      debugPrint('Failed to add pending request: $e');
    }
  }

  /// Background cache sync when connection restored
  static Future<void> syncPendingAIRequests() async {
    if (_prefs == null) await initialize();

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        debugPrint('No connectivity - skipping sync');
        return;
      }

      final pendingRequestsString = _prefs!.getString(_pendingRequestsKey);
      if (pendingRequestsString == null) return;

      final pendingRequests =
          jsonDecode(pendingRequestsString) as List<dynamic>;
      if (pendingRequests.isEmpty) return;

      debugPrint('Syncing ${pendingRequests.length} pending AI requests');

      final successfulRequests = <int>[];

      for (var i = 0; i < pendingRequests.length; i++) {
        final request = pendingRequests[i] as Map<String, dynamic>;
        try {
          await AIServiceBase.invokeAIFunction(
            request['function_name'] as String,
            request['params'] as Map<String, dynamic>,
          );
          successfulRequests.add(i);
        } catch (e) {
          debugPrint('Failed to sync request $i: $e');
          // Keep in pending queue for retry
        }
      }

      // Remove successful requests
      if (successfulRequests.isNotEmpty) {
        final remainingRequests = <dynamic>[];
        for (var i = 0; i < pendingRequests.length; i++) {
          if (!successfulRequests.contains(i)) {
            remainingRequests.add(pendingRequests[i]);
          }
        }

        await _prefs!.setString(
          _pendingRequestsKey,
          jsonEncode(remainingRequests),
        );

        debugPrint(
          'Synced ${successfulRequests.length} requests, ${remainingRequests.length} remaining',
        );
      }
    } catch (e) {
      debugPrint('Failed to sync pending requests: $e');
    }
  }

  /// Clear all cached data
  static Future<void> clearAllCache() async {
    if (_prefs == null) await initialize();

    try {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith(_consensusPrefix) ||
            key.startsWith(_questsPrefix) ||
            key == _pendingRequestsKey) {
          await _prefs!.remove(key);
        }
      }
      debugPrint('Cleared all AI cache data');
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  /// Get cache statistics
  static Map<String, int> getCacheStats() {
    if (_prefs == null) return {};

    try {
      final keys = _prefs!.getKeys();
      int consensusCount = 0;
      int questsCount = 0;
      int pendingCount = 0;

      for (final key in keys) {
        if (key.startsWith(_consensusPrefix)) consensusCount++;
        if (key.startsWith(_questsPrefix)) questsCount++;
        if (key == _pendingRequestsKey) {
          final pendingString = _prefs!.getString(_pendingRequestsKey);
          if (pendingString != null) {
            final pending = jsonDecode(pendingString) as List<dynamic>;
            pendingCount = pending.length;
          }
        }
      }

      return {
        'consensus_results': consensusCount,
        'cached_quests': questsCount,
        'pending_requests': pendingCount,
      };
    } catch (e) {
      debugPrint('Failed to get cache stats: $e');
      return {};
    }
  }
}
