import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class AlertAggregationService {
  static AlertAggregationService? _instance;
  static AlertAggregationService get instance =>
      _instance ??= AlertAggregationService._();

  AlertAggregationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Aggregate alerts from multiple sources
  Future<List<Map<String, dynamic>>> aggregateAlerts({
    List<String>? alertTypes,
    List<String>? severities,
    String? acknowledgmentStatus,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _client.from('unified_alerts').select();

      if (alertTypes != null && alertTypes.isNotEmpty) {
        query = query.inFilter('alert_type', alertTypes);
      }

      if (severities != null && severities.isNotEmpty) {
        query = query.inFilter('severity', severities);
      }

      if (acknowledgmentStatus != null) {
        query = query.eq('acknowledgment_status', acknowledgmentStatus);
      }

      if (startDate != null) {
        query = query.gte('detected_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('detected_at', endDate.toIso8601String());
      }

      final response = await query
          .order('detected_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Aggregate alerts error: $e');
      return [];
    }
  }

  /// Get alert summary metrics
  Future<Map<String, dynamic>> getAlertSummary() async {
    try {
      final allAlerts = await _client.from('unified_alerts').select();

      final alerts = List<Map<String, dynamic>>.from(allAlerts);

      final totalActive = alerts
          .where(
            (a) =>
                a['acknowledgment_status'] != 'resolved' &&
                a['acknowledgment_status'] != 'dismissed',
          )
          .length;

      final criticalAlerts = alerts
          .where((a) => a['severity'] == 'critical')
          .length;

      final unacknowledged = alerts
          .where((a) => a['acknowledgment_status'] == 'unacknowledged')
          .length;

      // Calculate average response time
      final acknowledgedAlerts = alerts.where(
        (a) =>
            a['acknowledgment_status'] == 'acknowledged' &&
            a['acknowledged_at'] != null,
      );

      double avgResponseTime = 0.0;
      if (acknowledgedAlerts.isNotEmpty) {
        final responseTimes = acknowledgedAlerts.map((a) {
          final detected = DateTime.parse(a['detected_at']);
          final acknowledged = DateTime.parse(a['acknowledged_at']);
          return acknowledged.difference(detected).inMinutes;
        });
        avgResponseTime =
            responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      }

      return {
        'total_active': totalActive,
        'critical_alerts': criticalAlerts,
        'unacknowledged': unacknowledged,
        'avg_response_time_minutes': avgResponseTime.round(),
      };
    } catch (e) {
      debugPrint('Get alert summary error: $e');
      return {
        'total_active': 0,
        'critical_alerts': 0,
        'unacknowledged': 0,
        'avg_response_time_minutes': 0,
      };
    }
  }

  /// Get alert counts by type
  Future<Map<String, int>> getAlertCountsByType() async {
    try {
      final response = await _client
          .from('unified_alerts')
          .select('alert_type');

      final alerts = List<Map<String, dynamic>>.from(response);
      final counts = <String, int>{};

      for (final alert in alerts) {
        final type = alert['alert_type'] as String;
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('Get alert counts by type error: $e');
      return {};
    }
  }

  /// Acknowledge alert
  Future<bool> acknowledgeAlert(String alertId, {String? note}) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('unified_alerts')
          .update({
            'acknowledgment_status': 'acknowledged',
            'assigned_to': _auth.currentUser!.id,
            'acknowledged_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);

      // Create timeline entry
      await _client.from('alert_timeline').insert({
        'alert_id': alertId,
        'event_type': 'acknowledged',
        'actor_id': _auth.currentUser!.id,
        'note': note,
      });

      return true;
    } catch (e) {
      debugPrint('Acknowledge alert error: $e');
      return false;
    }
  }

  /// Batch acknowledge alerts
  Future<Map<String, dynamic>> batchAcknowledgeAlerts(
    List<String> alertIds, {
    String? note,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      int successCount = 0;
      int failureCount = 0;
      final errors = <String>[];

      for (final alertId in alertIds) {
        try {
          await _client
              .from('unified_alerts')
              .update({
                'acknowledgment_status': 'acknowledged',
                'assigned_to': _auth.currentUser!.id,
                'acknowledged_at': DateTime.now().toIso8601String(),
              })
              .eq('id', alertId);

          await _client.from('alert_timeline').insert({
            'alert_id': alertId,
            'event_type': 'acknowledged',
            'actor_id': _auth.currentUser!.id,
            'note': note,
          });

          successCount++;
        } catch (e) {
          failureCount++;
          errors.add('Alert $alertId: ${e.toString()}');
        }
      }

      // Log batch operation
      await _client.from('alert_batch_operations').insert({
        'operation_type': 'acknowledge',
        'alert_ids': alertIds,
        'performed_by': _auth.currentUser!.id,
        'success_count': successCount,
        'failure_count': failureCount,
        'note': note,
      });

      return {
        'success': true,
        'success_count': successCount,
        'failure_count': failureCount,
        'errors': errors,
      };
    } catch (e) {
      debugPrint('Batch acknowledge error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Batch assign alerts
  Future<Map<String, dynamic>> batchAssignAlerts(
    List<String> alertIds,
    String assignedToUserId,
  ) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      int successCount = 0;
      int failureCount = 0;

      for (final alertId in alertIds) {
        try {
          await _client
              .from('unified_alerts')
              .update({'assigned_to': assignedToUserId})
              .eq('id', alertId);

          await _client.from('alert_timeline').insert({
            'alert_id': alertId,
            'event_type': 'assigned',
            'actor_id': _auth.currentUser!.id,
            'note': 'Assigned to user $assignedToUserId',
          });

          successCount++;
        } catch (e) {
          failureCount++;
        }
      }

      await _client.from('alert_batch_operations').insert({
        'operation_type': 'assign',
        'alert_ids': alertIds,
        'performed_by': _auth.currentUser!.id,
        'success_count': successCount,
        'failure_count': failureCount,
      });

      return {
        'success': true,
        'success_count': successCount,
        'failure_count': failureCount,
      };
    } catch (e) {
      debugPrint('Batch assign error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Batch dismiss alerts
  Future<Map<String, dynamic>> batchDismissAlerts(
    List<String> alertIds,
    String reason,
  ) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      int successCount = 0;
      int failureCount = 0;

      for (final alertId in alertIds) {
        try {
          await _client
              .from('unified_alerts')
              .update({
                'acknowledgment_status': 'dismissed',
                'dismissed_at': DateTime.now().toIso8601String(),
                'dismissed_by': _auth.currentUser!.id,
                'dismissal_reason': reason,
              })
              .eq('id', alertId);

          await _client.from('alert_timeline').insert({
            'alert_id': alertId,
            'event_type': 'dismissed',
            'actor_id': _auth.currentUser!.id,
            'note': reason,
          });

          successCount++;
        } catch (e) {
          failureCount++;
        }
      }

      await _client.from('alert_batch_operations').insert({
        'operation_type': 'dismiss',
        'alert_ids': alertIds,
        'performed_by': _auth.currentUser!.id,
        'success_count': successCount,
        'failure_count': failureCount,
        'note': reason,
      });

      return {
        'success': true,
        'success_count': successCount,
        'failure_count': failureCount,
      };
    } catch (e) {
      debugPrint('Batch dismiss error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Resolve alert
  Future<bool> resolveAlert(
    String alertId, {
    required String resolutionNotes,
    String? resolutionAction,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('unified_alerts')
          .update({
            'acknowledgment_status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
            'resolved_by': _auth.currentUser!.id,
            'resolution_notes': resolutionNotes,
            'resolution_action': resolutionAction,
          })
          .eq('id', alertId);

      await _client.from('alert_timeline').insert({
        'alert_id': alertId,
        'event_type': 'resolved',
        'actor_id': _auth.currentUser!.id,
        'note': resolutionNotes,
      });

      return true;
    } catch (e) {
      debugPrint('Resolve alert error: $e');
      return false;
    }
  }

  /// Add comment to alert
  Future<bool> addAlertComment(
    String alertId,
    String comment, {
    String? parentCommentId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('alert_comments').insert({
        'alert_id': alertId,
        'user_id': _auth.currentUser!.id,
        'comment': comment,
        'parent_comment_id': parentCommentId,
      });

      return true;
    } catch (e) {
      debugPrint('Add alert comment error: $e');
      return false;
    }
  }

  /// Get alert comments
  Future<List<Map<String, dynamic>>> getAlertComments(String alertId) async {
    try {
      final response = await _client
          .from('alert_comments')
          .select('*, user_profiles(username, avatar_url)')
          .eq('alert_id', alertId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get alert comments error: $e');
      return [];
    }
  }

  /// Stream real-time alerts
  Stream<List<Map<String, dynamic>>> streamAlerts() {
    return _client
        .from('unified_alerts')
        .stream(primaryKey: ['id'])
        .order('detected_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Export alerts to CSV
  Future<String> exportAlertsToCsv({
    List<String>? alertIds,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<Map<String, dynamic>> alerts;

      if (alertIds != null && alertIds.isNotEmpty) {
        alerts = await _client
            .from('unified_alerts')
            .select()
            .inFilter('id', alertIds);
      } else {
        var query = _client.from('unified_alerts').select();

        if (startDate != null) {
          query = query.gte('detected_at', startDate.toIso8601String());
        }
        if (endDate != null) {
          query = query.lte('detected_at', endDate.toIso8601String());
        }

        alerts = await query;
      }

      final csv = StringBuffer();
      csv.writeln(
        'Alert ID,Type,Severity,Title,Description,Detected At,Status,Assigned To',
      );

      for (final alert in alerts) {
        csv.writeln(
          '${alert['id']},${alert['alert_type']},${alert['severity']},'
          '"${alert['title']}","${alert['description']}",'
          '${alert['detected_at']},${alert['acknowledgment_status']},'
          '${alert['assigned_to'] ?? "Unassigned"}',
        );
      }

      return csv.toString();
    } catch (e) {
      debugPrint('Export alerts to CSV error: $e');
      return '';
    }
  }
}
