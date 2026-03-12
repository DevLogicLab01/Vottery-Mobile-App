import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import './supabase_service.dart';
import './auth_service.dart';

/// Enhanced Hive Offline-First Service with 3-way merge conflict resolution
class HiveOfflineService {
  static HiveOfflineService? _instance;
  static HiveOfflineService get instance =>
      _instance ??= HiveOfflineService._();

  HiveOfflineService._();

  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;
  final _connectivity = Connectivity();

  // Hive boxes
  Box<Map<dynamic, dynamic>>? _electionsBox;
  Box<Map<dynamic, dynamic>>? _votesBox;
  Box<Map<dynamic, dynamic>>? _userProfilesBox;
  Box<Map<dynamic, dynamic>>? _aiResponsesBox;
  Box<Map<dynamic, dynamic>>? _syncQueueBox;
  Box<Map<dynamic, dynamic>>? _conflictsBox;
  Box<Map<dynamic, dynamic>>? _ancestorBox;

  bool _isInitialized = false;
  bool _isSyncing = false;

  /// Initialize Hive and open all boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      _electionsBox = await Hive.openBox<Map<dynamic, dynamic>>('elections');
      _votesBox = await Hive.openBox<Map<dynamic, dynamic>>('votes');
      _userProfilesBox = await Hive.openBox<Map<dynamic, dynamic>>(
        'user_profiles',
      );
      _aiResponsesBox = await Hive.openBox<Map<dynamic, dynamic>>(
        'ai_responses',
      );
      _syncQueueBox = await Hive.openBox<Map<dynamic, dynamic>>('sync_queue');
      _conflictsBox = await Hive.openBox<Map<dynamic, dynamic>>('conflicts');
      _ancestorBox = await Hive.openBox<Map<dynamic, dynamic>>(
        'ancestor_states',
      );

      _isInitialized = true;
      debugPrint('Hive offline service initialized');

