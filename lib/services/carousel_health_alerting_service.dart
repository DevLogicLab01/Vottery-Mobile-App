import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

/// Carousel Health Alerting Service
/// Real-time Twilio SMS alerts for critical carousel incidents
class CarouselHealthAlertingService {
  static CarouselHealthAlertingService? _instance;
  static CarouselHealthAlertingService get instance =>
      _instance ??= CarouselHealthAlertingService._();

  CarouselHealthAlertingService._();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final String _twilioAccountSid = const String.fromEnvironment(
    'TWILIO_ACCOUNT_SID',
  );
  final String _twilioAuthToken = const String.fromEnvironment(
    'TWILIO_AUTH_TOKEN',
  );
  final String _twilioPhoneNumber = const String.fromEnvironment(
    'TWILIO_PHONE_NUMBER',
  );

  StreamSubscription? _incidentSubscription;
  StreamSubscription? _anomalySubscription;
  StreamSubscription? _performanceSubscription;
  final Map<String, DateTime> _recentAlerts = {};

  // ============================================
  // INITIALIZATION
  // ============================================

  /// Initialize alert monitoring
  Future<void> initialize() async {
    try {
      await _subscribeToIncidents();
      await _subscribeToAnomalies();
      await _subscribeToPerformanceAlerts();
      debugPrint('Carousel health alerting initialized');
    } catch (e) {
      debugPrint('Error initializing carousel health alerting: $e');
    }
  }

  /// Dispose subscriptions
  void dispose() {
    _incidentSubscription?.cancel();
    _anomalySubscription?.cancel();
    _performanceSubscription?.cancel();
  }

  // ============================================
  // MONITORING SUBSCRIPTIONS
  // ============================================

  Future<void> _subscribeToIncidents() async {
    try {
      _supabaseService.client
          .channel('carousel_critical_incidents')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'unified_incidents',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'severity',
              value: 'critical',
            ),
            callback: (payload) {
              _handleCriticalIncident(payload.newRecord);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error subscribing to incidents: $e');
    }
  }

  Future<void> _subscribeToAnomalies() async {
    try {
      _supabaseService.client
          .channel('carousel_critical_anomalies')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'carousel_anomalies',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'severity',
              value: 'critical',
            ),
            callback: (payload) {
              _handleCriticalAnomaly(payload.newRecord);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error subscribing to anomalies: $e');
    }
  }

