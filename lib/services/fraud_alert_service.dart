import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './twilio_notification_service.dart';

class FraudAlertService {
  static FraudAlertService? _instance;
  static FraudAlertService get instance => _instance ??= FraudAlertService._();

  FraudAlertService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  TwilioNotificationService get _twilio => TwilioNotificationService.instance;

  /// Create fraud alert escalation
  Future<Map<String, dynamic>?> createFraudAlert({
    required String alertType,
    required String severity,
    required String description,
    String? targetUserId,
    double? fraudScore,
  }) async {
    try {
      final response = await _client
          .from('fraud_alert_escalations')
          .insert({
            'alert_type': alertType,
            'severity': severity,
            'target_user_id': targetUserId,
            'fraud_score': fraudScore,
            'description': description,
            'escalation_status': 'pending',
          })
          .select()
          .single();

      // If critical and fraud score > 85%, trigger immediate SMS
      if (severity == 'critical' && fraudScore != null && fraudScore > 85) {
        await _triggerEmergencySMS(response);
      }

      return response;
    } catch (e) {
      debugPrint('Create fraud alert error: $e');
      return null;
    }
  }

  /// Get fraud alerts with filters
  Future<List<Map<String, dynamic>>> getFraudAlerts({
    String? severityFilter,
    String? statusFilter,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('fraud_alert_escalations').select();

      if (severityFilter != null && severityFilter.isNotEmpty) {
        query = query.eq('severity', severityFilter);
      }

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('escalation_status', statusFilter);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get fraud alerts error: $e');
      return [];
    }
  }

  /// Acknowledge fraud alert
  Future<bool> acknowledgeFraudAlert(String alertId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('fraud_alert_escalations')
          .update({
            'escalation_status': 'acknowledged',
            'acknowledged_by': _auth.currentUser!.id,
            'acknowledged_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);

      return true;
    } catch (e) {
      debugPrint('Acknowledge fraud alert error: $e');
      return false;
    }
  }

  /// Resolve fraud alert
  Future<bool> resolveFraudAlert(String alertId) async {
    try {
      await _client
          .from('fraud_alert_escalations')
          .update({
            'escalation_status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);

      return true;
    } catch (e) {
      debugPrint('Resolve fraud alert error: $e');
      return false;
    }
  }

  /// Get admin on-call rotation
  Future<List<Map<String, dynamic>>> getOnCallRotation() async {
    try {
      final today = DateTime.now();
      final response = await _client
          .from('admin_on_call_rotation')
          .select()
          .eq('is_active', true)
          .lte('start_date', today.toIso8601String().split('T')[0])
          .gte('end_date', today.toIso8601String().split('T')[0])
          .order('priority', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get on-call rotation error: $e');
      return [];
    }
  }

  /// Trigger emergency SMS with escalation workflow
  Future<void> _triggerEmergencySMS(Map<String, dynamic> alert) async {
    try {
      final onCallAdmins = await getOnCallRotation();
      if (onCallAdmins.isEmpty) {
        debugPrint('No on-call admins available');
        return;
      }

      // Try primary first
      final primary = onCallAdmins.firstWhere(
        (admin) => admin['priority'] == 'primary',
        orElse: () => onCallAdmins.first,
      );

      final message =
          'CRITICAL FRAUD ALERT: ${alert['description']}. '
          'Fraud Score: ${alert['fraud_score']}%. '
          'Alert ID: ${alert['id']}. '
          'Reply PAUSE [election_id], BAN [user_id], or APPROVE [withdrawal_id]';

      final phoneNumber =
          '${primary['country_code']}${primary['phone_number']}';
      final smsSent = await _twilio.sendUserActivityNotification(
        phoneNumber: phoneNumber,
        activityType: 'FRAUD_ALERT',
        details: message,
      );

      // Update alert with SMS status
      await _client
          .from('fraud_alert_escalations')
          .update({
            'sms_sent': smsSent,
            'sms_delivery_status': smsSent ? 'sent' : 'failed',
          })
          .eq('id', alert['id']);

      // If SMS failed or no acknowledgment after 5 minutes, escalate to secondary
      if (!smsSent) {
        await _escalateToSecondary(alert, onCallAdmins);
      }
    } catch (e) {
      debugPrint('Trigger emergency SMS error: $e');
    }
  }

  Future<void> _escalateToSecondary(
    Map<String, dynamic> alert,
    List<Map<String, dynamic>> onCallAdmins,
  ) async {
    try {
      final secondary = onCallAdmins.firstWhere(
        (admin) => admin['priority'] == 'secondary',
        orElse: () => onCallAdmins.last,
      );

      final message =
          'ESCALATED FRAUD ALERT: ${alert['description']}. '
          'Primary contact unavailable. '
          'Alert ID: ${alert['id']}';

      final phoneNumber =
          '${secondary['country_code']}${secondary['phone_number']}';
      await _twilio.sendUserActivityNotification(
        phoneNumber: phoneNumber,
        activityType: 'FRAUD_ALERT_ESCALATED',
        details: message,
      );
    } catch (e) {
      debugPrint('Escalate to secondary error: $e');
    }
  }

  /// Stream real-time fraud alerts
  Stream<List<Map<String, dynamic>>> streamFraudAlerts() {
    return _client
        .from('fraud_alert_escalations')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
}
