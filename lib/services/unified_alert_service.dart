import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './notification_cost_optimizer_service.dart';
import './integration_management_service.dart';

/// Unified Alert Management Service
/// Handles all notification types with real-time subscriptions,
/// bulk operations, preferences, and analytics
class UnifiedAlertService {
  static UnifiedAlertService? _instance;
  static UnifiedAlertService get instance =>
      _instance ??= UnifiedAlertService._();

  UnifiedAlertService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // NOTIFICATION MANAGEMENT
  // =====================================================

  /// Get all notifications for current user with filtering
  Future<List<Map<String, dynamic>>> getNotifications({
    List<String>? categories,
    bool? isRead,
    String? priority,
    int limit = 100,
  }) async {
    try {
      var query = _supabase.from('unified_notifications').select();

      if (categories != null && categories.isNotEmpty) {
        query = query.inFilter('notification_type', categories);
      }

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      if (priority != null) {
        query = query.eq('priority', priority);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get notifications error: $e');
      return [];
    }
  }

  /// Get unread count by category
  Future<Map<String, int>> getUnreadCountByCategory() async {
    try {
      final response = await _supabase
          .from('unified_notifications')
          .select('notification_type')
          .eq('is_read', false);

      final notifications = List<Map<String, dynamic>>.from(response);
      final counts = <String, int>{};

      for (final notification in notifications) {
        final type = notification['notification_type'] as String;
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('Get unread count error: $e');
      return {};
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('unified_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      // Track in alert history
      await _trackAlertAction(notificationId, 'opened');
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  /// Bulk mark as read
  Future<void> bulkMarkAsRead(List<String> notificationIds) async {
    try {
      for (final id in notificationIds) {
        await _supabase
            .from('unified_notifications')
            .update({'is_read': true})
            .eq('id', id);
      }
    } catch (e) {
      debugPrint('Bulk mark as read error: $e');
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      await _supabase
          .from('unified_notifications')
          .update({'is_read': true})
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Mark all as read error: $e');
    }
  }

  /// Mark all in category as read
  Future<void> markCategoryAsRead(String category) async {
    try {
      await _supabase
          .from('unified_notifications')
          .update({'is_read': true})
          .eq('notification_type', category)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Mark category as read error: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('unified_notifications')
          .delete()
          .eq('id', notificationId);

      await _trackAlertAction(notificationId, 'dismissed');
    } catch (e) {
      debugPrint('Delete notification error: $e');
    }
  }

  /// Bulk delete notifications
  Future<void> bulkDeleteNotifications(List<String> notificationIds) async {
    try {
      for (final id in notificationIds) {
        await _supabase.from('unified_notifications').delete().eq('id', id);
      }
    } catch (e) {
      debugPrint('Bulk delete error: $e');
    }
  }

  /// Clear all notifications in category
  Future<void> clearCategory(String category) async {
    try {
      await _supabase
          .from('unified_notifications')
          .delete()
          .eq('notification_type', category);
    } catch (e) {
      debugPrint('Clear category error: $e');
    }
  }

  // =====================================================
  // ALERT PREFERENCES
  // =====================================================

  /// Get user alert preferences
  Future<List<Map<String, dynamic>>> getAlertPreferences() async {
    try {
      final response = await _supabase
          .from('alert_preferences')
          .select()
          .order('category');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get alert preferences error: $e');
      return [];
    }
  }

  /// Update alert preference
  Future<void> updateAlertPreference({
    required String category,
    bool? enabled,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? priorityLevel,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (enabled != null) updates['enabled'] = enabled;
      if (pushEnabled != null) updates['push_enabled'] = pushEnabled;
      if (emailEnabled != null) updates['email_enabled'] = emailEnabled;
      if (smsEnabled != null) updates['sms_enabled'] = smsEnabled;
      if (soundEnabled != null) updates['sound_enabled'] = soundEnabled;
      if (vibrationEnabled != null) {
        updates['vibration_enabled'] = vibrationEnabled;
      }
      if (priorityLevel != null) updates['priority_level'] = priorityLevel;

      await _supabase.from('alert_preferences').upsert({
        'category': category,
        ...updates,
      });
    } catch (e) {
      debugPrint('Update alert preference error: $e');
    }
  }

  // =====================================================
  // QUIET HOURS
  // =====================================================

  /// Get quiet hours settings
  Future<Map<String, dynamic>?> getQuietHours() async {
    try {
      final response = await _supabase
          .from('quiet_hours')
          .select()
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get quiet hours error: $e');
      return null;
    }
  }

  /// Update quiet hours
  Future<void> updateQuietHours({
    required bool enabled,
    required String startTime,
    required String endTime,
    List<int>? daysOfWeek,
  }) async {
    try {
      await _supabase.from('quiet_hours').upsert({
        'enabled': enabled,
        'start_time': startTime,
        'end_time': endTime,
        if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      });
    } catch (e) {
      debugPrint('Update quiet hours error: $e');
    }
  }

  // =====================================================
  // ALERT HISTORY & SEARCH
  // =====================================================

  /// Search alert history
  Future<List<Map<String, dynamic>>> searchAlertHistory({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
  }) async {
    try {
      var query = _supabase.from('unified_notifications').select();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'title.ilike.%$searchQuery%,body.ilike.%$searchQuery%',
        );
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      if (categories != null && categories.isNotEmpty) {
        query = query.inFilter('notification_type', categories);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Search alert history error: $e');
      return [];
    }
  }

  /// Get alert history actions
  Future<List<Map<String, dynamic>>> getAlertHistory({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('alert_history')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get alert history error: $e');
      return [];
    }
  }

  // =====================================================
  // ALERT GROUPING
  // =====================================================

  /// Get grouped alerts
  Future<List<Map<String, dynamic>>> getGroupedAlerts() async {
    try {
      final response = await _supabase
          .from('alert_groups')
          .select()
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get grouped alerts error: $e');
      return [];
    }
  }

  /// Mark alert group as read
  Future<void> markGroupAsRead(String groupId) async {
    try {
      await _supabase
          .from('alert_groups')
          .update({'is_read': true})
          .eq('id', groupId);
    } catch (e) {
      debugPrint('Mark group as read error: $e');
    }
  }

  // =====================================================
  // ALERT ANALYTICS
  // =====================================================

  /// Get alert delivery analytics
  Future<List<Map<String, dynamic>>> getAlertAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final baseQuery = _supabase.from('alert_delivery_analytics').select();

      List<Map<String, dynamic>> response;

      if (startDate != null && endDate != null) {
        response = List<Map<String, dynamic>>.from(
          await baseQuery
              .gte('date', startDate.toIso8601String().split('T')[0])
              .lte('date', endDate.toIso8601String().split('T')[0])
              .order('date', ascending: false),
        );
      } else if (startDate != null) {
        response = List<Map<String, dynamic>>.from(
          await baseQuery
              .gte('date', startDate.toIso8601String().split('T')[0])
              .order('date', ascending: false),
        );
      } else if (endDate != null) {
        response = List<Map<String, dynamic>>.from(
          await baseQuery
              .lte('date', endDate.toIso8601String().split('T')[0])
              .order('date', ascending: false),
        );
      } else {
        response = List<Map<String, dynamic>>.from(
          await baseQuery.order('date', ascending: false),
        );
      }

      return response;
    } catch (e) {
      debugPrint('Get alert analytics error: $e');
      return [];
    }
  }

  /// Get engagement metrics summary
  Future<Map<String, dynamic>> getEngagementMetrics() async {
    try {
      final analytics = await getAlertAnalytics(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
      );

      int totalSent = 0;
      int totalDelivered = 0;
      int totalOpened = 0;
      int totalClicked = 0;

      for (final record in analytics) {
        totalSent += (record['total_sent'] as int?) ?? 0;
        totalDelivered += (record['total_delivered'] as int?) ?? 0;
        totalOpened += (record['total_opened'] as int?) ?? 0;
        totalClicked += (record['total_clicked'] as int?) ?? 0;
      }

      final deliveryRate = totalSent > 0
          ? (totalDelivered / totalSent * 100)
          : 0.0;
      final openRate = totalDelivered > 0
          ? (totalOpened / totalDelivered * 100)
          : 0.0;
      final clickRate = totalOpened > 0
          ? (totalClicked / totalOpened * 100)
          : 0.0;

      return {
        'total_sent': totalSent,
        'total_delivered': totalDelivered,
        'total_opened': totalOpened,
        'total_clicked': totalClicked,
        'delivery_rate': deliveryRate,
        'open_rate': openRate,
        'click_rate': clickRate,
      };
    } catch (e) {
      debugPrint('Get engagement metrics error: $e');
      return {};
    }
  }

  // =====================================================
  // REAL-TIME SUBSCRIPTIONS
  // =====================================================

  /// Subscribe to real-time notifications
  StreamSubscription subscribeToNotifications(
    Function(List<Map<String, dynamic>>) onData,
  ) {
    return _supabase
        .from('unified_notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(onData);
  }

  // =====================================================
  // PRIVATE HELPERS
  // =====================================================

  /// Track alert action in history
  Future<void> _trackAlertAction(String notificationId, String action) async {
    try {
      await _supabase.from('alert_history').insert({
        'notification_id': notificationId,
        'action': action,
      });
    } catch (e) {
      debugPrint('Track alert action error: $e');
    }
  }

  /// Cost-optimized dispatch plan for channels:
  /// push first, then WhatsApp/SMS fallback after 24h for non-urgent alerts.
  Future<Map<String, dynamic>> dispatchOptimizedAlert({
    required String title,
    required String body,
    required String severity,
    required String recipientId,
    String? useCase,
    String? phoneNumber,
    String? whatsappNumber,
    bool hasPushToken = true,
  }) async {
    final plan = NotificationCostOptimizerService.instance.buildChannelPlan(
      severity: severity,
      useCase: useCase,
      hasPushToken: hasPushToken,
      hasWhatsApp: (whatsappNumber ?? '').isNotEmpty,
      hasPhone: (phoneNumber ?? '').isNotEmpty,
    );

    final optimizedSms = NotificationCostOptimizerService.instance
        .optimizeSmsMessage(body);
    final executedChannels = <String>[];
    for (final channelPlan in plan) {
      final channel = (channelPlan['channel'] ?? '').toString();
      if (channel.isEmpty) continue;
      String integrationName = 'Push Notifications';
      double projectedCost = 0;
      if (channel == 'email') {
        integrationName = 'Resend';
        projectedCost = 0.001;
      } else if (channel == 'whatsapp') {
        integrationName = 'WhatsApp (Twilio)';
        projectedCost = 0.004;
      } else if (channel == 'sms') {
        integrationName = 'Twilio';
        projectedCost = 0.008;
      }
      final integrationCheck =
          await IntegrationManagementService.instance.canUseIntegration(
        integrationName,
        projectedCost: projectedCost,
      );
      if (integrationCheck['allowed'] == true) {
        executedChannels.add(channel);
        if (projectedCost > 0) {
          await IntegrationManagementService.instance.recordUsage(
            integrationName,
            costDelta: projectedCost,
          );
        }
      }
    }

    await _supabase.from('alert_history').insert({
      'notification_id': recipientId,
      'action': 'dispatch_planned',
      'metadata': {
        'title': title,
        'severity': severity,
        'use_case': useCase,
        'plan': plan,
        'executed_channels': executedChannels,
        'optimized_sms_preview': optimizedSms,
      },
    });

    return {
      'plan': plan,
      'executed_channels': executedChannels,
      'optimized_sms': optimizedSms,
    };
  }
}