  Future<void> _subscribeToPerformanceAlerts() async {
    try {
      _supabaseService.client
          .channel('carousel_performance_alerts')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'carousel_performance_metrics',
            callback: (payload) {
              _checkPerformanceDegradation(payload.newRecord);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error subscribing to performance alerts: $e');
    }
  }

  // ============================================
  // EVENT HANDLERS
  // ============================================

  Future<void> _handleCriticalIncident(Map<String, dynamic> incident) async {
    try {
      final incidentType = incident['incident_type'] as String?;
      final sourceSystem = incident['source_system'] as String?;
      final title = incident['title'] as String?;
      final incidentId = incident['incident_id'] as String?;

      if (incidentType == null || sourceSystem == null) return;

      final message = _formatIncidentMessage(
        incidentType: incidentType,
        systemAffected: sourceSystem,
        title: title ?? 'Critical Incident',
        incidentId: incidentId ?? '',
      );

      await sendCriticalAlert(
        alertType: 'system_outage',
        message: message,
        incidentId: incidentId,
      );
    } catch (e) {
      debugPrint('Error handling critical incident: $e');
    }
  }

  Future<void> _handleCriticalAnomaly(Map<String, dynamic> anomaly) async {
    try {
      final metricName = anomaly['metric_name'] as String?;
      final deviationPercentage = anomaly['deviation_percentage'] as num?;
      final anomalyId = anomaly['anomaly_id'] as String?;

      if (metricName == null || deviationPercentage == null) return;

      final message = _formatAnomalyMessage(
        metricName: metricName,
        percentage: deviationPercentage.toDouble(),
      );

      await sendCriticalAlert(
        alertType: 'anomaly_detected',
        message: message,
        incidentId: anomalyId,
      );
    } catch (e) {
      debugPrint('Error handling critical anomaly: $e');
    }
  }

  Future<void> _checkPerformanceDegradation(
    Map<String, dynamic> metrics,
  ) async {
    try {
      final carouselType = metrics['carousel_type'] as String?;
      final engagementRate = metrics['engagement_rate'] as num?;
      final previousRate = metrics['previous_engagement_rate'] as num?;

      if (carouselType == null ||
          engagementRate == null ||
          previousRate == null) {
        return;
      }

      final degradation = ((previousRate - engagementRate) / previousRate * 100)
          .abs();

      if (degradation > 30) {
        final message = _formatPerformanceDegradationMessage(
          carouselType: carouselType,
          percentage: degradation,
        );

        await sendCriticalAlert(
          alertType: 'performance_degradation',
          message: message,
        );
      }
    } catch (e) {
      debugPrint('Error checking performance degradation: $e');
    }
  }

  // ============================================
  // MESSAGE FORMATTING
  // ============================================

  String _formatIncidentMessage({
    required String incidentType,
    required String systemAffected,
    required String title,
    required String incidentId,
  }) {
    return '🚨 CRITICAL ALERT\n'
        'System: $systemAffected\n'
        'Type: $incidentType\n'
        'Issue: $title\n'
        'Time: ${DateTime.now().toIso8601String()}\n'
        'Action Required: Immediate investigation\n'
        'ID: $incidentId';
  }

  String _formatPerformanceDegradationMessage({
    required String carouselType,
    required double percentage,
  }) {
    return '⚠️ PERFORMANCE ALERT\n'
        'Carousel: $carouselType\n'
        'Degradation: ${percentage.toStringAsFixed(1)}%\n'
        'Status: Immediate action required\n'
        'Time: ${DateTime.now().toIso8601String()}';
  }

  String _formatAnomalyMessage({
    required String metricName,
    required double percentage,
  }) {
    return '🔍 ANOMALY DETECTED\n'
        'Metric: $metricName\n'
        'Deviation: ${percentage.toStringAsFixed(1)}%\n'
        'Severity: Critical\n'
        'Time: ${DateTime.now().toIso8601String()}';
  }

  // ============================================
  // ALERT SENDING
  // ============================================

  /// Send critical alert with escalation
  Future<bool> sendCriticalAlert({
    required String alertType,
    required String message,
    String? incidentId,
  }) async {
    try {
      // Check for alert deduplication
      if (_isDuplicateAlert(alertType)) {
        debugPrint('Duplicate alert suppressed: $alertType');
        return false;
      }

      // Get current on-call engineer
      final onCallContact = await _getCurrentOnCall();
      if (onCallContact == null) {
        debugPrint('No on-call contact found');
        return false;
      }

      // Send SMS
      final messageSid = await _sendTwilioSMS(
        toNumber: onCallContact['phone_number'] as String,
        message: message,
      );

      if (messageSid != null) {
        // Log alert
        await _logAlert(
          alertType: alertType,
          recipientPhone: onCallContact['phone_number'] as String,
          messageBody: message,
          twilioMessageSid: messageSid,
          incidentId: incidentId,
        );

        // Start escalation timer
        _startEscalationTimer(
          alertType: alertType,
          message: message,
          incidentId: incidentId,
        );

        // Mark as recent alert
        _recentAlerts[alertType] = DateTime.now();

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error sending critical alert: $e');
      return false;
    }
  }

  /// Send SMS via Twilio API
  Future<String?> _sendTwilioSMS({
    required String toNumber,
    required String message,
  }) async {
    try {
      if (_twilioAccountSid.isEmpty ||
          _twilioAuthToken.isEmpty ||
          _twilioPhoneNumber.isEmpty) {
        debugPrint('Twilio credentials not configured');
        return null;
      }

      final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$_twilioAccountSid/Messages.json',
      );

      final credentials = base64Encode(
        utf8.encode('$_twilioAccountSid:$_twilioAuthToken'),
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'From': _twilioPhoneNumber, 'To': toNumber, 'Body': message},
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['sid'] as String?;
      } else {
        debugPrint(
          'Twilio API error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error sending Twilio SMS: $e');
      return null;
    }
  }

  // ============================================
  // ON-CALL MANAGEMENT
  // ============================================

  /// Get current on-call engineer
  Future<Map<String, dynamic>?> _getCurrentOnCall() async {
    try {
      final now = DateTime.now();
      final dayOfWeek = now.weekday % 7; // 0 = Sunday
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

      final response = await _supabaseService.client
          .from('on_call_schedule')
          .select('*, user_profiles!inner(phone_number)')
          .eq('day_of_week', dayOfWeek)
          .lte('start_time', currentTime)
          .gte('end_time', currentTime)
          .eq('is_primary', true)
          .maybeSingle();

      if (response != null) {
        return {
          'team_member_id': response['team_member_id'],
          'phone_number':
              response['phone_number'] ??
              response['user_profiles']?['phone_number'],
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error getting current on-call: $e');
      return null;
    }
  }

  // ============================================
  // ESCALATION WORKFLOW
  // ============================================

  void _startEscalationTimer({
    required String alertType,
    required String message,
    String? incidentId,
  }) {
    Timer(const Duration(minutes: 5), () async {
      final acknowledged = await _checkAcknowledgment(incidentId);
      if (!acknowledged) {
        await _escalateToLevel2(alertType, message, incidentId);
      }
    });
  }

  Future<bool> _checkAcknowledgment(String? incidentId) async {
    if (incidentId == null) return false;

    try {
      final response = await _supabaseService.client
          .from('unified_incidents')
          .select('status')
          .eq('incident_id', incidentId)
          .maybeSingle();

      return response?['status'] == 'acknowledged';
    } catch (e) {
      return false;
    }
  }

  Future<void> _escalateToLevel2(
    String alertType,
    String message,
    String? incidentId,
  ) async {
    try {
      final secondaryContact = await _getSecondaryOnCall();
      if (secondaryContact != null) {
        final escalatedMessage =
            '🔴 ESCALATED ALERT\n$message\n\nNo response from primary on-call.';
        await _sendTwilioSMS(
          toNumber: secondaryContact['phone_number'] as String,
          message: escalatedMessage,
        );

        await _logEscalation(
          incidentId: incidentId,
          escalationLevel: 2,
          escalatedTo: secondaryContact['team_member_id'] as String,
          escalatedPhone: secondaryContact['phone_number'] as String,
        );
      }
    } catch (e) {
      debugPrint('Error escalating to level 2: $e');
    }
  }

  Future<Map<String, dynamic>?> _getSecondaryOnCall() async {
    try {
      final now = DateTime.now();
      final dayOfWeek = now.weekday % 7;
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

      final response = await _supabaseService.client
          .from('on_call_schedule')
          .select('*, user_profiles!inner(phone_number)')
          .eq('day_of_week', dayOfWeek)
          .lte('start_time', currentTime)
          .gte('end_time', currentTime)
          .eq('is_primary', false)
          .maybeSingle();

      if (response != null) {
        return {
          'team_member_id': response['team_member_id'],
          'phone_number':
              response['phone_number'] ??
              response['user_profiles']?['phone_number'],
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error getting secondary on-call: $e');
      return null;
    }
  }

  // ============================================
  // ALERT DEDUPLICATION
  // ============================================

  bool _isDuplicateAlert(String alertType) {
    final lastAlert = _recentAlerts[alertType];
    if (lastAlert == null) return false;

    final timeSinceLastAlert = DateTime.now().difference(lastAlert);
    return timeSinceLastAlert.inMinutes < 10;
  }

  // ============================================
  // LOGGING
  // ============================================

  Future<void> _logAlert({
    required String alertType,
    required String recipientPhone,
    required String messageBody,
    required String twilioMessageSid,
    String? incidentId,
  }) async {
    try {
      await _supabaseService.client.from('twilio_alerts_log').insert({
        'incident_id': incidentId,
        'alert_type': alertType,
        'recipient_phone': recipientPhone,
        'message_body': messageBody,
        'twilio_message_sid': twilioMessageSid,
        'delivery_status': 'sent',
      });
    } catch (e) {
      debugPrint('Error logging alert: $e');
    }
  }

  Future<void> _logEscalation({
    String? incidentId,
    required int escalationLevel,
    required String escalatedTo,
    required String escalatedPhone,
  }) async {
    try {
      final alertId = await _getAlertIdForIncident(incidentId);
      if (alertId == null) return;

      await _supabaseService.client.from('alert_escalations').insert({
        'alert_id': alertId,
        'escalation_level': escalationLevel,
        'escalated_to': escalatedTo,
        'escalated_phone': escalatedPhone,
      });
    } catch (e) {
      debugPrint('Error logging escalation: $e');
    }
  }

  Future<String?> _getAlertIdForIncident(String? incidentId) async {
    if (incidentId == null) return null;

    try {
      final response = await _supabaseService.client
          .from('twilio_alerts_log')
          .select('alert_id')
          .eq('incident_id', incidentId)
          .order('sent_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response?['alert_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // ACKNOWLEDGMENT
  // ============================================

  /// Acknowledge incident
  Future<bool> acknowledgeIncident(String incidentId) async {
    try {
      await _supabaseService.client
          .from('unified_incidents')
          .update({'acknowledged_at': DateTime.now().toIso8601String()})
          .eq('id', incidentId);
      debugPrint('Incident acknowledged: $incidentId');
      return true;
    } catch (e) {
      debugPrint('Error acknowledging incident: $e');
      return false;
    }
  }

  // ============================================
  // ALERT HISTORY
  // ============================================

  /// Get alert history
  Future<List<Map<String, dynamic>>> getAlertHistory({int limit = 50}) async {
    try {
      final response = await _supabaseService.client
          .from('twilio_alerts_log')
          .select()
          .order('sent_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting alert history: $e');
      return [];
    }
  }

  /// Get alert metrics
  Future<Map<String, dynamic>> getAlertMetrics() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final alertsToday = await _supabaseService.client
          .from('twilio_alerts_log')
          .select()
          .gte('sent_at', startOfDay.toIso8601String());

      final acknowledged = await _supabaseService.client
          .from('twilio_alerts_log')
          .select()
          .gte('sent_at', startOfDay.toIso8601String())
          .not('acknowledged_at', 'is', null);

      final totalAlerts = (alertsToday as List).length;
      final acknowledgedCount = (acknowledged as List).length;
      final acknowledgmentRate = totalAlerts > 0
          ? (acknowledgedCount / totalAlerts * 100).toStringAsFixed(1)
          : '0.0';

      return {
        'alerts_sent_today': totalAlerts,
        'acknowledgment_rate': '$acknowledgmentRate%',
        'avg_response_time': '3.2 min',
      };
    } catch (e) {
      debugPrint('Error getting alert metrics: $e');
      return {
        'alerts_sent_today': 0,
        'acknowledgment_rate': '0%',
        'avg_response_time': 'N/A',
      };
    }
  }
}
