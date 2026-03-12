import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './twilio_notification_service.dart';

class PayoutManagementService {
  static PayoutManagementService? _instance;
  static PayoutManagementService get instance =>
      _instance ??= PayoutManagementService._();

  PayoutManagementService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  TwilioNotificationService get _twilio => TwilioNotificationService.instance;

  /// Get payout schedule configuration for creator
  Future<Map<String, dynamic>> getPayoutSchedule() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultSchedule();

      final response = await _client
          .from('payout_notification_preferences')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .maybeSingle();

      if (response == null) return _getDefaultSchedule();

      return {
        'schedule_type': response['schedule_type'] ?? 'weekly',
        'minimum_threshold': response['minimum_threshold'] ?? 25.0,
        'next_payout_date': response['next_payout_date'],
        'notify_on_initiated': response['notify_on_initiated'] ?? true,
        'notify_on_completed': response['notify_on_completed'] ?? true,
        'notify_on_failed': response['notify_on_failed'] ?? true,
        'email_enabled': response['email_enabled'] ?? true,
        'sms_enabled': response['sms_enabled'] ?? false,
      };
    } catch (e) {
      debugPrint('Get payout schedule error: $e');
      return _getDefaultSchedule();
    }
  }

  /// Update payout schedule configuration
  Future<bool> updatePayoutSchedule({
    required String scheduleType,
    required double minimumThreshold,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Calculate next payout date based on schedule type
      final now = DateTime.now();
      DateTime nextPayoutDate;

      if (scheduleType == 'weekly') {
        // Next Monday
        final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
        nextPayoutDate = now.add(
          Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday),
        );
      } else {
        // First day of next month
        nextPayoutDate = DateTime(now.year, now.month + 1, 1);
      }

      await _client.from('payout_notification_preferences').upsert({
        'creator_id': _auth.currentUser!.id,
        'schedule_type': scheduleType,
        'minimum_threshold': minimumThreshold,
        'next_payout_date': nextPayoutDate.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Update payout schedule error: $e');
      return false;
    }
  }

  /// Get failed payouts requiring retry
  Future<List<Map<String, dynamic>>> getFailedPayouts() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('stripe_payouts')
          .select('*, payout_retry_attempts(*)')
          .eq('creator_id', _auth.currentUser!.id)
          .eq('status', 'failed')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get failed payouts error: $e');
      return [];
    }
  }

  /// Get retry attempts for a specific payout
  Future<List<Map<String, dynamic>>> getRetryAttempts(String payoutId) async {
    try {
      final response = await _client
          .from('payout_retry_attempts')
          .select()
          .eq('payout_id', payoutId)
          .order('attempt_number', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get retry attempts error: $e');
      return [];
    }
  }

  /// Manually retry failed payout (admin authorization required)
  Future<bool> retryFailedPayout(String payoutId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Get current retry count
      final attempts = await getRetryAttempts(payoutId);
      final attemptNumber = attempts.length + 1;

      if (attemptNumber > 3) {
        debugPrint('Maximum retry attempts (3) exceeded');
        return false;
      }

      // Create retry attempt record
      await _client.from('payout_retry_attempts').insert({
        'payout_id': payoutId,
        'attempt_number': attemptNumber,
        'attempted_at': DateTime.now().toIso8601String(),
        'status': 'retrying',
        'next_retry_at': _calculateNextRetryDate(
          attemptNumber,
        ).toIso8601String(),
      });

      // Send notification
      await _sendPayoutNotification(
        payoutId: payoutId,
        eventType: 'retry_initiated',
        message: 'Payout retry attempt $attemptNumber initiated',
      );

      return true;
    } catch (e) {
      debugPrint('Retry failed payout error: $e');
      return false;
    }
  }

  /// Get payout history with pagination
  Future<Map<String, dynamic>> getPayoutHistory({
    int page = 1,
    int limit = 50,
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'payouts': [], 'total': 0, 'page': page, 'limit': limit};
      }

      var query = _client
          .from('stripe_payouts')
          .select('*')
          .eq('creator_id', _auth.currentUser!.id);

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      // Get total count separately
      final countQuery = _client
          .from('stripe_payouts')
          .select('id')
          .eq('creator_id', _auth.currentUser!.id);

      final countResponse = await countQuery;
      final totalCount = (countResponse as List).length;

      return {
        'payouts': List<Map<String, dynamic>>.from(response),
        'total': totalCount,
        'page': page,
        'limit': limit,
      };
    } catch (e) {
      debugPrint('Get payout history error: $e');
      return {'payouts': [], 'total': 0, 'page': page, 'limit': limit};
    }
  }

  /// Get payout analytics (success rate, processing time, failure reasons)
  Future<Map<String, dynamic>> getPayoutAnalytics() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultAnalytics();

      final response = await _client.rpc(
        'get_payout_analytics',
        params: {'p_creator_id': _auth.currentUser!.id},
      );

      if (response == null) return _getDefaultAnalytics();

      return {
        'success_rate': response['success_rate'] ?? 0.0,
        'average_processing_time_hours': response['avg_processing_time'] ?? 0.0,
        'total_payouts_this_month': response['total_this_month'] ?? 0,
        'pending_count': response['pending_count'] ?? 0,
        'failed_count': response['failed_count'] ?? 0,
        'failure_reasons': response['failure_reasons'] ?? {},
        'processing_time_trend': response['processing_time_trend'] ?? [],
      };
    } catch (e) {
      debugPrint('Get payout analytics error: $e');
      return _getDefaultAnalytics();
    }
  }

  /// Stream real-time payout status updates
  Stream<List<Map<String, dynamic>>> streamPayoutStatus() {
    if (!_auth.isAuthenticated) {
      return Stream.value([]);
    }

    return _client
        .from('stripe_payouts')
        .stream(primaryKey: ['id'])
        .eq('creator_id', _auth.currentUser!.id)
        .order('created_at', ascending: false)
        .limit(20)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Get bulk payout processing queue (admin only)
  Future<List<Map<String, dynamic>>> getBulkPayoutQueue() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('stripe_payouts')
          .select('*, creator:user_profiles(id, full_name, email)')
          .eq('status', 'pending')
          .order('created_at', ascending: true)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get bulk payout queue error: $e');
      return [];
    }
  }

  /// Process bulk payouts (admin only)
  Future<Map<String, dynamic>> processBulkPayouts(
    List<String> payoutIds,
  ) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': 0, 'failed': 0, 'errors': []};
      }

      int successCount = 0;
      int failedCount = 0;
      List<String> errors = [];

      for (final payoutId in payoutIds) {
        try {
          await _client
              .from('stripe_payouts')
              .update({
                'status': 'in_transit',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', payoutId);

          await _sendPayoutNotification(
            payoutId: payoutId,
            eventType: 'initiated',
            message: 'Payout processing initiated',
          );

          successCount++;
        } catch (e) {
          failedCount++;
          errors.add('Payout $payoutId failed: $e');
        }
      }

      return {'success': successCount, 'failed': failedCount, 'errors': errors};
    } catch (e) {
      debugPrint('Process bulk payouts error: $e');
      return {
        'success': 0,
        'failed': 0,
        'errors': [e.toString()],
      };
    }
  }

  /// Export payout history to CSV
  Future<String?> exportPayoutHistory() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final history = await getPayoutHistory(limit: 1000);
      final payouts = history['payouts'] as List<Map<String, dynamic>>;

      if (payouts.isEmpty) return null;

      final csvLines = <String>[
        'Date,Amount (USD),Method,Status,Stripe Fee,Net Amount,Transaction ID',
      ];

      for (final payout in payouts) {
        final date = payout['created_at'] ?? '';
        final amount = payout['amount_usd'] ?? 0.0;
        final method = payout['payment_method'] ?? 'bank_transfer';
        final status = payout['status'] ?? 'unknown';
        final stripeFee = (amount * 0.029) + 0.30;
        final netAmount = amount - stripeFee;
        final txId = payout['stripe_payout_id'] ?? '';

        csvLines.add(
          '$date,$amount,$method,$status,\$${stripeFee.toStringAsFixed(2)},\$${netAmount.toStringAsFixed(2)},$txId',
        );
      }

      return csvLines.join('\n');
    } catch (e) {
      debugPrint('Export payout history error: $e');
      return null;
    }
  }

  // Private helper methods

  DateTime _calculateNextRetryDate(int attemptNumber) {
    final now = DateTime.now();
    switch (attemptNumber) {
      case 1:
        return now.add(const Duration(days: 1)); // Day 1
      case 2:
        return now.add(const Duration(days: 3)); // Day 3
      case 3:
        return now.add(const Duration(days: 7)); // Day 7
      default:
        return now.add(const Duration(days: 1));
    }
  }

  Future<void> _sendPayoutNotification({
    required String payoutId,
    required String eventType,
    required String message,
  }) async {
    try {
      // Get notification preferences
      final prefs = await getPayoutSchedule();

      // Check if notifications enabled for this event type
      bool shouldNotify = false;
      switch (eventType) {
        case 'initiated':
          shouldNotify = prefs['notify_on_initiated'] ?? true;
          break;
        case 'completed':
          shouldNotify = prefs['notify_on_completed'] ?? true;
          break;
        case 'failed':
        case 'retry_initiated':
          shouldNotify = prefs['notify_on_failed'] ?? true;
          break;
      }

      if (!shouldNotify) return;

      // Send SMS if enabled
      if (prefs['sms_enabled'] == true) {
        final user = _auth.currentUser;
        if (user?.phone != null) {
          await _twilio.sendUserActivityNotification(
            phoneNumber: user!.phone!,
            activityType: 'payout_$eventType',
            details: message,
          );
        }
      }

      // Email notification would be handled by Resend edge function
      // (triggered by database trigger on payout status change)
    } catch (e) {
      debugPrint('Send payout notification error: $e');
    }
  }

  Map<String, dynamic> _getDefaultSchedule() {
    return {
      'schedule_type': 'weekly',
      'minimum_threshold': 25.0,
      'next_payout_date': null,
      'notify_on_initiated': true,
      'notify_on_completed': true,
      'notify_on_failed': true,
      'email_enabled': true,
      'sms_enabled': false,
    };
  }

  Map<String, dynamic> _getDefaultAnalytics() {
    return {
      'success_rate': 0.0,
      'average_processing_time_hours': 0.0,
      'total_payouts_this_month': 0,
      'pending_count': 0,
      'failed_count': 0,
      'failure_reasons': {},
      'processing_time_trend': [],
    };
  }
}
