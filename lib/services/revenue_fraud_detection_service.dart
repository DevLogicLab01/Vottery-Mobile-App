import 'package:supabase_flutter/supabase_flutter.dart';

import './resend_email_service.dart';
import './twilio_notification_service.dart';

class RevenueFraudDetectionService {
  final SupabaseClient _client = Supabase.instance.client;
  final TwilioNotificationService _twilioService =
      TwilioNotificationService.instance;
  final ResendEmailService _resendService = ResendEmailService.instance;

  Future<Map<String, dynamic>> getFraudOverview() async {
    final activeAlerts = await _client
        .from('fraud_alerts')
        .select()
        .eq('status', 'pending')
        .count();

    final blockedToday = await _client
        .from('fraud_alerts')
        .select('transaction_amount')
        .gte(
          'detected_at',
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        )
        .gt('risk_score', 90);

    final blockedAmount = blockedToday.isEmpty
        ? 0.0
        : blockedToday
              .map((a) => (a['transaction_amount'] as num?)?.toDouble() ?? 0.0)
              .reduce((a, b) => a + b);

    final confirmedCases = await _client
        .from('fraud_alerts')
        .select()
        .eq('status', 'confirmed')
        .gte(
          'detected_at',
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        )
        .count();

    return {
      'active_alerts': activeAlerts.count,
      'blocked_amount': blockedAmount,
      'confirmed_cases': confirmedCases.count,
      'false_positive_rate': 8.5,
    };
  }

  Future<List<Map<String, dynamic>>> getActiveAlerts() async {
    final alerts = await _client
        .from('fraud_alerts')
        .select()
        .eq('status', 'pending')
        .order('detected_at', ascending: false)
        .limit(50);

    return alerts.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getFraudPatterns() async {
    return [
      {
        'pattern_name': 'Payout Spike',
        'description': 'Sudden increase in payout amount',
        'detection_rate': 92,
        'false_positive_rate': 8,
      },
      {
        'pattern_name': 'Override Abuse',
        'description': 'Excessive creator overrides',
        'detection_rate': 88,
        'false_positive_rate': 12,
      },
    ];
  }

  Future<void> confirmFraud(String alertId, String explanation) async {
    await _client
        .from('fraud_alerts')
        .update({
          'status': 'confirmed',
          'resolution_explanation': explanation,
          'resolved_at': DateTime.now().toIso8601String(),
        })
        .eq('alert_id', alertId);
  }

  Future<void> markFalsePositive(String alertId, String explanation) async {
    await _client
        .from('fraud_alerts')
        .update({
          'status': 'false_positive',
          'resolution_explanation': explanation,
          'resolved_at': DateTime.now().toIso8601String(),
        })
        .eq('alert_id', alertId);
  }
}
