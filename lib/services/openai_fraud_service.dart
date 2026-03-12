import 'package:flutter/foundation.dart';
import 'package:dart_openai/dart_openai.dart';
import './supabase_service.dart';
import './auth_service.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class OpenAIFraudService {
  static OpenAIFraudService? _instance;
  static OpenAIFraudService get instance =>
      _instance ??= OpenAIFraudService._();

  OpenAIFraudService._();

  static const String apiKey = String.fromEnvironment('OPENAI_API_KEY');
  bool _initialized = false;

  AuthService get _auth => AuthService.instance;
  SupabaseClient get _client => SupabaseService.instance.client;

  void _initializeService() {
    if (_initialized) return;
    if (apiKey.isEmpty) {
      debugPrint('OPENAI_API_KEY not configured');
      return;
    }
    OpenAI.apiKey = apiKey;
    _initialized = true;
  }

  Future<Map<String, dynamic>> analyzeFraudRisk({
    required String voteId,
    required Map<String, dynamic> voteData,
  }) async {
    try {
      _initializeService();
      if (!_initialized) {
        return _getDefaultFraudAnalysis();
      }

      final votingContext = await _getVotingContext(voteData);
      final prompt = _buildFraudPrompt(voteData, votingContext);

      final response = await OpenAI.instance.chat.create(
        model: 'gpt-4o',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                'You are a fraud detection AI specializing in voting pattern analysis. Analyze voting behavior and respond in JSON format.',
              ),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
          ),
        ],
        temperature: 0.3,
        maxTokens: 1500,
        responseFormat: {'type': 'json_object'},
      );

      final content =
          response.choices.first.message.content?.first.text ?? '{}';
      final analysis = _parseFraudResponse(content, voteId);

      await _logFraudAnalysis(voteId, analysis);

      if (analysis['fraud_score'] >= 70) {
        await _createFraudAlert(voteId, analysis);
      }

      return analysis;
    } catch (e) {
      debugPrint('OpenAI fraud analysis error: $e');
      return _getDefaultFraudAnalysis();
    }
  }

  Future<Map<String, dynamic>> _getVotingContext(
    Map<String, dynamic> voteData,
  ) async {
    try {
      final userId = voteData['user_id'] as String?;
      final electionId = voteData['election_id'] as String?;

      if (userId == null || electionId == null) {
        return {'user_vote_history': [], 'election_vote_count': 0};
      }

      final userVotes = await _client
          .from('votes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final electionVotes = await _client
          .from('votes')
          .select('user_id, created_at')
          .eq('election_id', electionId);

      final recentVotes = electionVotes.where((vote) {
        final createdAt = DateTime.parse(vote['created_at'] as String);
        return DateTime.now().difference(createdAt).inMinutes <= 60;
      }).toList();

      return {
        'user_vote_history': userVotes,
        'election_vote_count': electionVotes.length,
        'recent_vote_velocity': recentVotes.length,
        'unique_voters': electionVotes.map((v) => v['user_id']).toSet().length,
      };
    } catch (e) {
      debugPrint('Get voting context error: $e');
      return {'user_vote_history': [], 'election_vote_count': 0};
    }
  }

  String _buildFraudPrompt(
    Map<String, dynamic> voteData,
    Map<String, dynamic> context,
  ) {
    return '''
Analyze this voting transaction for fraud risk:

Vote Data:
- User ID: ${voteData['user_id']}
- Election ID: ${voteData['election_id']}
- Timestamp: ${voteData['created_at']}
- IP Address: ${voteData['ip_address'] ?? 'unknown'}
- Device: ${voteData['device_info'] ?? 'unknown'}

Voting Context:
- User's Total Votes: ${(context['user_vote_history'] as List).length}
- Election Total Votes: ${context['election_vote_count']}
- Recent Vote Velocity (last hour): ${context['recent_vote_velocity']}
- Unique Voters: ${context['unique_voters']}

Analyze for:
1. Velocity Anomalies: Unusual voting speed or frequency
2. Pattern Matching: Repetitive behavior or bot-like patterns
3. Geographic Clustering: Multiple votes from same location
4. Temporal Anomalies: Suspicious timing patterns

Respond with JSON:
{
  "fraud_score": 0-100,
  "risk_level": "low|medium|high|critical",
  "confidence": 0.0-1.0,
  "suspicious_indicators": [
    {"type": "velocity|pattern|geographic|temporal", "description": "...", "severity": "low|medium|high"}
  ],
  "anomaly_types": ["velocity", "pattern", "geographic", "temporal"],
  "recommended_action": "monitor|flag|investigate|block",
  "reasoning": "Detailed explanation"
}
''';
  }

  Map<String, dynamic> _parseFraudResponse(String response, String voteId) {
    try {
      final parsed = jsonDecode(response) as Map<String, dynamic>;
      return {
        'vote_id': voteId,
        'fraud_score': parsed['fraud_score'] ?? 0,
        'risk_level': parsed['risk_level'] ?? 'low',
        'confidence': parsed['confidence'] ?? 0.0,
        'suspicious_indicators': parsed['suspicious_indicators'] ?? [],
        'anomaly_types': parsed['anomaly_types'] ?? [],
        'recommended_action': parsed['recommended_action'] ?? 'monitor',
        'reasoning': parsed['reasoning'] ?? '',
        'analyzed_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Parse fraud response error: $e');
      return _getDefaultFraudAnalysis();
    }
  }

  Map<String, dynamic> _getDefaultFraudAnalysis() {
    return {
      'fraud_score': 0,
      'risk_level': 'low',
      'confidence': 0.0,
      'suspicious_indicators': [],
      'anomaly_types': [],
      'recommended_action': 'monitor',
      'reasoning': 'Unable to perform fraud analysis',
      'analyzed_at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _logFraudAnalysis(
    String voteId,
    Map<String, dynamic> analysis,
  ) async {
    try {
      await _client.from('fraud_detection_logs').insert({
        'vote_id': voteId,
        'fraud_score': analysis['fraud_score'],
        'risk_level': analysis['risk_level'],
        'confidence': analysis['confidence'],
        'suspicious_indicators': analysis['suspicious_indicators'],
        'anomaly_types': analysis['anomaly_types'],
        'recommended_action': analysis['recommended_action'],
        'reasoning': analysis['reasoning'],
      });
    } catch (e) {
      debugPrint('Log fraud analysis error: $e');
    }
  }

  Future<void> _createFraudAlert(
    String voteId,
    Map<String, dynamic> analysis,
  ) async {
    try {
      await _client.from('fraud_alerts').insert({
        'vote_id': voteId,
        'fraud_score': analysis['fraud_score'],
        'risk_level': analysis['risk_level'],
        'alert_type': 'automated',
        'status': 'pending',
        'details': {
          'suspicious_indicators': analysis['suspicious_indicators'],
          'reasoning': analysis['reasoning'],
        },
      });
    } catch (e) {
      debugPrint('Create fraud alert error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> batchAnalyzeFraud(
    List<Map<String, dynamic>> votes,
  ) async {
    try {
      final results = <Map<String, dynamic>>[];
      for (var vote in votes) {
        final analysis = await analyzeFraudRisk(
          voteId: vote['id'] as String,
          voteData: vote,
        );
        results.add(analysis);
      }
      return results;
    } catch (e) {
      debugPrint('Batch fraud analysis error: $e');
      return [];
    }
  }
}
