import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

/// SMS Rate Limiter Service
/// Implements token bucket algorithm for per-user and per-provider rate limiting
class SMSRateLimiter {
  static SMSRateLimiter? _instance;
  static SMSRateLimiter get instance => _instance ??= SMSRateLimiter._();

  SMSRateLimiter._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // Provider rate limits (messages per second)
  static const int telnyxRateLimit = 200;
  static const int twilioRateLimit = 100;

  // User tier limits (messages per day)
  static const Map<String, int> tierLimits = {
    'free': 10,
    'pro': 100,
    'business': 1000,
    'enterprise': 999999,
  };

  /// Check if user can send SMS (rate limit check)
  Future<bool> canUserSendSMS(String userId) async {
    try {
      final result = await _client.rpc(
        'check_user_rate_limit',
        params: {'p_user_id': userId},
      );

      return result == true;
    } catch (e) {
      debugPrint('Check user rate limit error: $e');
      return false;
    }
  }

  /// Increment user rate limit counter
  Future<void> incrementUserRateLimit(String userId) async {
    try {
      await _client.rpc(
        'increment_user_rate_limit',
        params: {'p_user_id': userId},
      );
    } catch (e) {
      debugPrint('Increment user rate limit error: $e');
    }
  }

  /// Initialize user rate limit for new period
  Future<void> initializeUserRateLimit({
    required String userId,
    required String tier,
  }) async {
    try {
      final limitAmount = tierLimits[tier] ?? tierLimits['free']!;
      final now = DateTime.now();
      final periodEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      await _client.from('sms_user_rate_limits').upsert({
        'user_id': userId,
        'tier': tier,
        'messages_sent': 0,
        'limit_amount': limitAmount,
        'period_start': now.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Initialize user rate limit error: $e');
    }
  }

  /// Get user rate limit status
  Future<Map<String, dynamic>> getUserRateLimitStatus(String userId) async {
    try {
      final response = await _client
          .from('sms_user_rate_limits')
          .select()
          .eq('user_id', userId)
          .gte('period_end', DateTime.now().toIso8601String())
          .order('period_end', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return {
          'messages_sent': 0,
          'limit_amount': tierLimits['free'],
          'remaining': tierLimits['free'],
          'reset_at': DateTime.now()
              .add(const Duration(days: 1))
              .toIso8601String(),
        };
      }

      final messagesSent = response['messages_sent'] as int;
      final limitAmount = response['limit_amount'] as int;

      return {
        'messages_sent': messagesSent,
        'limit_amount': limitAmount,
        'remaining': limitAmount - messagesSent,
        'reset_at': response['period_end'],
        'tier': response['tier'],
      };
    } catch (e) {
      debugPrint('Get user rate limit status error: $e');
      return {};
    }
  }

  /// Check provider rate limit
  Future<bool> canProviderSendSMS(String provider) async {
    try {
      final limit = provider == 'telnyx' ? telnyxRateLimit : twilioRateLimit;

      final response = await _client
          .from('sms_provider_rate_limits')
          .select()
          .eq('provider', provider)
          .gte(
            'window_start',
            DateTime.now()
                .subtract(const Duration(seconds: 1))
                .toIso8601String(),
          )
          .maybeSingle();

      if (response == null) return true;

      final messagesSent = response['messages_sent_current_second'] as int;
      return messagesSent < limit;
    } catch (e) {
      debugPrint('Check provider rate limit error: $e');
      return true;
    }
  }

  /// Increment provider rate limit counter
  Future<void> incrementProviderRateLimit(String provider) async {
    try {
      final limit = provider == 'telnyx' ? telnyxRateLimit : twilioRateLimit;
      final now = DateTime.now();

      await _client.from('sms_provider_rate_limits').upsert({
        'provider': provider,
        'messages_sent_current_second': 1,
        'limit_per_second': limit,
        'window_start': now.toIso8601String(),
      });

      // Increment counter
      await _client.rpc(
        'increment',
        params: {
          'table_name': 'sms_provider_rate_limits',
          'column_name': 'messages_sent_current_second',
          'filter_column': 'provider',
          'filter_value': provider,
        },
      );
    } catch (e) {
      debugPrint('Increment provider rate limit error: $e');
    }
  }

  /// Reset daily user rate limits (scheduled job)
  Future<void> resetDailyRateLimits() async {
    try {
      await _client
          .from('sms_user_rate_limits')
          .update({'messages_sent': 0})
          .lt('period_end', DateTime.now().toIso8601String());

      debugPrint('✅ Daily rate limits reset');
    } catch (e) {
      debugPrint('Reset daily rate limits error: $e');
    }
  }
}

/// SMS Queue Manager Service
/// Implements priority queue with intelligent processing and retry logic
class SMSQueueManager {
  static SMSQueueManager? _instance;
  static SMSQueueManager get instance => _instance ??= SMSQueueManager._();

  SMSQueueManager._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  final _rateLimiter = SMSRateLimiter.instance;

  Timer? _processingTimer;
  bool _isProcessing = false;

  /// Start queue processor
  void startQueueProcessor() {
    if (_processingTimer != null) return;

    _processingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => processQueue(),
    );

    debugPrint('✅ SMS Queue Processor started');
  }

  /// Stop queue processor
  void stopQueueProcessor() {
    _processingTimer?.cancel();
    _processingTimer = null;
    debugPrint('⏹️ SMS Queue Processor stopped');
  }

  /// Enqueue SMS for sending
  Future<String?> enqueueSMS({
    required String recipientPhone,
    required String messageBody,
    String? messageCategory,
    String priority = 'normal',
    DateTime? scheduledFor,
  }) async {
    try {
      final userId = _auth.currentUser?.id;

      final response = await _client
          .from('sms_queue')
          .insert({
            'user_id': userId,
            'recipient_phone': recipientPhone,
            'message_body': messageBody,
            'message_category': messageCategory,
            'priority': priority,
            'scheduled_for': (scheduledFor ?? DateTime.now()).toIso8601String(),
          })
          .select()
          .single();

      return response['queue_id'] as String;
    } catch (e) {
      debugPrint('Enqueue SMS error: $e');
      return null;
    }
  }

  /// Process queue (dequeue and send)
  Future<void> processQueue() async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      // Get pending messages ordered by priority and scheduled time
      final messages = await _client
          .from('sms_queue')
          .select()
          .eq('status', 'pending')
          .lte('scheduled_for', DateTime.now().toIso8601String())
          .order('priority', ascending: false)
          .order('scheduled_for', ascending: true)
          .limit(100);

      for (final message in messages) {
        await _processMessage(message);
      }
    } catch (e) {
      debugPrint('Process queue error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Process individual message
  Future<void> _processMessage(Map<String, dynamic> message) async {
    try {
      final queueId = message['queue_id'] as String;
      final userId = message['user_id'] as String?;
      final recipientPhone = message['recipient_phone'] as String;
      final messageBody = message['message_body'] as String;

      // Update status to processing
      await _client
          .from('sms_queue')
          .update({'status': 'processing'})
          .eq('queue_id', queueId);

      // Check rate limits
      if (userId != null) {
        final canSend = await _rateLimiter.canUserSendSMS(userId);
        if (!canSend) {
          // Reschedule for next day
          await _client
              .from('sms_queue')
              .update({
                'status': 'pending',
                'scheduled_for': DateTime.now()
                    .add(const Duration(days: 1))
                    .toIso8601String(),
              })
              .eq('queue_id', queueId);
          return;
        }
      }

      // TODO: Send SMS via UnifiedSMSService
      // For now, mark as sent
      await _client
          .from('sms_queue')
          .update({
            'status': 'sent',
            'sent_at': DateTime.now().toIso8601String(),
          })
          .eq('queue_id', queueId);

      // Increment rate limit
      if (userId != null) {
        await _rateLimiter.incrementUserRateLimit(userId);
      }
    } catch (e) {
      debugPrint('Process message error: $e');
      await _handleMessageFailure(message, e.toString());
    }
  }

  /// Handle message failure with retry logic
  Future<void> _handleMessageFailure(
    Map<String, dynamic> message,
    String error,
  ) async {
    try {
      final queueId = message['queue_id'] as String;
      final retryCount = (message['retry_count'] as int?) ?? 0;

      if (retryCount >= 3) {
        // Max retries reached, move to failed
        await _client
            .from('sms_queue')
            .update({'status': 'failed', 'error_message': error})
            .eq('queue_id', queueId);
      } else {
        // Retry with exponential backoff
        final backoffMinutes = [1, 5, 15][retryCount];
        await _client
            .from('sms_queue')
            .update({
              'status': 'pending',
              'retry_count': retryCount + 1,
              'scheduled_for': DateTime.now()
                  .add(Duration(minutes: backoffMinutes))
                  .toIso8601String(),
              'error_message': error,
            })
            .eq('queue_id', queueId);
      }
    } catch (e) {
      debugPrint('Handle message failure error: $e');
    }
  }

  /// Get queue statistics
  Future<Map<String, dynamic>> getQueueStatistics() async {
    try {
      final pending = await _client
          .from('sms_queue')
          .select('queue_id')
          .eq('status', 'pending');

      final processing = await _client
          .from('sms_queue')
          .select('queue_id')
          .eq('status', 'processing');

      final failed = await _client
          .from('sms_queue')
          .select('queue_id')
          .eq('status', 'failed');

      // Get oldest pending message
      final oldestPending = await _client
          .from('sms_queue')
          .select('enqueued_at')
          .eq('status', 'pending')
          .order('enqueued_at', ascending: true)
          .limit(1)
          .maybeSingle();

      return {
        'pending_count': pending.length,
        'processing_count': processing.length,
        'failed_count': failed.length,
        'oldest_pending_age': oldestPending != null
            ? DateTime.now()
                  .difference(DateTime.parse(oldestPending['enqueued_at']))
                  .inMinutes
            : 0,
      };
    } catch (e) {
      debugPrint('Get queue statistics error: $e');
      return {};
    }
  }

  /// Get queued messages
  Future<List<Map<String, dynamic>>> getQueuedMessages({
    String? status,
    String? priority,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('sms_queue').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      if (priority != null) {
        query = query.eq('priority', priority);
      }

      final response = await query
          .order('priority', ascending: false)
          .order('scheduled_for', ascending: true)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get queued messages error: $e');
      return [];
    }
  }

  /// Retry failed message
  Future<bool> retryFailedMessage(String queueId) async {
    try {
      await _client
          .from('sms_queue')
          .update({
            'status': 'pending',
            'retry_count': 0,
            'scheduled_for': DateTime.now().toIso8601String(),
            'error_message': null,
          })
          .eq('queue_id', queueId);

      return true;
    } catch (e) {
      debugPrint('Retry failed message error: $e');
      return false;
    }
  }

  /// Delete message from queue
  Future<bool> deleteQueuedMessage(String queueId) async {
    try {
      await _client.from('sms_queue').delete().eq('queue_id', queueId);
      return true;
    } catch (e) {
      debugPrint('Delete queued message error: $e');
      return false;
    }
  }

  /// Bulk retry failed messages
  Future<int> bulkRetryFailedMessages() async {
    try {
      final result = await _client
          .from('sms_queue')
          .update({
            'status': 'pending',
            'retry_count': 0,
            'scheduled_for': DateTime.now().toIso8601String(),
            'error_message': null,
          })
          .eq('status', 'failed')
          .select('queue_id');

      return result.length;
    } catch (e) {
      debugPrint('Bulk retry failed messages error: $e');
      return 0;
    }
  }

  /// Change message priority
  Future<bool> changeMessagePriority(String queueId, String newPriority) async {
    try {
      await _client
          .from('sms_queue')
          .update({'priority': newPriority})
          .eq('queue_id', queueId);

      return true;
    } catch (e) {
      debugPrint('Change message priority error: $e');
      return false;
    }
  }
}