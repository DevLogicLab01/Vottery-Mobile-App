import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

import '../models/quest.dart';
import '../models/security_alert.dart';

/// AI Notification Service for Push Notifications
/// Manages notification channels for security alerts, AI recommendations, and quest updates
class AINotificationService {
  static bool _isInitialized = false;

  /// Initialize AwesomeNotifications with AI-specific channels
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await AwesomeNotifications().initialize(null, [
        NotificationChannel(
          channelKey: 'ai_security_alerts',
          channelName: 'AI Security Alerts',
          channelDescription: 'Critical security alerts from AI systems',
          defaultColor: Colors.red,
          ledColor: Colors.red,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: 'ai_recommendations',
          channelName: 'AI Recommendations',
          channelDescription: 'Personalized recommendations from AI',
          defaultColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
        ),
        NotificationChannel(
          channelKey: 'quest_updates',
          channelName: 'Quest Updates',
          channelDescription:
              'AI-generated quest completions and new challenges',
          defaultColor: Colors.green,
          importance: NotificationImportance.Default,
          channelShowBadge: true,
        ),
      ]);

      // Request notification permissions
      await AwesomeNotifications().requestPermissionToSendNotifications();

      _isInitialized = true;
      debugPrint('AINotificationService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AINotificationService: $e');
      rethrow;
    }
  }

  /// Show security alert notification
  static Future<void> showSecurityAlert({required SecurityAlert alert}) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: alert.id.hashCode,
          channelKey: 'ai_security_alerts',
          title: 'Security Alert: ${alert.severity.toUpperCase()}',
          body: alert.description,
          category: NotificationCategory.Alarm,
          wakeUpScreen: alert.severity == 'critical',
          criticalAlert: alert.severity == 'critical',
          payload: {
            'alert_id': alert.id,
            'type': 'security',
            'severity': alert.severity,
          },
          notificationLayout: NotificationLayout.Default,
        ),
      );
    } catch (e) {
      debugPrint('Failed to show security alert: $e');
    }
  }

  /// Show quest completion notification
  static Future<void> showQuestComplete({
    required Quest quest,
    required int vpEarned,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: quest.id.hashCode,
          channelKey: 'quest_updates',
          title: 'Quest Completed! 🎉',
          body: '${quest.title} - Earned $vpEarned VP',
          payload: {
            'quest_id': quest.id,
            'vp_earned': vpEarned.toString(),
            'type': 'quest_complete',
          },
          notificationLayout: NotificationLayout.Default,
        ),
      );
    } catch (e) {
      debugPrint('Failed to show quest completion: $e');
    }
  }

  /// Show AI recommendation notification
  static Future<void> showAIRecommendation({
    required String title,
    required String message,
    Map<String, String>? payload,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'ai_recommendations',
          title: title,
          body: message,
          payload: payload ?? {'type': 'ai_recommendation'},
          notificationLayout: NotificationLayout.Default,
        ),
      );
    } catch (e) {
      debugPrint('Failed to show AI recommendation: $e');
    }
  }

  /// Show new quest available notification
  static Future<void> showNewQuestAvailable({required Quest quest}) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: quest.id.hashCode,
          channelKey: 'quest_updates',
          title: 'New Quest Available! 🎯',
          body: '${quest.title} - Earn ${quest.vpReward} VP',
          payload: {'quest_id': quest.id, 'type': 'new_quest'},
          notificationLayout: NotificationLayout.Default,
        ),
      );
    } catch (e) {
      debugPrint('Failed to show new quest notification: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel notifications: $e');
    }
  }

  /// Cancel notification by ID
  static Future<void> cancelNotification(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      return await AwesomeNotifications().isNotificationAllowed();
    } catch (e) {
      debugPrint('Failed to check notification status: $e');
      return false;
    }
  }
}
