import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MessagePriority { critical, high, normal }

class QueuedMessage {
  final String id;
  final String conversationId;
  final String content;
  final MessagePriority priority;
  final DateTime queuedAt;
  final Map<String, dynamic> payload;

  const QueuedMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.priority,
    required this.queuedAt,
    required this.payload,
  });
}

class MessageQueueService {
  static MessageQueueService? _instance;
  static MessageQueueService get instance =>
      _instance ??= MessageQueueService._();

  MessageQueueService._() {
    _initConnectivityMonitoring();
  }

  final SupabaseClient _supabase = Supabase.instance.client;
  final List<QueuedMessage> _localQueue = [];
  bool _isOnline = true;
  bool _isProcessing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool get isOnline => _isOnline;
  int get queuedCount => _localQueue.length;

  void _initConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (wasOffline && _isOnline) {
        // Reconnected - process queue
        processOfflineQueue();
      }
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then((results) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      _isOnline = result != ConnectivityResult.none;
    });
  }

  /// Queue a message for offline sending
  Future<QueuedMessage> queueMessage({
    required String conversationId,
    required String content,
    MessagePriority priority = MessagePriority.normal,
    Map<String, dynamic>? additionalPayload,
  }) async {
    final message = QueuedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      content: content,
      priority: priority,
      queuedAt: DateTime.now(),
      payload: {
        'conversation_id': conversationId,
        'content': content,
        'priority': priority.name,
        ...?additionalPayload,
      },
    );

    // Add to local queue
    _localQueue.add(message);

    // Also store in Supabase offline_sync_queue
    try {
      await _supabase.from('offline_sync_queue').insert({
        'operation_type': 'send_message',
        'payload': message.payload,
        'priority_level': priority.name,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Keep in local queue even if Supabase insert fails
    }

    return message;
  }

  /// Process all queued messages when back online
  Future<Map<String, dynamic>> processOfflineQueue() async {
    if (_isProcessing || !_isOnline) {
      return {'success': false, 'processed': 0, 'failed': 0};
    }

    _isProcessing = true;
    int processed = 0;
    int failed = 0;

    try {
      // Fetch pending messages from Supabase
      final pending = await _supabase
          .from('offline_sync_queue')
          .select()
          .eq('operation_type', 'send_message')
          .eq('status', 'pending')
          .order('priority_level', ascending: true) // critical first
          .order('created_at', ascending: true);

      final messages = pending as List;

      // Sort: critical > high > normal
      messages.sort((a, b) {
        final priorityOrder = {'critical': 0, 'high': 1, 'normal': 2};
        final aPriority = priorityOrder[a['priority_level']] ?? 2;
        final bPriority = priorityOrder[b['priority_level']] ?? 2;
        return aPriority.compareTo(bPriority);
      });

      for (final msg in messages) {
        try {
          final payload = msg['payload'] as Map<String, dynamic>? ?? {};
          final conversationId = payload['conversation_id'] as String? ?? '';
          final content = payload['content'] as String? ?? '';

          if (conversationId.isNotEmpty && content.isNotEmpty) {
            // Send via messaging service
            await _supabase.from('messages').insert({
              'conversation_id': conversationId,
              'content': content,
              'created_at': DateTime.now().toIso8601String(),
              'is_synced': true,
            });

            // Mark as sent
            await _supabase
                .from('offline_sync_queue')
                .update({'status': 'sent'})
                .eq('id', msg['id']);

            processed++;
          }
        } catch (e) {
          failed++;
        }
      }

      // Clear local queue
      _localQueue.clear();
    } catch (e) {
      // Silent fail
    } finally {
      _isProcessing = false;
    }

    return {'success': true, 'processed': processed, 'failed': failed};
  }

  /// Get count of pending messages
  Future<int> getPendingCount() async {
    try {
      final result = await _supabase
          .from('offline_sync_queue')
          .select('id')
          .eq('status', 'pending')
          .eq('operation_type', 'send_message');
      return (result as List).length;
    } catch (e) {
      return _localQueue.length;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
