import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './auth_service.dart';

/// SMS Rate Limiter Service
/// Implements per-user and per-provider rate limiting with intelligent queue management
class SMSRateLimiterService {
  static SMSRateLimiterService? _instance;
  static SMSRateLimiterService get instance =>
      _instance ??= SMSRateLimiterService._();

  SMSRateLimiterService._();

  final _supabase = SupabaseService.instance.client;
  final _auth = AuthService.instance;

  /// Check if user can send SMS (rate limit check)
  Future<bool> canUserSendSMS() async {
    try {
      if (!_auth.isAuthenticated) return false;

      final userId = _auth.currentUser!.id;

      // Get current rate limit
      final limit = await _supabase
          .from('sms_user_rate_limits')
          .select()
          .eq('user_id', userId)
          .gte('period_end', DateTime.now().toIso8601String())
          .maybeSingle();

      if (limit == null) {
        // No limit set, create default (free tier)
        await _createDefaultRateLimit(userId);
        return true;
      }

      return limit['messages_sent'] < limit['limit_amount'];
    } catch (e) {
      debugPrint('Check user rate limit error: $e');
      return false;
    }
  }

  /// Increment user message count
  Future<void> incrementUserMessageCount() async {
    try {
      if (!_auth.isAuthenticated) return;

      final userId = _auth.currentUser!.id;

      await _supabase.rpc(
        'increment_user_message_count',
        params: {'user_id_param': userId},
      );
    } catch (e) {
      debugPrint('Increment message count error: $e');
    }
  }

  /// Get user rate limit info
  Future<Map<String, dynamic>?> getUserRateLimit() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final userId = _auth.currentUser!.id;

      final limit = await _supabase
          .from('sms_user_rate_limits')
          .select()
          .eq('user_id', userId)
          .gte('period_end', DateTime.now().toIso8601String())
          .maybeSingle();

