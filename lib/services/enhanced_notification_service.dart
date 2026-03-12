import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './ga4_analytics_service.dart';
import './notification_service.dart';

/// Enhanced notification service with batching, priority queuing, and analytics
class EnhancedNotificationService {
  static EnhancedNotificationService? _instance;
  static EnhancedNotificationService get instance =>
      _instance ??= EnhancedNotificationService._();

  EnhancedNotificationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  GA4AnalyticsService get _analytics => GA4AnalyticsService.instance;
  NotificationService get _notificationService => createNotificationService();

  static const Map<String, String> priorityLevels = {
    'critical': 'Critical',
    'high': 'High',
    'normal': 'Normal',
    'low': 'Low',
  };

  static const Map<String, String> categories = {
    'fraud_alert': 'Fraud Alert',
    'security': 'Security',
    'new_vote': 'New Vote',
    'winner_announcement': 'Winner Announcement',
    'comment': 'Comment',
    'reaction': 'Reaction',
    'suggestion': 'Suggestion',
    'system': 'System',
  };

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      await _notificationService.initialize();
      await _createDefaultPreferences();
      await _processPendingNotifications();
    } catch (e) {
      debugPrint('Initialize enhanced notification service error: $e');
    }
  }

  /// Send notification with priority and batching
  Future<bool> sendNotification({
    required String userId,
    required String category,
    required String priority,
    required String title,
    required String body,
    String? deepLink,
    Map<String, dynamic>? deepLinkParams,
    List<Map<String, String>>? actionButtons,
  }) async {
    try {
      // Get user preferences
      final prefs = await _getUserPreferences(userId);
      if (prefs == null) return false;

      // Check if category is enabled
      final categoryKey = '${category}_enabled';
      if (prefs[categoryKey] == false) {
        debugPrint('Category $category disabled for user');
        return false;
      }

      // Check if priority is enabled
      final priorityKey = '${priority}_priority';
      if (prefs[priorityKey] == false) {
        debugPrint('Priority $priority disabled for user');
        return false;
      }

      // Check quiet hours
      if (prefs['enable_quiet_hours'] == true) {
        final now = DateTime.now();
        final quietStart = prefs['quiet_hours_start'] as String?;
        final quietEnd = prefs['quiet_hours_end'] as String?;

        if (quietStart != null && quietEnd != null) {
          if (_isInQuietHours(now, quietStart, quietEnd)) {
            // Only send critical notifications during quiet hours
            if (priority != 'critical') {
              debugPrint('Notification delayed due to quiet hours');
              // Schedule for after quiet hours
              return await _scheduleNotification(
                userId: userId,
                category: category,
                priority: priority,
                title: title,
                body: body,
                deepLink: deepLink,
                deepLinkParams: deepLinkParams,
                actionButtons: actionButtons,
                scheduledFor: _getNextBatchTime(prefs),
              );
            }
          }
        }
      }

      // Check if batching is enabled and priority allows it
      if (prefs['enable_batching'] == true &&
          priority != 'critical' &&
          priority != 'high') {
        return await _addToBatch(
          userId: userId,
          category: category,
          priority: priority,
          title: title,
          body: body,
          deepLink: deepLink,
          deepLinkParams: deepLinkParams,
          actionButtons: actionButtons,
        );
      }

      // Send immediately
      return await _sendImmediately(
        userId: userId,
        category: category,
        priority: priority,
        title: title,
        body: body,
        deepLink: deepLink,
        deepLinkParams: deepLinkParams,
        actionButtons: actionButtons,
      );
    } catch (e) {
      debugPrint('Send notification error: $e');
      return false;
    }
  }

  /// Send notification immediately
  Future<bool> _sendImmediately({
    required String userId,
    required String category,
    required String priority,
    required String title,
    required String body,
    String? deepLink,
    Map<String, dynamic>? deepLinkParams,
    List<Map<String, String>>? actionButtons,
  }) async {
    try {
      // Insert into database
      final notification = await _client
          .from('enhanced_notifications')
          .insert({
            'user_id': userId,
            'category': category,
            'priority': priority,
            'title': title,
            'body': body,
            'deep_link': deepLink,
            'deep_link_params': deepLinkParams,
            'action_buttons': actionButtons,
            'delivery_status': 'sent',
            'sent_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Send via platform notification service
      await _notificationService.showNotification(
        title: title,
        body: body,
        payload: notification['id'] as String,
      );

      // Track analytics event
      await _trackNotificationEvent(
        notificationId: notification['id'] as String,
        eventType: 'received',
        category: category,
        priority: priority,
        deepLink: deepLink,
      );

      return true;
    } catch (e) {
      debugPrint('Send immediately error: $e');
      return false;
    }
  }

  /// Add notification to batch
  Future<bool> _addToBatch({
    required String userId,
    required String category,
    required String priority,
    required String title,
    required String body,
    String? deepLink,
    Map<String, dynamic>? deepLinkParams,
    List<Map<String, String>>? actionButtons,
  }) async {
    try {
      final prefs = await _getUserPreferences(userId);
      if (prefs == null) return false;

      final scheduledFor = _getNextBatchTime(prefs);

      await _client.from('enhanced_notifications').insert({
        'user_id': userId,
        'category': category,
        'priority': priority,
        'title': title,
        'body': body,
        'deep_link': deepLink,
        'deep_link_params': deepLinkParams,
        'action_buttons': actionButtons,
        'delivery_status': 'batched',
        'scheduled_for': scheduledFor.toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Add to batch error: $e');
      return false;
    }
  }

  /// Schedule notification for later
  Future<bool> _scheduleNotification({
    required String userId,
    required String category,
    required String priority,
    required String title,
    required String body,
    String? deepLink,
    Map<String, dynamic>? deepLinkParams,
    List<Map<String, String>>? actionButtons,
    required DateTime scheduledFor,
  }) async {
    try {
      await _client.from('enhanced_notifications').insert({
        'user_id': userId,
        'category': category,
        'priority': priority,
        'title': title,
        'body': body,
        'deep_link': deepLink,
        'deep_link_params': deepLinkParams,
        'action_buttons': actionButtons,
        'delivery_status': 'pending',
        'scheduled_for': scheduledFor.toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Schedule notification error: $e');
      return false;
    }
  }

  /// Process pending notifications
  Future<void> _processPendingNotifications() async {
    try {
      if (!_auth.isAuthenticated) return;

      final now = DateTime.now();

      // Get pending notifications ready to send
      final notifications = await _client
          .from('enhanced_notifications')
          .select('*')
          .eq('user_id', _auth.currentUser!.id)
          .eq('delivery_status', 'pending')
          .lte('scheduled_for', now.toIso8601String())
          .order('priority', ascending: true)
          .order('scheduled_for', ascending: true);

      for (var notification in notifications) {
        await _sendImmediately(
          userId: notification['user_id'] as String,
          category: notification['category'] as String,
          priority: notification['priority'] as String,
          title: notification['title'] as String,
          body: notification['body'] as String,
          deepLink: notification['deep_link'] as String?,
          deepLinkParams:
              notification['deep_link_params'] as Map<String, dynamic>?,
          actionButtons:
              notification['action_buttons'] as List<Map<String, String>>?,
        );
      }
    } catch (e) {
      debugPrint('Process pending notifications error: $e');
    }
  }

  /// Track notification event for analytics
  Future<void> _trackNotificationEvent({
    required String notificationId,
    required String eventType,
    required String category,
    required String priority,
    String? deepLink,
    String? actionButtonId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return;

      // Insert into analytics table
      await _client.from('notification_analytics_events').insert({
        'notification_id': notificationId,
        'user_id': _auth.currentUser!.id,
        'event_type': eventType,
        'category': category,
        'priority': priority,
        'deep_link': deepLink,
        'action_button_id': actionButtonId,
      });

      // Note: GA4 tracking removed as trackNotificationEvent method doesn't exist
      // Analytics are still tracked in notification_analytics_events table
    } catch (e) {
      debugPrint('Track notification event error: $e');
    }
  }

  /// Mark notification as clicked
  Future<void> notificationClicked(String notificationId) async {
    try {
      await _client.rpc(
        'track_notification_event',
        params: {
          'p_notification_id': notificationId,
          'p_event_type': 'clicked',
        },
      );
    } catch (e) {
      debugPrint('Notification clicked error: $e');
    }
  }

  /// Mark notification as dismissed
  Future<void> notificationDismissed(String notificationId) async {
    try {
      await _client.rpc(
        'track_notification_event',
        params: {
          'p_notification_id': notificationId,
          'p_event_type': 'dismissed',
        },
      );
    } catch (e) {
      debugPrint('Notification dismissed error: $e');
    }
  }

  /// Get user notification preferences
  Future<Map<String, dynamic>?> _getUserPreferences(String userId) async {
    try {
      final response = await _client
          .from('notification_preferences')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get user preferences error: $e');
      return null;
    }
  }

  /// Create default preferences for user
  Future<void> _createDefaultPreferences() async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client.from('notification_preferences').insert({
        'user_id': _auth.currentUser!.id,
      });
    } catch (e) {
      debugPrint('Create default preferences error: $e');
    }
  }

  /// Check if current time is in quiet hours
  bool _isInQuietHours(DateTime now, String startTime, String endTime) {
    final start = TimeOfDay(
      hour: int.parse(startTime.split(':')[0]),
      minute: int.parse(startTime.split(':')[1]),
    );
    final end = TimeOfDay(
      hour: int.parse(endTime.split(':')[0]),
      minute: int.parse(endTime.split(':')[1]),
    );

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes < endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  /// Get next batch time based on preferences
  DateTime _getNextBatchTime(Map<String, dynamic> prefs) {
    final now = DateTime.now();
    final batchTimes =
        prefs['batch_times'] as List<dynamic>? ?? ['09:00', '12:00', '18:00'];

    for (var timeStr in batchTimes) {
      final parts = (timeStr as String).split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      var batchTime = DateTime(now.year, now.month, now.day, hour, minute);

      if (batchTime.isAfter(now)) {
        return batchTime;
      }
    }

    // If all batch times passed today, return first batch time tomorrow
    final firstTime = batchTimes.first as String;
    final parts = firstTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return DateTime(now.year, now.month, now.day + 1, hour, minute);
  }
}
