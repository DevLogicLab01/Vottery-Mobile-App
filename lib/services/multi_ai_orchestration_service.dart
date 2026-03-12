import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import './openai_fraud_service.dart';
import './claude_service.dart';
import './perplexity_service.dart';
import './supabase_service.dart';

class MultiAIOrchestrationService {
  static MultiAIOrchestrationService? _instance;
  static MultiAIOrchestrationService get instance =>
      _instance ??= MultiAIOrchestrationService._();

  MultiAIOrchestrationService._();

  OpenAIFraudService get _openai => OpenAIFraudService.instance;
  ClaudeService get _claude => ClaudeService.instance;
  PerplexityService get _perplexity => PerplexityService.instance;
  SupabaseClient get _client => SupabaseService.instance.client;

  Future<Map<String, dynamic>> runMultiAIAnalysis({
    required String analysisType,
    required Map<String, dynamic> inputData,
  }) async {
    try {
      final results = await Future.wait([
        _runOpenAIAnalysis(analysisType, inputData),
        _runClaudeAnalysis(analysisType, inputData),
        _runPerplexityAnalysis(analysisType, inputData),
      ]);

      final consensus = _detectConsensus(results);
      final recommendation = _generateWeightedRecommendation(
        results,
        consensus,
      );

      await _logOrchestrationResult({
        'analysis_type': analysisType,
        'ai_results': results,
        'consensus': consensus,
        'recommendation': recommendation,
      });

      if (consensus['has_consensus'] && recommendation['confidence'] >= 0.8) {
        await _executeAutomatedAction(recommendation);
      }

      return {
        'analysis_type': analysisType,
        'ai_results': results,
        'consensus': consensus,
        'recommendation': recommendation,
        'execution_status':
            consensus['has_consensus'] && recommendation['confidence'] >= 0.8
            ? 'automated'
            : 'manual_review_required',
      };
    } catch (e) {
      debugPrint('Multi-AI orchestration error: $e');
      return {
        'analysis_type': analysisType,
        'error': e.toString(),
        'execution_status': 'failed',
      };
    }
  }

