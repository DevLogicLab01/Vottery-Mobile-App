import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

import '../../models/platform_log.dart';
import './log_stream_service.dart';

class LogNotificationService {
  static StreamSubscription? _criticalLogsSubscription;

  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'critical_logs',
        channelName: 'Security Alerts',
        channelDescription: 'Critical security and system alerts',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
      ),
    ]);

    await _setupCriticalLogAlerts();
  }

  static Future<void> _setupCriticalLogAlerts() async {
    _criticalLogsSubscription = LogStreamService.getCriticalAlertsStream()
        .listen((logs) {
          for (final log in logs) {
            if (_isRecentLog(log)) {
              _showCriticalAlert(log);
            }
          }
        });
  }

  static bool _isRecentLog(PlatformLog log) {
    final now = DateTime.now();
    final logTime = log.createdAt;
    return now.difference(logTime).inMinutes <
        5; // Only show alerts for logs from last 5 minutes
  }

  static Future<void> _showCriticalAlert(PlatformLog log) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: log.id.hashCode,
        channelKey: 'critical_logs',
        title: 'Security Alert',
        body: log.message,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        criticalAlert: true,
        payload: {
          'log_id': log.id,
          'log_category': log.logCategory,
          'timestamp': log.createdAt.toIso8601String(),
        },
      ),
    );
  }

  static void dispose() {
    _criticalLogsSubscription?.cancel();
  }
}