      return limit;
    } catch (e) {
      debugPrint('Get user rate limit error: $e');
      return null;
    }
  }

  /// Update user tier
  Future<bool> updateUserTier(String tier) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final userId = _auth.currentUser!.id;

      // Tier limits
      final limits = {
        'free': 10,
        'pro': 100,
        'business': 1000,
        'enterprise': 999999,
      };

      final limitAmount = limits[tier] ?? 10;

      // Create new rate limit period
      await _supabase.from('sms_user_rate_limits').insert({
        'user_id': userId,
        'tier': tier,
        'messages_sent': 0,
        'limit_amount': limitAmount,
        'period_start': DateTime.now().toIso8601String(),
        'period_end': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Update user tier error: $e');
      return false;
    }
  }

  /// Check provider rate limit
  Future<bool> canProviderSendSMS(String provider) async {
    try {
      // Provider limits (per second)
      final providerLimits = {'telnyx': 200, 'twilio': 100};

      final limitPerSecond = providerLimits[provider] ?? 100;

      // Get current second's count
      final now = DateTime.now();
      final windowStart = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      );

      final currentCount = await _supabase
          .from('sms_provider_rate_limits')
          .select('messages_sent_current_second')
          .eq('provider', provider)
          .eq('window_start', windowStart.toIso8601String())
          .maybeSingle();

      if (currentCount == null) {
        // Create new window
        await _supabase.from('sms_provider_rate_limits').insert({
          'provider': provider,
          'messages_sent_current_second': 0,
          'limit_per_second': limitPerSecond,
          'window_start': windowStart.toIso8601String(),
        });
        return true;
      }

      return currentCount['messages_sent_current_second'] < limitPerSecond;
    } catch (e) {
      debugPrint('Check provider rate limit error: $e');
      return true; // Allow on error
    }
  }

  /// Increment provider message count
  Future<void> incrementProviderMessageCount(String provider) async {
    try {
      final now = DateTime.now();
      final windowStart = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      );

      await _supabase
          .from('sms_provider_rate_limits')
          .update({
            'messages_sent_current_second': _supabase.rpc(
              'increment',
              params: {},
            ),
          })
          .eq('provider', provider)
          .eq('window_start', windowStart.toIso8601String());
    } catch (e) {
      debugPrint('Increment provider count error: $e');
    }
  }

  /// Create default rate limit for new user
  Future<void> _createDefaultRateLimit(String userId) async {
    try {
      await _supabase.from('sms_user_rate_limits').insert({
        'user_id': userId,
        'tier': 'free',
        'messages_sent': 0,
        'limit_amount': 10,
        'period_start': DateTime.now().toIso8601String(),
        'period_end': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String(),
      });
    } catch (e) {
      debugPrint('Create default rate limit error: $e');
    }
  }

  /// Get rate limit statistics
  Future<Map<String, dynamic>> getRateLimitStats() async {
    try {
      // Get all active rate limits
      final limits = await _supabase
          .from('sms_user_rate_limits')
          .select()
          .gte('period_end', DateTime.now().toIso8601String());

      final tierCounts = <String, int>{};
      var totalMessages = 0;
      var totalLimit = 0;

      for (final limit in limits) {
        final tier = limit['tier'] as String;
        tierCounts[tier] = (tierCounts[tier] ?? 0) + 1;
        totalMessages += limit['messages_sent'] as int;
        totalLimit += limit['limit_amount'] as int;
      }

      return {
        'total_users': limits.length,
        'tier_distribution': tierCounts,
        'total_messages_sent': totalMessages,
        'total_limit': totalLimit,
        'utilization_rate': totalLimit > 0
            ? (totalMessages / totalLimit * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      debugPrint('Get rate limit stats error: $e');
      return {};
    }
  }
}

/// SMS Queue Manager Service
/// Manages intelligent queue with priority levels and retry logic
class SMSQueueManagerService {
  static SMSQueueManagerService? _instance;
  static SMSQueueManagerService get instance =>
      _instance ??= SMSQueueManagerService._();

  SMSQueueManagerService._();

  final _supabase = SupabaseService.instance.client;
  final _auth = AuthService.instance;

  /// Enqueue SMS message
  Future<String?> enqueueSMS({
    required String recipientPhone,
    required String messageBody,
    String? messageCategory,
    String priority = 'normal',
    DateTime? scheduledFor,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _supabase
          .from('sms_queue')
          .insert({
            'user_id': _auth.currentUser!.id,
            'recipient_phone': recipientPhone,
            'message_body': messageBody,
            'message_category': messageCategory,
            'priority': priority,
            'status': 'pending',
            'scheduled_for': (scheduledFor ?? DateTime.now()).toIso8601String(),
          })
          .select('queue_id')
          .single();

      return response['queue_id'] as String;
    } catch (e) {
      debugPrint('Enqueue SMS error: $e');
      return null;
    }
  }

  /// Get queue messages
  Future<List<Map<String, dynamic>>> getQueueMessages({
    String? status,
    String? priority,
    int limit = 100,
  }) async {
    try {
      var query = _supabase.from('sms_queue').select();

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
      debugPrint('Get queue messages error: $e');
      return [];
    }
  }

  /// Update message status
  Future<bool> updateMessageStatus({
    required String queueId,
    required String status,
    String? errorMessage,
  }) async {
    try {
      final updates = <String, dynamic>{'status': status};

      if (status == 'sent') {
        updates['sent_at'] = DateTime.now().toIso8601String();
      }
      if (errorMessage != null) {
        updates['error_message'] = errorMessage;
      }

      await _supabase.from('sms_queue').update(updates).eq('queue_id', queueId);

      return true;
    } catch (e) {
      debugPrint('Update message status error: $e');
      return false;
    }
  }

  /// Retry failed message
  Future<bool> retryMessage(String queueId) async {
    try {
      await _supabase
          .from('sms_queue')
          .update({
            'status': 'pending',
            'retry_count': _supabase.rpc('increment', params: {}),
            'error_message': null,
          })
          .eq('queue_id', queueId);

      return true;
    } catch (e) {
      debugPrint('Retry message error: $e');
      return false;
    }
  }

  /// Delete message from queue
  Future<bool> deleteMessage(String queueId) async {
    try {
      await _supabase.from('sms_queue').delete().eq('queue_id', queueId);
      return true;
    } catch (e) {
      debugPrint('Delete message error: $e');
      return false;
    }
  }

  /// Get queue statistics
  Future<Map<String, dynamic>> getQueueStats() async {
    try {
      final messages = await _supabase.from('sms_queue').select();

      final pending = messages.where((m) => m['status'] == 'pending').length;
      final processing = messages
          .where((m) => m['status'] == 'processing')
          .length;
      final sent = messages.where((m) => m['status'] == 'sent').length;
      final failed = messages.where((m) => m['status'] == 'failed').length;

      // Priority distribution
      final critical = messages
          .where((m) => m['priority'] == 'critical')
          .length;
      final high = messages.where((m) => m['priority'] == 'high').length;
      final normal = messages.where((m) => m['priority'] == 'normal').length;

      // Calculate oldest message age
      final pendingMessages = messages
          .where((m) => m['status'] == 'pending')
          .toList();
      DateTime? oldestMessageTime;
      if (pendingMessages.isNotEmpty) {
        oldestMessageTime = DateTime.parse(
          pendingMessages.first['enqueued_at'] as String,
        );
      }

      return {
        'total_messages': messages.length,
        'pending': pending,
        'processing': processing,
        'sent': sent,
        'failed': failed,
        'priority_distribution': {
          'critical': critical,
          'high': high,
          'normal': normal,
        },
        'oldest_message_age_minutes': oldestMessageTime != null
            ? DateTime.now().difference(oldestMessageTime).inMinutes
            : 0,
        'queue_depth': pending + processing,
      };
    } catch (e) {
      debugPrint('Get queue stats error: $e');
      return {};
    }
  }

  /// Bulk retry failed messages
  Future<int> bulkRetryFailed() async {
    try {
      final failedMessages = await _supabase
          .from('sms_queue')
          .select('queue_id')
          .eq('status', 'failed')
          .lt('retry_count', 3);

      var retried = 0;
      for (final message in failedMessages) {
        final success = await retryMessage(message['queue_id'] as String);
        if (success) retried++;
      }

      return retried;
    } catch (e) {
      debugPrint('Bulk retry failed error: $e');
      return 0;
    }
  }

  /// Bulk delete messages
  Future<int> bulkDelete(List<String> queueIds) async {
    try {
      // Remove this line - use inFilter instead of in_
      await _supabase.from('sms_queue').delete().inFilter('queue_id', queueIds);
      return queueIds.length;
    } catch (e) {
      debugPrint('Bulk delete error: $e');
      return 0;
    }
  }
}