      // Setup connectivity listener for auto-sync
      _connectivity.onConnectivityChanged.listen((results) {
        if (!results.contains(ConnectivityResult.none) && !_isSyncing) {
          syncAllData();
        }
      });
    } catch (e) {
      debugPrint('Hive initialization error: $e');
    }
  }

  /// Diagnostics: number of cached elections
  int get cachedElectionsCount => _electionsBox?.length ?? 0;

  /// Cache election data
  Future<void> cacheElection(Map<String, dynamic> election) async {
    if (_electionsBox == null) return;

    try {
      final electionId = election['id'];
      await _electionsBox!.put(electionId, {
        ...election,
        'cached_at': DateTime.now().toIso8601String(),
      });

      // Store ancestor state for conflict resolution
      await _ancestorBox?.put('election_$electionId', election);
    } catch (e) {
      debugPrint('Cache election error: $e');
    }
  }

  /// Get cached election
  Map<String, dynamic>? getCachedElection(String electionId) {
    if (_electionsBox == null) return null;

    try {
      final cached = _electionsBox!.get(electionId);
      if (cached == null) return null;

      // Check TTL (7 days)
      final cachedAt = DateTime.tryParse(cached['cached_at'] ?? '');
      if (cachedAt != null && DateTime.now().difference(cachedAt).inDays > 7) {
        _electionsBox!.delete(electionId);
        return null;
      }

      return Map<String, dynamic>.from(cached);
    } catch (e) {
      debugPrint('Get cached election error: $e');
      return null;
    }
  }

  /// Cache vote offline
  Future<void> cacheVote(Map<String, dynamic> vote) async {
    if (_votesBox == null) return;

    try {
      final voteId =
          vote['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      await _votesBox!.put(voteId, {
        ...vote,
        'cached_at': DateTime.now().toIso8601String(),
        'synced': false,
      });

      // Add to sync queue
      await _addToSyncQueue('vote', voteId, vote, priority: 10);
    } catch (e) {
      debugPrint('Cache vote error: $e');
    }
  }

  /// Add item to sync queue
  Future<void> _addToSyncQueue(
    String entityType,
    String entityId,
    Map<String, dynamic> data, {
    int priority = 5,
  }) async {
    if (_syncQueueBox == null) return;

    try {
      final queueId = '${entityType}_$entityId';
      await _syncQueueBox!.put(queueId, {
        'entity_type': entityType,
        'entity_id': entityId,
        'data': data,
        'priority': priority,
        'retry_count': 0,
        'queued_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Add to sync queue error: $e');
    }
  }

  /// Sync all pending data with 3-way merge conflict resolution
  Future<Map<String, dynamic>> syncAllData() async {
    if (_isSyncing || !_isInitialized) {
      return {'success': false, 'message': 'Sync already in progress'};
    }

    _isSyncing = true;

    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _isSyncing = false;
        return {'success': false, 'message': 'No internet connection'};
      }

      if (!_auth.isAuthenticated) {
        _isSyncing = false;
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Get sync queue items sorted by priority
      final queueItems = _syncQueueBox?.values.toList() ?? [];
      queueItems.sort(
        (a, b) => (b['priority'] ?? 0).compareTo(a['priority'] ?? 0),
      );

      int synced = 0;
      int failed = 0;
      int conflicts = 0;

      // Process queue in batches of 50
      for (var i = 0; i < queueItems.length; i += 50) {
        final batch = queueItems.skip(i).take(50).toList();

        for (var item in batch) {
          final result = await _syncItem(item);
          if (result['success'] == true) {
            synced++;
            // Remove from queue
            final queueId = '${item['entity_type']}_${item['entity_id']}';
            await _syncQueueBox?.delete(queueId);
          } else if (result['conflict'] == true) {
            conflicts++;
          } else {
            failed++;
            // Increment retry count
            item['retry_count'] = (item['retry_count'] ?? 0) + 1;
            if (item['retry_count'] < 3) {
              final queueId = '${item['entity_type']}_${item['entity_id']}';
              await _syncQueueBox?.put(queueId, item);
            }
          }
        }
      }

      _isSyncing = false;

      return {
        'success': true,
        'synced': synced,
        'failed': failed,
        'conflicts': conflicts,
      };
    } catch (e) {
      _isSyncing = false;
      debugPrint('Sync all data error: $e');
      return {'success': false, 'message': 'Sync error: $e'};
    }
  }

  /// Sync individual item with 3-way merge
  Future<Map<String, dynamic>> _syncItem(Map<dynamic, dynamic> item) async {
    try {
      final entityType = item['entity_type'];
      final entityId = item['entity_id'];
      final localData = Map<String, dynamic>.from(item['data']);

      // Get server version
      final serverData = await _fetchServerData(entityType, entityId);

      if (serverData == null) {
        // No server version, safe to insert
        await _insertToServer(entityType, localData);
        return {'success': true};
      }

      // Get ancestor version
      final ancestorData = _ancestorBox?.get('${entityType}_$entityId');

      if (ancestorData == null) {
        // No ancestor, use last-write-wins
        final localTimestamp = DateTime.tryParse(localData['updated_at'] ?? '');
        final serverTimestamp = DateTime.tryParse(
          serverData['updated_at'] ?? '',
        );

        if (localTimestamp != null &&
            serverTimestamp != null &&
            localTimestamp.isAfter(serverTimestamp)) {
          await _updateServer(entityType, entityId, localData);
          return {'success': true};
        } else {
          // Server wins, update local
          await _updateLocal(entityType, entityId, serverData);
          return {'success': true};
        }
      }

      // Perform 3-way merge
      final mergeResult = _threeWayMerge(
        Map<String, dynamic>.from(ancestorData),
        localData,
        serverData,
      );

      if (mergeResult['conflict'] == true) {
        // Store conflict for manual resolution
        await _conflictsBox?.put('${entityType}_$entityId', {
          'entity_type': entityType,
          'entity_id': entityId,
          'client_value': localData,
          'server_value': serverData,
          'ancestor_value': ancestorData,
          'created_at': DateTime.now().toIso8601String(),
        });

        return {'success': false, 'conflict': true};
      }

      // Apply merged result
      final mergedData = mergeResult['merged'];
      await _updateServer(entityType, entityId, mergedData);
      await _updateLocal(entityType, entityId, mergedData);
      await _ancestorBox?.put('${entityType}_$entityId', mergedData);

      return {'success': true};
    } catch (e) {
      debugPrint('Sync item error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Three-way merge algorithm
  Map<String, dynamic> _threeWayMerge(
    Map<String, dynamic> ancestor,
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final merged = <String, dynamic>{};
    bool hasConflict = false;

    // Get all keys
    final allKeys = {...ancestor.keys, ...local.keys, ...server.keys};

    for (var key in allKeys) {
      final ancestorValue = ancestor[key];
      final localValue = local[key];
      final serverValue = server[key];

      if (localValue == serverValue) {
        // No conflict, both have same value
        merged[key] = localValue;
      } else if (localValue == ancestorValue) {
        // Local unchanged, server changed
        merged[key] = serverValue;
      } else if (serverValue == ancestorValue) {
        // Server unchanged, local changed
        merged[key] = localValue;
      } else {
        // Both changed differently - conflict
        hasConflict = true;
        // Use server value as default
        merged[key] = serverValue;
      }
    }

    return {'merged': merged, 'conflict': hasConflict};
  }

  /// Fetch data from server
  Future<Map<String, dynamic>?> _fetchServerData(
    String entityType,
    String entityId,
  ) async {
    try {
      final response = await _client
          .from(_getTableName(entityType))
          .select()
          .eq('id', entityId)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      debugPrint('Fetch server data error: $e');
      return null;
    }
  }

  /// Insert data to server
  Future<void> _insertToServer(
    String entityType,
    Map<String, dynamic> data,
  ) async {
    await _client.from(_getTableName(entityType)).insert(data);
  }

  /// Update data on server
  Future<void> _updateServer(
    String entityType,
    String entityId,
    Map<String, dynamic> data,
  ) async {
    await _client
        .from(_getTableName(entityType))
        .update(data)
        .eq('id', entityId);
  }

  /// Update local cache
  Future<void> _updateLocal(
    String entityType,
    String entityId,
    Map<String, dynamic> data,
  ) async {
    final box = _getBox(entityType);
    await box?.put(entityId, data);
  }

  /// Get table name for entity type
  String _getTableName(String entityType) {
    switch (entityType) {
      case 'election':
        return 'elections';
      case 'vote':
        return 'votes';
      case 'profile':
        return 'user_profiles';
      default:
        return entityType;
    }
  }

  /// Get Hive box for entity type
  Box<Map<dynamic, dynamic>>? _getBox(String entityType) {
    switch (entityType) {
      case 'election':
        return _electionsBox;
      case 'vote':
        return _votesBox;
      case 'profile':
        return _userProfilesBox;
      default:
        return null;
    }
  }

  /// Get pending conflicts
  List<Map<String, dynamic>> getPendingConflicts() {
    if (_conflictsBox == null) return [];

    return _conflictsBox!.values
        .map((v) => Map<String, dynamic>.from(v))
        .toList();
  }

  /// Resolve conflict manually
  Future<void> resolveConflict(
    String entityType,
    String entityId,
    Map<String, dynamic> resolvedData,
  ) async {
    try {
      await _updateServer(entityType, entityId, resolvedData);
      await _updateLocal(entityType, entityId, resolvedData);
      await _ancestorBox?.put('${entityType}_$entityId', resolvedData);
      await _conflictsBox?.delete('${entityType}_$entityId');
    } catch (e) {
      debugPrint('Resolve conflict error: $e');
    }
  }

  /// Get sync queue count
  int getSyncQueueCount() {
    return _syncQueueBox?.length ?? 0;
  }

  /// Get conflicts count
  int getConflictsCount() {
    return _conflictsBox?.length ?? 0;
  }

  /// Clean expired cache
  Future<void> cleanExpiredCache() async {
    try {
      // Clean elections cache (7 days TTL)
      if (_electionsBox != null) {
        final keysToDelete = <dynamic>[];
        for (var key in _electionsBox!.keys) {
          final item = _electionsBox!.get(key);
          if (item != null) {
            final cachedAt = DateTime.tryParse(item['cached_at'] ?? '');
            if (cachedAt != null &&
                DateTime.now().difference(cachedAt).inDays > 7) {
              keysToDelete.add(key);
            }
          }
        }
        await _electionsBox!.deleteAll(keysToDelete);
      }

      // Clean AI responses cache (24 hours TTL)
      if (_aiResponsesBox != null) {
        final keysToDelete = <dynamic>[];
        for (var key in _aiResponsesBox!.keys) {
          final item = _aiResponsesBox!.get(key);
          if (item != null) {
            final cachedAt = DateTime.tryParse(item['cached_at'] ?? '');
            if (cachedAt != null &&
                DateTime.now().difference(cachedAt).inHours > 24) {
              keysToDelete.add(key);
            }
          }
        }
        await _aiResponsesBox!.deleteAll(keysToDelete);
      }

      debugPrint('Expired cache cleaned');
    } catch (e) {
      debugPrint('Clean expired cache error: $e');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'elections': _electionsBox?.length ?? 0,
      'votes': _votesBox?.length ?? 0,
      'profiles': _userProfilesBox?.length ?? 0,
      'ai_responses': _aiResponsesBox?.length ?? 0,
      'sync_queue': _syncQueueBox?.length ?? 0,
      'conflicts': _conflictsBox?.length ?? 0,
    };
  }
}
