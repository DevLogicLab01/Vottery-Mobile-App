import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './twilio_notification_service.dart';
import './notification_service.dart';
import './supabase_query_cache_service.dart';

class AlertRulesService {
  static AlertRulesService? _instance;
  static AlertRulesService get instance => _instance ??= AlertRulesService._();

  AlertRulesService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  TwilioNotificationService get _twilio => TwilioNotificationService.instance;
  NotificationService get _notifications => createNotificationService();

  Future<Map<String, dynamic>> createAlertRule({
    required String ruleName,
    required String description,
    required String metricType,
    required double thresholdValue,
    required String comparisonOperator,
    required String severity,
    required List<String> notificationChannels,
    int cooldownMinutes = 60,
    List<Map<String, dynamic>>? conditions,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final response = await _client
          .from('alert_rules')
          .insert({
            'created_by': _auth.currentUser!.id,
            'rule_name': ruleName,
            'description': description,
            'metric_type': metricType,
            'threshold_value': thresholdValue,
            'comparison_operator': comparisonOperator,
            'severity': severity,
            'notification_channels': notificationChannels,
            'cooldown_minutes': cooldownMinutes,
            'status': 'active',
          })
          .select()
          .single();

      if (conditions != null && conditions.isNotEmpty) {
        for (final condition in conditions) {
          await _client.from('alert_rule_conditions').insert({
            'rule_id': response['id'],
            'condition_group': condition['condition_group'] ?? 1,
            'logic_operator': condition['logic_operator'] ?? 'AND',
            'metric_name': condition['metric_name'],
            'comparison_operator': condition['comparison_operator'],
            'threshold_value': condition['threshold_value'],
            'time_window_minutes': condition['time_window_minutes'] ?? 5,
          });
        }
      }

      return response;
    } catch (e) {
      debugPrint('Create alert rule error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAlertRules({
    String? status,
    String? metricType,
  }) async {
    try {
      var query = _client.from('alert_rules').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      if (metricType != null) {
        query = query.eq('metric_type', metricType);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get alert rules error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getAlertRuleById(String ruleId) async {
    try {
      final response = await _client
          .from('alert_rules')
          .select()
          .eq('id', ruleId)
          .maybeSingle();

      if (response != null) {
        final conditions = await _client
            .from('alert_rule_conditions')
            .select()
            .eq('rule_id', ruleId);

        response['conditions'] = conditions;
      }

      return response;
    } catch (e) {
      debugPrint('Get alert rule by ID error: $e');
      return null;
    }
  }

  Future<bool> updateAlertRule({
    required String ruleId,
    String? ruleName,
    String? description,
    String? metricType,
    double? thresholdValue,
    String? comparisonOperator,
    String? severity,
    List<String>? notificationChannels,
    String? status,
    List<Map<String, dynamic>>? conditions,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (ruleName != null) updates['rule_name'] = ruleName;
      if (description != null) updates['description'] = description;
      if (metricType != null) updates['metric_type'] = metricType;
      if (thresholdValue != null) updates['threshold_value'] = thresholdValue;
      if (comparisonOperator != null) {
        updates['comparison_operator'] = comparisonOperator;
      }
      if (severity != null) updates['severity'] = severity;
      if (notificationChannels != null) {
        updates['notification_channels'] = notificationChannels;
      }
      if (status != null) updates['status'] = status;

      if (updates.isNotEmpty) {
        await _client.from('alert_rules').update(updates).eq('id', ruleId);
      }

      if (conditions != null) {
        await _client.from('alert_rule_conditions').delete().eq('rule_id', ruleId);
        if (conditions.isNotEmpty) {
          for (final condition in conditions) {
            await _client.from('alert_rule_conditions').insert({
              'rule_id': ruleId,
              'condition_group': condition['condition_group'] ?? 1,
              'logic_operator': condition['logic_operator'] ?? 'AND',
              'metric_name': condition['metric_name'],
              'comparison_operator': condition['comparison_operator'],
              'threshold_value': condition['threshold_value'],
              'time_window_minutes': condition['time_window_minutes'] ?? 5,
            });
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Update alert rule error: $e');
      return false;
    }
  }

  Future<bool> deleteAlertRule(String ruleId) async {
    try {
      await _client.from('alert_rules').delete().eq('id', ruleId);
      return true;
    } catch (e) {
      debugPrint('Delete alert rule error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveAlerts({
    bool unresolvedOnly = true,
    String? severity,
  }) async {
    try {
      var query = _client.from('active_alerts').select();

      if (unresolvedOnly) {
        query = query.eq('is_resolved', false);
      }

      if (severity != null) {
        query = query.eq('severity', severity);
      }

      final response = await query.order('triggered_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get active alerts error: $e');
      return [];
    }
  }

  Future<bool> acknowledgeAlert({
    required String alertId,
    String? notes,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('active_alerts')
          .update({
            'is_acknowledged': true,
            'acknowledged_by': _auth.currentUser!.id,
            'acknowledged_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);
      SupabaseQueryCacheService.instance
          .onAlertLifecycleChanged(alertId: alertId);

      return true;
    } catch (e) {
      debugPrint('Acknowledge alert error: $e');
      return false;
    }
  }

  Future<bool> resolveAlert({
    required String alertId,
    required String resolutionNotes,
  }) async {
    try {
      await _client
          .from('active_alerts')
          .update({
            'is_resolved': true,
            'resolved_at': DateTime.now().toIso8601String(),
            'resolution_notes': resolutionNotes,
          })
          .eq('id', alertId);
      SupabaseQueryCacheService.instance
          .onAlertLifecycleChanged(alertId: alertId);

      return true;
    } catch (e) {
      debugPrint('Resolve alert error: $e');
      return false;
    }
  }

  Future<bool> snoozeAlert({
    required String alertId,
    required DateTime snoozeUntil,
    String? reason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;
      final updates = <String, dynamic>{
        'status': 'snoozed',
        'snoozed_until': snoozeUntil.toIso8601String(),
        'snoozed_by': _auth.currentUser!.id,
        'snoozed_at': DateTime.now().toIso8601String(),
      };
      if (reason != null && reason.isNotEmpty) {
        updates['snooze_reason'] = reason;
      }
      await _client.from('active_alerts').update(updates).eq('id', alertId);
      SupabaseQueryCacheService.instance
          .onAlertLifecycleChanged(alertId: alertId);
      return true;
    } catch (e) {
      debugPrint('Snooze alert error: $e');
      return false;
    }
  }

  Future<bool> assignAlertOwner({
    required String alertId,
    required String ownerUserId,
    String? notes,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;
      final updates = <String, dynamic>{
        'assigned_to': ownerUserId,
        'assigned_by': _auth.currentUser!.id,
        'assigned_at': DateTime.now().toIso8601String(),
      };
      if (notes != null && notes.isNotEmpty) {
        updates['assignment_notes'] = notes;
      }
      await _client.from('active_alerts').update(updates).eq('id', alertId);
      SupabaseQueryCacheService.instance
          .onAlertLifecycleChanged(alertId: alertId);
      return true;
    } catch (e) {
      debugPrint('Assign alert owner error: $e');
      return false;
    }
  }

  Future<bool> escalateAlert({
    required String alertId,
    String escalationLevel = 'P0',
    String? escalationNotes,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;
      final severity = escalationLevel == 'P0'
          ? 'critical'
          : escalationLevel == 'P1'
          ? 'high'
          : 'medium';
      final updates = <String, dynamic>{
        'status': 'escalated',
        'severity': severity,
        'escalation_level': escalationLevel,
        'escalated_by': _auth.currentUser!.id,
        'escalated_at': DateTime.now().toIso8601String(),
      };
      if (escalationNotes != null && escalationNotes.isNotEmpty) {
        updates['escalation_notes'] = escalationNotes;
      }
      await _client.from('active_alerts').update(updates).eq('id', alertId);
      SupabaseQueryCacheService.instance
          .onAlertLifecycleChanged(alertId: alertId);
      return true;
    } catch (e) {
      debugPrint('Escalate alert error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAlertHistory({
    String? ruleId,
    int limit = 100,
  }) async {
    try {
      var query = _client.from('alert_history').select();

      if (ruleId != null) {
        query = query.eq('rule_id', ruleId);
      }

      final response = await query
          .order('triggered_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get alert history error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getAlertStatistics() async {
    try {
      final activeAlerts = await getActiveAlerts(unresolvedOnly: true);
      final totalRules = await getAlertRules(status: 'active');

      final criticalAlerts = activeAlerts
          .where((a) => a['severity'] == 'critical')
          .length;
      final highAlerts = activeAlerts
          .where((a) => a['severity'] == 'high')
          .length;
      final mediumAlerts = activeAlerts
          .where((a) => a['severity'] == 'medium')
          .length;

      return {
        'total_active_alerts': activeAlerts.length,
        'critical_alerts': criticalAlerts,
        'high_alerts': highAlerts,
        'medium_alerts': mediumAlerts,
        'total_active_rules': totalRules.length,
      };
    } catch (e) {
      debugPrint('Get alert statistics error: $e');
      return {
        'total_active_alerts': 0,
        'critical_alerts': 0,
        'high_alerts': 0,
        'medium_alerts': 0,
        'total_active_rules': 0,
      };
    }
  }

  Future<void> triggerAlert({
    required String ruleId,
    required String severity,
    required String metricType,
    required double currentValue,
    required double thresholdValue,
    required String message,
    List<String>? notificationChannels,
  }) async {
    try {
      await _client
          .from('active_alerts')
          .insert({
            'rule_id': ruleId,
            'severity': severity,
            'metric_type': metricType,
            'current_value': currentValue,
            'threshold_value': thresholdValue,
            'message': message,
          })
          .select()
          .single();

      await _sendNotifications(
        message: message,
        severity: severity,
        channels: notificationChannels ?? ['email'],
      );

      await _client.from('alert_history').insert({
        'rule_id': ruleId,
        'triggered_at': DateTime.now().toIso8601String(),
        'severity': severity,
        'metric_type': metricType,
        'metric_value': currentValue,
        'threshold_value': thresholdValue,
        'notification_sent': true,
        'notification_channels': notificationChannels ?? ['email'],
      });
    } catch (e) {
      debugPrint('Trigger alert error: $e');
    }
  }

  Future<void> _sendNotifications({
    required String message,
    required String severity,
    required List<String> channels,
  }) async {
    try {
      for (final channel in channels) {
        switch (channel) {
          case 'sms':
            if (_auth.currentUser?.phone != null) {
              await _twilio.sendUserActivityNotification(
                phoneNumber: _auth.currentUser!.phone!,
                activityType: 'Alert',
                details: message,
              );
            }
            break;
          case 'email':
            break;
          case 'push':
            await _notifications.showNotification(
              title: 'Alert: $severity',
              body: message,
            );
            break;
        }
      }
    } catch (e) {
      debugPrint('Send notifications error: $e');
    }
  }

  Future<bool> bulkDismissAlerts(List<String> alertIds) async {
    try {
      for (final alertId in alertIds) {
        await resolveAlert(alertId: alertId, resolutionNotes: 'Bulk dismissed');
      }
      return true;
    } catch (e) {
      debugPrint('Bulk dismiss alerts error: $e');
      return false;
    }
  }

  Future<bool> suspendRule(String ruleId) async {
    return updateAlertRule(ruleId: ruleId, status: 'paused');
  }

  Future<bool> activateRule(String ruleId) async {
    return updateAlertRule(ruleId: ruleId, status: 'active');
  }
}
