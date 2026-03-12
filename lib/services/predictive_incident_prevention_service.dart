import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import './perplexity_service.dart';
import './resend_email_service.dart';
import './twilio_notification_service.dart';

class PredictiveIncidentPreventionService {
  final SupabaseClient _client = Supabase.instance.client;
  late final PerplexityService _perplexityService;
  late final TwilioNotificationService _twilioService;
  late final ResendEmailService _resendService;

  PredictiveIncidentPreventionService() {
    _perplexityService = PerplexityService.instance;
    _twilioService = TwilioNotificationService.instance;
    _resendService = ResendEmailService.instance;
  }

  Future<Map<String, dynamic>> getPredictionOverview() async {
    final predictions24h = await _client
        .from('incident_predictions')
        .select()
        .eq('prediction_horizon_hours', 24)
        .order('predicted_at', ascending: false)
        .limit(1);

    final predictions48h = await _client
        .from('incident_predictions')
        .select()
        .eq('prediction_horizon_hours', 48)
        .order('predicted_at', ascending: false)
        .limit(1);

    final actionsToday = await _client
        .from('preventive_actions_log')
        .select()
        .gte(
          'executed_at',
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        )
        .count();

    return {
      'predictions_24h': predictions24h.isNotEmpty
          ? (jsonDecode(predictions24h[0]['predictions']) as List).length
          : 0,
      'predictions_48h': predictions48h.isNotEmpty
          ? (jsonDecode(predictions48h[0]['predictions']) as List).length
          : 0,
      'actions_today': actionsToday.count,
    };
  }

  Future<List<Map<String, dynamic>>> getPredictions(int horizonHours) async {
    final predictions = await _client
        .from('incident_predictions')
        .select()
        .eq('prediction_horizon_hours', horizonHours)
        .order('predicted_at', ascending: false)
        .limit(1);

    if (predictions.isEmpty) return [];

    final predictionsData = jsonDecode(predictions[0]['predictions']) as List;
    return predictionsData.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getPreventiveActions() async {
    final actions = await _client
        .from('preventive_actions_log')
        .select()
        .order('executed_at', ascending: false)
        .limit(20);

    return actions.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAccuracyMetrics() async {
    final metrics = await _client
        .from('prediction_accuracy_metrics')
        .select()
        .order('date', ascending: false)
        .limit(30);

    return metrics.cast<Map<String, dynamic>>();
  }

  Future<void> executePreventiveAction(String actionId) async {
    print('Executing action: $actionId');
  }

  Future<void> requestActionApproval(
    String actionId,
    String justification,
  ) async {
    await _client.from('action_approval_requests').insert({
      'action_id': actionId,
      'requested_at': DateTime.now().toIso8601String(),
      'justification': justification,
      'status': 'pending',
    });
  }
}
