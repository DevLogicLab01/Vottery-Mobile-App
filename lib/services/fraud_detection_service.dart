import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './multi_ai_orchestration_service.dart';
import './openai_fraud_service.dart';
import './claude_service.dart';
import './perplexity_service.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './analytics_service.dart';

class FraudDetectionService {
  static FraudDetectionService? _instance;
  static FraudDetectionService get instance =>
      _instance ??= FraudDetectionService._();

  FraudDetectionService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  MultiAIOrchestrationService get _orchestrator =>
      MultiAIOrchestrationService.instance;
  OpenAIFraudService get _openai => OpenAIFraudService.instance;
  ClaudeService get _claude => ClaudeService.instance;
  PerplexityService get _perplexity => PerplexityService.instance;
  AnalyticsService get _analytics => AnalyticsService.instance;

  static const double fraudThreshold = 70.0;
  static const double criticalThreshold = 85.0;

  /// Run comprehensive fraud detection with multi-AI consensus
  Future<Map<String, dynamic>> detectFraud({
    required String voteId,
    required Map<String, dynamic> voteData,
  }) async {
    try {
      final orchestrationResult = await _orchestrator.runMultiAIAnalysis(
        analysisType: 'fraud_detection',
        inputData: {'vote_id': voteId, ...voteData},
      );

      final fraudScore = _calculateFraudScore(orchestrationResult);
      final severity = _determineSeverity(fraudScore);
      final recommendation = orchestrationResult['recommendation'] ?? {};

      final result = {
        'vote_id': voteId,
        'fraud_score': fraudScore,
        'severity': severity,
        'confidence': recommendation['confidence'] ?? 0.0,
        'ai_consensus': orchestrationResult['consensus'] ?? {},
        'recommended_action': recommendation['action'] ?? 'manual_review',
        'reasoning': recommendation['reasoning'] ?? 'Multi-AI analysis',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _logFraudDetection(result);

      if (fraudScore >= fraudThreshold) {
        await _createFraudAlert(result);
        await _analytics.trackFraudAlert(
          alertType: 'vote_fraud',
          fraudScore: fraudScore,
          severity: severity,
        );
      }

      if (fraudScore >= criticalThreshold) {
        await _executeAutomatedAction(result);
      }

      return result;
    } catch (e) {
      debugPrint('Fraud detection error: $e');
      return {
        'vote_id': voteId,
        'fraud_score': 0.0,
        'severity': 'unknown',
        'error': e.toString(),
      };
    }
  }

  /// Get fraud detection history
  Future<List<Map<String, dynamic>>> getFraudHistory({
    int limit = 50,
    String? severity,
  }) async {
    try {
      var query = _client.from('fraud_detections').select();

      if (severity != null) {
        query = query.eq('severity', severity);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get fraud history error: $e');
      return [];
    }
  }

  /// Get fraud alerts requiring action
  Future<List<Map<String, dynamic>>> getFraudAlerts({
    bool unresolved = true,
  }) async {
    try {
      var query = _client.from('fraud_alerts').select();

      if (unresolved) {
        query = query.eq('is_resolved', false);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get fraud alerts error: $e');
      return [];
    }
  }

  /// Resolve fraud alert
  Future<bool> resolveFraudAlert({
    required String alertId,
    required String resolution,
    String? notes,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('fraud_alerts')
          .update({
            'is_resolved': true,
            'resolution': resolution,
            'resolution_notes': notes,
            'resolved_by': _auth.currentUser!.id,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);

      return true;
    } catch (e) {
      debugPrint('Resolve fraud alert error: $e');
      return false;
    }
  }

  /// Get fraud statistics
  Future<Map<String, dynamic>> getFraudStatistics() async {
    try {
      final response = await _client.rpc('get_fraud_statistics');
      return response ?? _getDefaultStatistics();
    } catch (e) {
      debugPrint('Get fraud statistics error: $e');
      return _getDefaultStatistics();
    }
  }

  double _calculateFraudScore(Map<String, dynamic> orchestrationResult) {
    final aiResults = orchestrationResult['ai_results'] as List? ?? [];
    if (aiResults.isEmpty) return 0.0;

    final scores = aiResults
        .where((r) => r['result'] != null && r['result']['fraud_score'] != null)
        .map((r) => (r['result']['fraud_score'] as num).toDouble())
        .toList();

    if (scores.isEmpty) return 0.0;

    return scores.reduce((a, b) => a + b) / scores.length;
  }

  String _determineSeverity(double fraudScore) {
    if (fraudScore >= 85) return 'critical';
    if (fraudScore >= 70) return 'high';
    if (fraudScore >= 50) return 'medium';
    if (fraudScore >= 30) return 'low';
    return 'minimal';
  }

  Future<void> _logFraudDetection(Map<String, dynamic> result) async {
    try {
      await _client.from('fraud_detections').insert({
        'vote_id': result['vote_id'],
        'fraud_score': result['fraud_score'],
        'severity': result['severity'],
        'confidence': result['confidence'],
        'ai_consensus': result['ai_consensus'],
        'recommended_action': result['recommended_action'],
        'reasoning': result['reasoning'],
      });
    } catch (e) {
      debugPrint('Log fraud detection error: $e');
    }
  }

  Future<void> _createFraudAlert(Map<String, dynamic> result) async {
    try {
      await _client.from('fraud_alerts').insert({
        'vote_id': result['vote_id'],
        'fraud_score': result['fraud_score'],
        'severity': result['severity'],
        'alert_type': 'automated_detection',
        'description':
            'Fraud detected with ${result['fraud_score'].toStringAsFixed(1)}% confidence',
        'recommended_action': result['recommended_action'],
        'is_resolved': false,
      });
    } catch (e) {
      debugPrint('Create fraud alert error: $e');
    }
  }

  Future<void> _executeAutomatedAction(Map<String, dynamic> result) async {
    try {
      final action = result['recommended_action'] as String?;
      final voteId = result['vote_id'] as String?;

      if (action == null || voteId == null) return;

      switch (action) {
        case 'flag':
          await _client
              .from('votes')
              .update({'is_flagged': true})
              .eq('id', voteId);
          break;
        case 'investigate':
          await _client.from('investigations').insert({
            'vote_id': voteId,
            'investigation_type': 'fraud',
            'priority': 'high',
            'status': 'open',
          });
          break;
        case 'suspend':
          await _client
              .from('votes')
              .update({'is_suspended': true})
              .eq('id', voteId);
          break;
      }
    } catch (e) {
      debugPrint('Execute automated action error: $e');
    }
  }

  Map<String, dynamic> _getDefaultStatistics() {
    return {
      'total_detections': 0,
      'critical_alerts': 0,
      'high_alerts': 0,
      'medium_alerts': 0,
      'low_alerts': 0,
      'resolved_alerts': 0,
      'average_fraud_score': 0.0,
    };
  }
}
