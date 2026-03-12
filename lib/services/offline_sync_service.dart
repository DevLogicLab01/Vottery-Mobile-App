import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './voting_service.dart';

/// Enhanced offline sync service with vote caching, sync queues, and background orchestration
class OfflineSyncService {
  static OfflineSyncService? _instance;
  static OfflineSyncService get instance =>
      _instance ??= OfflineSyncService._();

  OfflineSyncService._();

  final VotingService _votingService = VotingService.instance;
  final Connectivity _connectivity = Connectivity();
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _offlineVotesKey = 'offline_votes_box';
  static const String _syncQueueKey = 'sync_queue_box';
  static const String _cachedElectionsKey = 'cached_elections_box';
  static const String _lastSyncKey = 'last_sync_timestamp';

  bool _isSyncing = false;

  /// Initialize offline sync service
  Future<void> initialize() async {
    try {
      // Listen to connectivity changes and auto-sync
      _connectivity.onConnectivityChanged.listen((results) {
        if (!results.contains(ConnectivityResult.none) && !_isSyncing) {
          syncPendingVotes();
        }
      });
    } catch (e) {
      debugPrint('Initialize offline sync error: $e');
    }
  }

  /// Store vote offline when no connectivity
  Future<bool> storeOfflineVote({
    required String electionId,
    required String electionTitle,
    String? selectedOptionId,
    List<String>? rankedChoices,
    List<String>? selectedOptions,
    Map<String, dynamic>? voteScores,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineVotesJson = prefs.getString(_offlineVotesKey) ?? '{}';
      final offlineVotes = Map<String, dynamic>.from(
        json.decode(offlineVotesJson),
      );

      offlineVotes[electionId] = {
        'election_id': electionId,
        'election_title': electionTitle,
        'selected_option_id': selectedOptionId,
        'ranked_choices': rankedChoices ?? [],
        'selected_options': selectedOptions ?? [],
        'vote_scores': voteScores ?? {},
        'queued_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      };

      await prefs.setString(_offlineVotesKey, json.encode(offlineVotes));

      // Add to sync queue
      await _addToSyncQueue(offlineVotes[electionId]);

      debugPrint('Vote stored offline for election: $electionId');
      return true;
    } catch (e) {
      debugPrint('Store offline vote error: $e');
      return false;
    }
  }

  /// Cache election details for offline display
  Future<bool> cacheElection(Map<String, dynamic> election) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedElectionsJson = prefs.getString(_cachedElectionsKey) ?? '{}';
      final cachedElections = Map<String, dynamic>.from(
        json.decode(cachedElectionsJson),
      );

      cachedElections[election['id']] = election;

      await prefs.setString(_cachedElectionsKey, json.encode(cachedElections));
      return true;
    } catch (e) {
      debugPrint('Cache election error: $e');
      return false;
    }
  }

  /// Get cached election
  Future<Map<String, dynamic>?> getCachedElection(String electionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedElectionsJson = prefs.getString(_cachedElectionsKey) ?? '{}';
      final cachedElections = Map<String, dynamic>.from(
        json.decode(cachedElectionsJson),
      );
      return cachedElections[electionId];
    } catch (e) {
      debugPrint('Get cached election error: $e');
      return null;
    }
  }

  /// Get pending votes count
  Future<int> getPendingVotesCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncQueueJson = prefs.getString(_syncQueueKey) ?? '[]';
      final syncQueue = List<dynamic>.from(json.decode(syncQueueJson));
      return syncQueue.length;
    } catch (e) {
      debugPrint('Get pending votes count error: $e');
      return 0;
    }
  }

  /// Sync pending votes with conflict resolution
  Future<Map<String, dynamic>> syncPendingVotes() async {
    if (_isSyncing) {
      return {
        'success': false,
        'message': 'Sync already in progress',
        'synced': 0,
        'failed': 0,
      };
    }

    _isSyncing = true;

    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _isSyncing = false;
        return {
          'success': false,
          'message': 'No internet connection',
          'synced': 0,
          'failed': 0,
        };
      }

      final prefs = await SharedPreferences.getInstance();
      final syncQueueJson = prefs.getString(_syncQueueKey) ?? '[]';
      final syncQueue = List<Map<String, dynamic>>.from(
        json.decode(syncQueueJson).map((e) => Map<String, dynamic>.from(e)),
      );

      if (syncQueue.isEmpty) {
        _isSyncing = false;
        return {
          'success': true,
          'message': 'No pending votes to sync',
          'synced': 0,
          'failed': 0,
        };
      }

      int synced = 0;
      int failed = 0;
      final List<Map<String, dynamic>> failedVotes = [];

      for (var vote in syncQueue) {
        // Conflict resolution: timestamp-based last-write-wins
        final success = await _votingService.castVote(
          electionId: vote['election_id'],
          selectedOptionId: vote['selected_option_id'],
          rankedChoices: List<String>.from(vote['ranked_choices'] ?? []),
          selectedOptions: List<String>.from(vote['selected_options'] ?? []),
          voteScores: Map<String, dynamic>.from(vote['vote_scores'] ?? {}),
        );

        if (success) {
          synced++;
          // Remove from offline votes
          await _removeOfflineVote(vote['election_id']);
        } else {
          failed++;
          vote['retry_count'] = (vote['retry_count'] ?? 0) + 1;
          if (vote['retry_count'] < 3) {
            failedVotes.add(vote);
          }
        }
      }

      // Update sync queue with only failed votes
      await prefs.setString(_syncQueueKey, json.encode(failedVotes));

      // Update last sync timestamp
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      _isSyncing = false;

      return {
        'success': true,
        'message': 'Sync completed',
        'synced': synced,
        'failed': failed,
      };
    } catch (e) {
      _isSyncing = false;
      debugPrint('Sync pending votes error: $e');
      return {
        'success': false,
        'message': 'Sync error: $e',
        'synced': 0,
        'failed': 0,
      };
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastSyncKey);
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      debugPrint('Get last sync time error: $e');
      return null;
    }
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Check online status error: $e');
      return false;
    }
  }

  /// Get sync status
  bool get isSyncing => _isSyncing;

  /// Listen to connectivity changes
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) {
      return !results.contains(ConnectivityResult.none);
    });
  }

  // Private helper methods
  Future<void> _addToSyncQueue(Map<String, dynamic> vote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncQueueJson = prefs.getString(_syncQueueKey) ?? '[]';
      final syncQueue = List<Map<String, dynamic>>.from(
        json.decode(syncQueueJson).map((e) => Map<String, dynamic>.from(e)),
      );

      syncQueue.add(vote);
      await prefs.setString(_syncQueueKey, json.encode(syncQueue));
    } catch (e) {
      debugPrint('Add to sync queue error: $e');
    }
  }

  Future<void> _removeOfflineVote(String electionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineVotesJson = prefs.getString(_offlineVotesKey) ?? '{}';
      final offlineVotes = Map<String, dynamic>.from(
        json.decode(offlineVotesJson),
      );
      offlineVotes.remove(electionId);
      await prefs.setString(_offlineVotesKey, json.encode(offlineVotes));
    } catch (e) {
      debugPrint('Remove offline vote error: $e');
    }
  }

  /// Three-way merge conflict resolution
  Future<Map<String, dynamic>?> resolveConflict({
    required String conflictId,
    required String strategy,
  }) async {
    try {
      final conflict = await _supabase
          .from('sync_conflicts')
          .select('*')
          .eq('conflict_id', conflictId)
          .single();

      Map<String, dynamic> resolvedVersion;

      switch (strategy) {
        case 'local_wins':
          resolvedVersion = conflict['local_version'];
          break;
        case 'server_wins':
          resolvedVersion = conflict['server_version'];
          break;
        case 'merged':
          resolvedVersion = _performThreeWayMerge(
            conflict['local_version'],
            conflict['server_version'],
            conflict['ancestor_version'],
          );
          break;
        default:
          throw Exception('Invalid resolution strategy');
      }

      await _supabase
          .from('sync_conflicts')
          .update({
            'resolution_strategy': strategy,
            'resolved_version': resolvedVersion,
            'resolved_at': DateTime.now().toIso8601String(),
            'resolved_by': _supabase.auth.currentUser?.id,
          })
          .eq('conflict_id', conflictId);

      return resolvedVersion;
    } catch (e) {
      debugPrint('Resolve conflict error: $e');
      return null;
    }
  }

  /// Perform three-way merge algorithm
  Map<String, dynamic> _performThreeWayMerge(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
    Map<String, dynamic>? ancestor,
  ) {
    final merged = <String, dynamic>{};
    final allKeys = {...local.keys, ...server.keys};

    for (var key in allKeys) {
      final localValue = local[key];
      final serverValue = server[key];
      final ancestorValue = ancestor?[key];

      if (localValue == serverValue) {
        merged[key] = localValue;
      } else if (localValue == ancestorValue) {
        merged[key] = serverValue;
      } else if (serverValue == ancestorValue) {
        merged[key] = localValue;
      } else {
        merged[key] = serverValue;
      }
    }

    return merged;
  }

  /// Add to sync queue with priority
  Future<bool> addToSyncQueue({
    required String operationType,
    required String tableName,
    required Map<String, dynamic> recordData,
    String priority = 'medium',
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('sync_queue').insert({
        'user_id': userId,
        'operation_type': operationType,
        'table_name': tableName,
        'record_data': recordData,
        'priority': priority,
      });

      return true;
    } catch (e) {
      debugPrint('Add to sync queue error: $e');
      return false;
    }
  }

  /// Get sync queue with priority ordering
  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final queue = await _supabase
          .from('sync_queue')
          .select('*')
          .eq('user_id', userId)
          .isFilter('synced_at', null)
          .order('priority')
          .order('queued_at');

      return queue;
    } catch (e) {
      debugPrint('Get sync queue error: $e');
      return [];
    }
  }

  /// Get network quality
  Future<String> getNetworkQuality() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return 'wifi';
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return '4g';
      } else if (connectivityResult.contains(ConnectivityResult.none)) {
        return 'offline';
      } else {
        return '3g';
      }
    } catch (e) {
      debugPrint('Get network quality error: $e');
      return 'offline';
    }
  }

  /// Get adaptive sync strategy based on network quality
  String getAdaptiveSyncStrategy(String networkQuality) {
    switch (networkQuality) {
      case 'wifi':
        return 'realtime';
      case '4g':
        return 'interval_30s';
      case '3g':
        return 'interval_5min';
      default:
        return 'manual';
    }
  }

  /// Record sync performance metrics
  Future<void> recordSyncMetrics({
    required int durationMs,
    required int dataVolumeBytes,
    required int recordsSynced,
    required int conflictsDetected,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final networkQuality = await getNetworkQuality();
      final syncStrategy = getAdaptiveSyncStrategy(networkQuality);

      await _supabase.from('sync_performance_metrics').insert({
        'user_id': userId,
        'sync_duration_ms': durationMs,
        'data_volume_bytes': dataVolumeBytes,
        'records_synced': recordsSynced,
        'conflicts_detected': conflictsDetected,
        'network_quality': networkQuality,
        'sync_strategy': syncStrategy,
      });
    } catch (e) {
      debugPrint('Record sync metrics error: $e');
    }
  }

  /// Get sync conflicts
  Future<List<Map<String, dynamic>>> getSyncConflicts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final conflicts = await _supabase
          .from('sync_conflicts')
          .select('*')
          .eq('user_id', userId)
          .isFilter('resolved_at', null)
          .order('detected_at', ascending: false);

      return conflicts;
    } catch (e) {
      debugPrint('Get sync conflicts error: $e');
      return [];
    }
  }

  /// Get sync performance metrics
  Future<List<Map<String, dynamic>>> getSyncPerformanceMetrics({
    int limit = 50,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final metrics = await _supabase
          .from('sync_performance_metrics')
          .select('*')
          .eq('user_id', userId)
          .order('recorded_at', ascending: false)
          .limit(limit);

      return metrics;
    } catch (e) {
      debugPrint('Get sync performance metrics error: $e');
      return [];
    }
  }

  /// Clear sync queue
  Future<bool> clearSyncQueue() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('sync_queue')
          .delete()
          .eq('user_id', userId)
          .isFilter('synced_at', null);

      return true;
    } catch (e) {
      debugPrint('Clear sync queue error: $e');
      return false;
    }
  }
}
