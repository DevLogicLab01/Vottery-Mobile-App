import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/twilio_notification_service.dart';

class TwilioEmergencyAlertService {
  static final TwilioEmergencyAlertService _instance =
      TwilioEmergencyAlertService._internal();
  factory TwilioEmergencyAlertService() => _instance;
  TwilioEmergencyAlertService._internal();

  final _supabase = Supabase.instance.client;
  final _twilioService = TwilioNotificationService.instance;

  /// Send critical fraud alert SMS
  Future<Map<String, dynamic>> sendCriticalFraudAlert({
    required String analysisId,
    required String patternName,
    required double confidenceScore,
    required int affectedUserCount,
    required int evidenceCount,
    required String dashboardUrl,
  }) async {
    try {
      print('🚨 Sending critical fraud alert SMS');

      // Get on-call security analyst
      final onCallData = await _getOnCallContact('security');
      if (onCallData == null) {
        print('⚠️ No on-call security analyst found');
        return {'success': false, 'error': 'No on-call contact available'};
      }

      // Construct SMS message
      final message =
          '''🚨 CRITICAL FRAUD ALERT
Type: $patternName
Confidence: ${(confidenceScore * 100).toStringAsFixed(0)}%
Affected: $affectedUserCount users
Evidence: $evidenceCount logs
Action Required: Review immediately
Dashboard: $dashboardUrl''';

      // Send SMS
      final smsResult = await _sendSMS(
        phoneNumber: onCallData['phone'],
        message: message,
        alertType: 'fraud',
        severity: 'critical',
        recipientUserId: onCallData['user_id'],
        metadata: {
          'analysis_id': analysisId,
          'pattern_name': patternName,
          'confidence_score': confidenceScore,
        },
      );

      // Try backup contact if primary fails
      if (!smsResult['success'] && onCallData['backup_user_id'] != null) {
        final backupData = await _getUserContact(onCallData['backup_user_id']);
        if (backupData != null) {
          await _sendSMS(
            phoneNumber: backupData['phone'],
            message: message,
            alertType: 'fraud',
            severity: 'critical',
            recipientUserId: backupData['user_id'],
            metadata: {'analysis_id': analysisId, 'escalated_to_backup': true},
          );
        }
      }

      return smsResult;
    } catch (e, stackTrace) {
      print('❌ Critical fraud alert failed: $e');
      print(stackTrace);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send AI failover alert SMS
  Future<Map<String, dynamic>> sendAIFailoverAlert({
    required String serviceName,
    required String backupService,
    required String failureReason,
    required int expectedDurationMinutes,
    required String affectedOperations,
    required String dashboardUrl,
  }) async {
    try {
      print('⚠️ Sending AI failover alert SMS');

      // Get on-call DevOps engineer
      final onCallData = await _getOnCallContact('devops');
      if (onCallData == null) {
        print('⚠️ No on-call DevOps engineer found');
        return {'success': false, 'error': 'No on-call contact available'};
      }

      // Construct SMS message
      final message =
          '''⚠️ AI SERVICE FAILOVER
Failed: $serviceName
Backup: $backupService
Reason: $failureReason
Expected Duration: ${expectedDurationMinutes}min
Impact: $affectedOperations
Monitor: $dashboardUrl''';

      // Send SMS
      final smsResult = await _sendSMS(
        phoneNumber: onCallData['phone'],
        message: message,
        alertType: 'failover',
        severity: 'high',
        recipientUserId: onCallData['user_id'],
        metadata: {
          'service_name': serviceName,
          'backup_service': backupService,
          'failure_reason': failureReason,
        },
      );

      return smsResult;
    } catch (e, stackTrace) {
      print('❌ AI failover alert failed: $e');
      print(stackTrace);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get on-call contact for team
  Future<Map<String, dynamic>?> _getOnCallContact(String teamType) async {
    try {
      final response = await _supabase
          .from('on_call_schedules')
          .select(
            'current_on_call_user_id, current_on_call_phone, next_on_call_user_id',
          )
          .eq('team_name', teamType)
          .gte('on_call_until', DateTime.now().toIso8601String())
          .maybeSingle();

      if (response == null) return null;

      return {
        'user_id': response['current_on_call_user_id'],
        'phone': response['current_on_call_phone'],
        'backup_user_id': response['next_on_call_user_id'],
      };
    } catch (e) {
      print('Error getting on-call contact: $e');
      return null;
    }
  }

  /// Get user contact info
  Future<Map<String, dynamic>?> _getUserContact(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('id, phone_number')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return {'user_id': response['id'], 'phone': response['phone_number']};
    } catch (e) {
      print('Error getting user contact: $e');
      return null;
    }
  }

  /// Send SMS with retry logic
  Future<Map<String, dynamic>> _sendSMS({
    required String phoneNumber,
    required String message,
    required String alertType,
    required String severity,
    String? recipientUserId,
    Map<String, dynamic>? metadata,
  }) async {
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Call Twilio service
        final success = await _twilioService.sendUserActivityNotification(
          phoneNumber: phoneNumber,
          activityType: 'Emergency Alert',
          details: message,
        );

        // Log alert
        final alertLog = await _supabase
            .from('sms_alerts_log')
            .insert({
              'alert_type': alertType,
              'severity': severity,
              'recipient_phone': phoneNumber,
              'recipient_user_id': recipientUserId,
              'message': message,
              'delivery_status': success ? 'sent' : 'failed',
              'metadata': metadata ?? {},
            })
            .select()
            .single();

        if (success) {
          print('✅ SMS alert sent successfully');
          return {
            'success': true,
            'alert_id': alertLog['alert_id'],
            'delivery_status': 'sent',
          };
        }

        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      } catch (e) {
        print('SMS send attempt ${retryCount + 1} failed: $e');
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }
    }

    return {'success': false, 'error': 'Failed after $maxRetries attempts'};
  }

  /// Acknowledge alert
  Future<bool> acknowledgeAlert({
    required String alertId,
    required String acknowledgedBy,
    required String method,
    String? responseNotes,
  }) async {
    try {
      // Update alert
      await _supabase
          .from('sms_alerts_log')
          .update({
            'acknowledged_at': DateTime.now().toIso8601String(),
            'response_time_minutes': null, // Calculate in trigger
          })
          .eq('alert_id', alertId);

      // Insert acknowledgment
      await _supabase.from('alert_acknowledgments').insert({
        'alert_id': alertId,
        'acknowledged_by': acknowledgedBy,
        'acknowledgment_method': method,
        'response_notes': responseNotes,
      });

      return true;
    } catch (e) {
      print('Error acknowledging alert: $e');
      return false;
    }
  }

  /// Get alert history
  Future<List<Map<String, dynamic>>> getAlertHistory({
    String? alertType,
    int limit = 50,
  }) async {
    try {
      var query = _supabase.from('sms_alerts_log').select();

      if (alertType != null) {
        query = query.eq('alert_type', alertType);
      }

      final response = await query
          .order('sent_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting alert history: $e');
      return [];
    }
  }

  /// Get alert analytics
  Future<Map<String, dynamic>> getAlertAnalytics() async {
    try {
      final response = await _supabase.from('sms_alerts_log').select();

      final total = response.length;
      final delivered = response
          .where((r) => r['delivery_status'] == 'delivered')
          .length;
      final acknowledged = response
          .where((r) => r['acknowledged_at'] != null)
          .length;

      final acknowledgedAlerts = response.where(
        (r) => r['acknowledged_at'] != null && r['sent_at'] != null,
      );
      final avgResponseTime = acknowledgedAlerts.isEmpty
          ? 0.0
          : acknowledgedAlerts
                    .map((r) {
                      final sent = DateTime.parse(r['sent_at']);
                      final acked = DateTime.parse(r['acknowledged_at']);
                      return acked.difference(sent).inMinutes;
                    })
                    .reduce((a, b) => a + b) /
                acknowledgedAlerts.length;

      return {
        'total_alerts': total,
        'delivered': delivered,
        'acknowledged': acknowledged,
        'acknowledgment_rate': total > 0
            ? (acknowledged / total * 100).toStringAsFixed(1)
            : '0.0',
        'avg_response_time_minutes': avgResponseTime.toStringAsFixed(1),
      };
    } catch (e) {
      print('Error getting alert analytics: $e');
      return {
        'total_alerts': 0,
        'delivered': 0,
        'acknowledged': 0,
        'acknowledgment_rate': '0.0',
        'avg_response_time_minutes': '0.0',
      };
    }
  }
}
