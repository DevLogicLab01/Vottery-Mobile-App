import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import './notification_service.dart';
import './supabase_service.dart';

class TwilioNotificationService {
  static TwilioNotificationService? _instance;
  static TwilioNotificationService get instance =>
      _instance ??= TwilioNotificationService._();

  TwilioNotificationService._();

  final NotificationService _notificationService = createNotificationService();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _notificationService.initialize();
    _initialized = true;
  }

  Future<bool> sendVoteDeadlineNotification({
    required String phoneNumber,
    required String voteTitle,
    required DateTime deadline,
  }) async {
    try {
      final message =
          'Reminder: Vote "$voteTitle" ends at ${_formatDeadline(deadline)}. Cast your vote now!';

      final success = await _sendSMS(phoneNumber, message);

      if (success) {
        await _notificationService.showNotification(
          title: 'Vote Deadline Reminder',
          body: message,
        );
      }

      return success;
    } catch (e) {
      debugPrint('Send vote deadline notification error: $e');
      return false;
    }
  }

  Future<bool> sendVoteResultsNotification({
    required String phoneNumber,
    required String voteTitle,
    required String result,
  }) async {
    try {
      final message =
          'Results are in for "$voteTitle": $result. View full details in the app.';

      final success = await _sendSMS(phoneNumber, message);

      if (success) {
        await _notificationService.showNotification(
          title: 'Vote Results Available',
          body: message,
        );
      }

      return success;
    } catch (e) {
      debugPrint('Send vote results notification error: $e');
      return false;
    }
  }

  Future<bool> sendUserActivityNotification({
    required String phoneNumber,
    required String activityType,
    required String details,
  }) async {
    try {
      final message = 'Activity Update: $activityType - $details';

      final success = await _sendSMS(phoneNumber, message);

      if (success) {
        await _notificationService.showNotification(
          title: 'Activity Update',
          body: message,
        );
      }

      return success;
    } catch (e) {
      debugPrint('Send user activity notification error: $e');
      return false;
    }
  }

  /// Send a raw SMS (e.g. for alerts). Use domain methods when possible.
  Future<bool> sendSms({required String to, required String body}) async {
    return _sendSMS(to, body);
  }

  Future<bool> _sendSMS(String phoneNumber, String message) async {
    try {
      final supabaseUrl = SupabaseService.supabaseUrl;
      final anonKey = SupabaseService.supabaseAnonKey;

      final edgeFunctionUrl = '$supabaseUrl/functions/v1/send-sms';

      final response = await http.post(
        Uri.parse(edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $anonKey',
        },
        body: json.encode({'to': phoneNumber, 'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        debugPrint(
          'SMS send failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('SMS send error: $e');
      return false;
    }
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours';
    } else {
      return '${difference.inDays} days';
    }
  }
}