  Future<Map<String, dynamic>> _runOpenAIAnalysis(
    String analysisType,
    Map<String, dynamic> inputData,
  ) async {
    try {
      if (analysisType == 'fraud_detection') {
        final result = await _openai.analyzeFraudRisk(
          voteId: inputData['vote_id'] ?? 'unknown',
          voteData: inputData,
        );
        return {
          'ai_service': 'openai',
          'model': 'gpt-4o',
          'confidence': result['confidence'] ?? 0.0,
          'result': result,
        };
      }
      return {'ai_service': 'openai', 'confidence': 0.0, 'result': {}};
    } catch (e) {
      return {'ai_service': 'openai', 'confidence': 0.0, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _runClaudeAnalysis(
    String analysisType,
    Map<String, dynamic> inputData,
  ) async {
    try {
      if (analysisType == 'security_incident') {
        final result = await _claude.analyzeSecurityIncident(
          incidentData: inputData,
        );
        return {
          'ai_service': 'claude',
          'model': 'claude-sonnet-4',
          'confidence': result['confidence'] ?? 0.0,
          'result': result,
        };
      } else if (analysisType == 'content_moderation') {
        final result = await _claude.moderateContent(
          content: inputData['content'] ?? '',
          contentType: inputData['content_type'] ?? 'text',
        );
        return {
          'ai_service': 'claude',
          'model': 'claude-sonnet-4',
          'confidence': result['risk_score'] != null
              ? result['risk_score'] / 100
              : 0.0,
          'result': result,
        };
      }
      return {'ai_service': 'claude', 'confidence': 0.0, 'result': {}};
    } catch (e) {
      return {'ai_service': 'claude', 'confidence': 0.0, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _runPerplexityAnalysis(
    String analysisType,
    Map<String, dynamic> inputData,
  ) async {
    try {
      if (analysisType == 'threat_intelligence') {
        final result = await _perplexity.analyzeThreatIntelligenceInstance(
          threatData: inputData,
        );
        return {
          'ai_service': 'perplexity',
          'model': 'sonar-reasoning',
          'confidence': result['forecast_60d']?['confidence'] ?? 0.0,
          'result': result,
        };
      } else if (analysisType == 'market_sentiment') {
        final result = await _perplexity.analyzeMarketSentiment(
          topic: inputData['topic'] ?? '',
          category: inputData['category'],
        );
        return {
          'ai_service': 'perplexity',
          'model': 'sonar-pro',
          'confidence': result['trend_forecast_30d']?['confidence'] ?? 0.0,
          'result': result,
        };
      }
      return {'ai_service': 'perplexity', 'confidence': 0.0, 'result': {}};
    } catch (e) {
      return {
        'ai_service': 'perplexity',
        'confidence': 0.0,
        'error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _detectConsensus(List<Map<String, dynamic>> results) {
    final confidences = results
        .map((r) => r['confidence'] as double? ?? 0.0)
        .where((c) => c > 0)
        .toList();

    if (confidences.isEmpty) {
      return {'has_consensus': false, 'variance': 1.0, 'agreement_level': 0.0};
    }

    final avgConfidence =
        confidences.reduce((a, b) => a + b) / confidences.length;
    final variance =
        confidences
            .map((c) => (c - avgConfidence) * (c - avgConfidence))
            .reduce((a, b) => a + b) /
        confidences.length;

    final hasConsensus = variance <= 0.15;
    final agreementLevel = 1.0 - variance;

    return {
      'has_consensus': hasConsensus,
      'variance': variance,
      'agreement_level': agreementLevel,
      'average_confidence': avgConfidence,
    };
  }

  Map<String, dynamic> _generateWeightedRecommendation(
    List<Map<String, dynamic>> results,
    Map<String, dynamic> consensus,
  ) {
    final validResults = results.where(
      (r) => r['confidence'] != null && r['confidence'] > 0,
    );

    if (validResults.isEmpty) {
      return {
        'action': 'manual_review',
        'confidence': 0.0,
        'reasoning': 'Insufficient AI analysis results',
      };
    }

    final totalConfidence = validResults.fold<double>(
      0.0,
      (sum, r) => sum + (r['confidence'] as double),
    );

    final weightedRecommendations = <String, double>{};
    for (var result in validResults) {
      final weight = (result['confidence'] as double) / totalConfidence;
      final action = _extractAction(result['result']);
      weightedRecommendations[action] =
          (weightedRecommendations[action] ?? 0.0) + weight;
    }

    final topAction = weightedRecommendations.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return {
      'action': topAction.key,
      'confidence': consensus['average_confidence'] ?? 0.0,
      'agreement_level': consensus['agreement_level'] ?? 0.0,
      'weighted_scores': weightedRecommendations,
      'reasoning':
          'Multi-AI consensus with ${(consensus['agreement_level'] * 100).toStringAsFixed(1)}% agreement',
    };
  }

  String _extractAction(Map<String, dynamic> result) {
    if (result.containsKey('recommended_action')) {
      return result['recommended_action'] as String;
    }
    if (result.containsKey('risk_level')) {
      final riskLevel = result['risk_level'] as String;
      if (riskLevel == 'critical' || riskLevel == 'high') return 'investigate';
      if (riskLevel == 'medium') return 'flag';
      return 'monitor';
    }
    return 'manual_review';
  }

  Future<void> _executeAutomatedAction(
    Map<String, dynamic> recommendation,
  ) async {
    try {
      final action = recommendation['action'] as String;
      debugPrint('Executing automated action: $action');

      await _client.from('orchestration_workflows').insert({
        'action': action,
        'confidence': recommendation['confidence'],
        'status': 'executed',
        'executed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Execute automated action error: $e');
    }
  }

  Future<void> _logOrchestrationResult(Map<String, dynamic> result) async {
    try {
      await _client.from('orchestration_workflows').insert({
        'analysis_type': result['analysis_type'],
        'ai_results': jsonEncode(result['ai_results']),
        'consensus': jsonEncode(result['consensus']),
        'recommendation': jsonEncode(result['recommendation']),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log orchestration result error: $e');
    }
  }
}
