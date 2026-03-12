import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './supabase_service.dart';

/// Offline Content Cache Service
/// Comprehensive offline-first architecture for all 9 content types
class OfflineContentCacheService {
  static OfflineContentCacheService? _instance;
  static OfflineContentCacheService get instance =>
      _instance ??= OfflineContentCacheService._();

  OfflineContentCacheService._();

  final _supabase = SupabaseService.instance.client;
  bool _isOnline = true;
  bool _isSyncing = false;

  final StreamController<bool> _connectivityStream =
      StreamController.broadcast();
  final StreamController<SyncProgressEvent> _syncProgressStream =
      StreamController.broadcast();

  Stream<bool> get connectivityStream => _connectivityStream.stream;
  Stream<SyncProgressEvent> get syncProgressStream =>
      _syncProgressStream.stream;
  bool get isOnline => _isOnline;

  static const Map<String, Duration> _cacheDurations = {
    'jolts': Duration(hours: 24),
    'moments': Duration(hours: 24),
    'creator_spotlights': Duration(hours: 48),
    'groups': Duration(hours: 24),
    'elections': Duration(hours: 12),
    'services': Duration(hours: 48),
    'topics': Duration(hours: 12),
    'earners': Duration(hours: 1),
    'champions': Duration(hours: 6),
    'load_test_history': Duration(hours: 6),
  };

  /// Initialize offline cache
  Future<void> initialize() async {
    debugPrint('✅ OfflineContentCache initialized for 9 content types');
  }

  /// Cache content item
  Future<void> cacheContent({
    required String contentType,
    required String contentId,
    required Map<String, dynamic> data,
    String? userId,
  }) async {
    try {
      final key = _cacheKey(contentType, contentId);
      final prefs = await SharedPreferences.getInstance();
      final cacheEntry = {
        'content_type': contentType,
        'content_id': contentId,
        'data': data,
        'cached_at': DateTime.now().toIso8601String(),
        'user_id': userId,
      };
      await prefs.setString(key, jsonEncode(cacheEntry));

      // Also persist to Supabase if online
      if (_isOnline && userId != null) {
        try {
          await _supabase.from('content_offline_cache').upsert({
            'user_id': userId,
            'content_type': contentType,
            'content_id': contentId,
            'content_data': data,
            'cached_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Supabase cache persist error: $e');
        }
      }
    } catch (e) {
      debugPrint('Cache content error: $e');
    }
  }

  /// Get cached content
  Future<Map<String, dynamic>?> getCachedContent({
    required String contentType,
    required String contentId,
  }) async {
    try {
      final key = _cacheKey(contentType, contentId);
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      if (cached == null) return null;

      final entry = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(entry['cached_at'] as String);
      final maxAge = _cacheDurations[contentType] ?? const Duration(hours: 24);

      if (DateTime.now().difference(cachedAt) > maxAge) {
        // Mark as stale but still return
        entry['is_stale'] = true;
      }

      return entry['data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Get cached content error: $e');
      return null;
    }
  }

  /// Queue operation for sync when online
  Future<void> queueOperation({
    required String operationType,
    required Map<String, dynamic> payload,
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueKey = 'sync_queue_${DateTime.now().millisecondsSinceEpoch}';
      final operation = {
        'operation_type': operationType,
        'payload': payload,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
        'retry_count': 0,
      };
      await prefs.setString(queueKey, jsonEncode(operation));

      // Also persist to Supabase if online
      if (_isOnline) {
        try {
          await _supabase.from('offline_sync_queue').insert({
            'user_id': userId,
            'operation_type': operationType,
            'operation_payload': payload,
            'status': 'pending',
          });
        } catch (e) {
          debugPrint('Queue persist error: $e');
        }
      }

      debugPrint('📥 Queued operation: $operationType');
    } catch (e) {
      debugPrint('Queue operation error: $e');
    }
  }

  /// Process pending sync queue when online
  Future<void> processSyncQueue(String? userId) async {
    if (!_isOnline || _isSyncing) return;
    _isSyncing = true;

    try {
      final pending = await _supabase
          .from('offline_sync_queue')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true)
          .limit(50);

      int processed = 0;
      for (final op in pending) {
        try {
          await _supabase
              .from('offline_sync_queue')
              .update({'status': 'processing'})
              .eq('queue_id', op['queue_id']);

          // Execute the operation
          await _executeOperation(op);

          await _supabase
              .from('offline_sync_queue')
              .update({'status': 'completed'})
              .eq('queue_id', op['queue_id']);

          processed++;
          _syncProgressStream.add(
            SyncProgressEvent(
              total: pending.length,
              processed: processed,
              operationType: op['operation_type'] as String,
            ),
          );
        } catch (e) {
          final retryCount = (op['retry_count'] as int? ?? 0) + 1;
          await _supabase
              .from('offline_sync_queue')
              .update({
                'status': retryCount >= 3 ? 'failed' : 'pending',
                'retry_count': retryCount,
              })
              .eq('queue_id', op['queue_id']);
        }
      }

      if (processed > 0) {
        debugPrint('✅ Synced $processed operations');
      }
    } catch (e) {
      debugPrint('Sync queue error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _executeOperation(Map<String, dynamic> op) async {
    final type = op['operation_type'] as String;
    final payload = op['operation_payload'] as Map<String, dynamic>;

    switch (type) {
      case 'cast_vote':
        await _supabase.from('votes').insert(payload);
        break;
      case 'join_group':
        await _supabase.from('group_members').insert(payload);
        break;
      case 'create_moment':
        await _supabase.from('moments').insert(payload);
        break;
      case 'follow_topic':
        await _supabase.from('user_topic_preferences').insert(payload);
        break;
      default:
        debugPrint('Unknown operation type: $type');
    }
  }

  /// Update connectivity status
  void setConnectivity(bool isOnline) {
    final wasOffline = !_isOnline;
    _isOnline = isOnline;
    _connectivityStream.add(isOnline);

    if (isOnline && wasOffline) {
      debugPrint('🌐 Back online - starting sync...');
      // Auto-sync when connectivity restored
      processSyncQueue(null);
    }
  }

  String _cacheKey(String contentType, String contentId) {
    return 'offline_cache_${contentType}_$contentId';
  }

  void dispose() {
    _connectivityStream.close();
    _syncProgressStream.close();
  }
}

class SyncProgressEvent {
  final int total;
  final int processed;
  final String operationType;

  const SyncProgressEvent({
    required this.total,
    required this.processed,
    required this.operationType,
  });
}
