import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Push Notification Intelligence Service
/// Optimizes push delivery based on user activity patterns, engagement history,
/// and device state. Supports A/B testing for optimal notification windows.
class PushNotificationIntelligenceService {
  static PushNotificationIntelligenceService? _instance;
  static PushNotificationIntelligenceService get instance =>
      _instance ??= PushNotificationIntelligenceService._();

  PushNotificationIntelligenceService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Get optimal send window for user based on activity patterns
  /// Returns { startHour, endHour, bestDayOfWeek } in local timezone
  /// Falls back to defaults if user_activity_sessions table doesn't exist
  Future<Map<String, dynamic>> getOptimalSendWindow(String userId) async {
    try {
      final response = await _client
          .from('user_activity_sessions')
          .select('session_start, session_end, engagement_score')
          .eq('user_id', userId)
          .gte('session_start', DateTime.now()
              .subtract(const Duration(days: 14))
              .toIso8601String())
          .order('session_start', ascending: false)
          .limit(100);

      final sessions = response is List ? response : <dynamic>[];
      if (sessions.isEmpty) {
        return {
          'startHour': 9,
          'endHour': 21,
          'bestDayOfWeek': 1, // Monday
          'confidence': 0.5,
        };
      }

      final hourCounts = <int, int>{};
      final dayCounts = <int, int>{};
      for (final s in sessions) {
        final map = s as Map<String, dynamic>;
        final start = map['session_start'] as String?;
        if (start != null) {
          final dt = DateTime.tryParse(start);
          if (dt != null) {
            hourCounts[dt.hour] = (hourCounts[dt.hour] ?? 0) + 1;
            dayCounts[dt.weekday] = (dayCounts[dt.weekday] ?? 0) + 1;
          }
        }
      }

      final topHour = hourCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      final topDay = dayCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      return {
        'startHour': (topHour - 1).clamp(0, 23),
        'endHour': (topHour + 2).clamp(0, 24),
        'bestDayOfWeek': topDay,
        'confidence': (sessions.length / 100).clamp(0.0, 1.0),
      };
    } catch (e) {
      debugPrint('getOptimalSendWindow error: $e');
      return {
        'startHour': 9,
        'endHour': 21,
        'bestDayOfWeek': 1,
        'confidence': 0.5,
      };
    }
  }

  /// Check if current time is within user's optimal window
  Future<bool> isWithinOptimalWindow(String userId) async {
    final window = await getOptimalSendWindow(userId);
    final now = DateTime.now();
    final hour = now.hour;
    final day = now.weekday;
    final start = (window['startHour'] as num?)?.toInt() ?? 9;
    final end = (window['endHour'] as num?)?.toInt() ?? 21;
    final bestDay = (window['bestDayOfWeek'] as num?)?.toInt() ?? 1;
    return hour >= start && hour <= end && (day == bestDay || (hour >= start && hour <= end));
  }

  /// Get optimal send time from smart-push-timing Edge function
  /// Returns nextSendTime, optimalHour, confidence for scheduling
  Future<Map<String, dynamic>> getSmartPushOptimalTime(String userId) async {
    try {
      final response = await _client.functions.invoke(
        'smart-push-timing',
        body: {'userId': userId},
      );
      if (response.status == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('getSmartPushOptimalTime error: $e');
    }
    return {
      'optimalHour': 12,
      'confidence': 'low',
      'nextSendTime': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    };
  }

  /// Schedule notification at optimal time (uses smart-push-timing when available)
  Future<void> scheduleAtOptimalTime({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final optimal = await getSmartPushOptimalTime(userId);
      final nextSend = optimal['nextSendTime'] as String?;
      if (nextSend != null) {
        await _client.from('notifications').insert({
          'user_id': userId,
          'title': title,
          'message': body,
          'type': 'push',
          'data': data ?? {},
          'is_read': false,
          'scheduled_for': nextSend,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('scheduleAtOptimalTime error: $e');
    }
  }

  /// Record notification engagement for ML optimization
  Future<void> recordEngagement({
    required String userId,
    required String notificationId,
    required String action,
    required DateTime timestamp,
  }) async {
    try {
      await _client.from('push_notification_engagement').insert({
        'user_id': userId,
        'notification_id': notificationId,
        'action': action,
        'timestamp': timestamp.toIso8601String(),
      });
    } catch (e) {
      debugPrint('recordEngagement error: $e');
    }
  }
}
