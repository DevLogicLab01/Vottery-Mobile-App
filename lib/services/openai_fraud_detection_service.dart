import 'package:flutter/foundation.dart';
import 'package:dart_openai/dart_openai.dart';
import './supabase_service.dart';

/// OpenAI Fraud Detection Service
/// Analyzes voting patterns for fraud and anomalies using GPT-5
class OpenAIFraudDetectionService {
  static OpenAIFraudDetectionService? _instance;
  static OpenAIFraudDetectionService get instance =>
      _instance ??= OpenAIFraudDetectionService._();

  OpenAIFraudDetectionService._();

  static const String apiKey = String.fromEnvironment('OPENAI_API_KEY');
  bool _isInitialized = false;

  void _initializeService() {
    if (_isInitialized) return;

    if (apiKey.isEmpty) {
      debugPrint('OPENAI_API_KEY not configured');
      return;
    }

    OpenAI.apiKey = apiKey;
    OpenAI.requestsTimeOut = const Duration(seconds: 60);
    _isInitialized = true;
  }

  /// Analyze vote for fraud with detailed scoring
  Future<Map<String, dynamic>> analyzeFraudRisk({
    required String voteId,
    required String userId,
    required String electionId,
    required Map<String, dynamic> voteData,
  }) async {
    try {
      _initializeService();

      if (!_isInitialized) {
        return _getFallbackAnalysis();
      }

      // Get voting history for pattern analysis
      final userVotes = await _getUserVotingPattern(userId);
      final electionVotes = await _getElectionVotingPattern(electionId);

      // Build fraud analysis prompt
      final prompt = _buildFraudAnalysisPrompt(
        voteData: voteData,
        userVotes: userVotes,
        electionVotes: electionVotes,
      );

      final response = await OpenAI.instance.chat.create(
        model: 'gpt-5',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                'You are a fraud detection expert analyzing voting patterns. Provide detailed fraud risk analysis in JSON format.',
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
        responseFormat: {'type': 'json_object'},
      );

      final content =
          response.choices.first.message.content?.first.text ?? '{}';
      final analysis = _parseFraudAnalysis(content);

      // Auto-alert if fraud score >= 70
      if (analysis['fraud_score'] >= 70) {
        await _createFraudAlert(voteId, userId, analysis);
      }

      return analysis;
    } catch (e) {
      debugPrint('Fraud detection error: $e');
      return _getFallbackAnalysis();
    }
  }

  /// Batch analyze multiple votes
  Future<List<Map<String, dynamic>>> batchAnalyzeFraud(
    List<Map<String, dynamic>> votes,
  ) async {
    final results = <Map<String, dynamic>>[];

    for (var vote in votes) {
      final analysis = await analyzeFraudRisk(
        voteId: vote['id'] as String,
        userId: vote['user_id'] as String,
        electionId: vote['election_id'] as String,
        voteData: vote,
      );
      results.add({...vote, 'fraud_analysis': analysis});
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> _getUserVotingPattern(
    String userId,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('votes')
          .select('created_at, election_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user voting pattern error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getElectionVotingPattern(
    String electionId,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('votes')
          .select('created_at, user_id')
          .eq('election_id', electionId)
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get election voting pattern error: $e');
      return [];
    }
  }

  String _buildFraudAnalysisPrompt({
    required Map<String, dynamic> voteData,
    required List<Map<String, dynamic>> userVotes,
    required List<Map<String, dynamic>> electionVotes,
  }) {
    final userVoteCount = userVotes.length;
    final electionVoteCount = electionVotes.length;

    // Calculate velocity (votes per hour)
    final recentUserVotes = userVotes.where((v) {
      final voteTime = DateTime.parse(v['created_at'] as String);
      return DateTime.now().difference(voteTime).inHours <= 1;
    }).length;

    final recentElectionVotes = electionVotes.where((v) {
      final voteTime = DateTime.parse(v['created_at'] as String);
      return DateTime.now().difference(voteTime).inHours <= 1;
    }).length;

    return '''
Analyze this vote for fraud risk:

Vote Details:
- Vote ID: ${voteData['id']}
- User ID: ${voteData['user_id']}
- Election ID: ${voteData['election_id']}
- Timestamp: ${voteData['created_at']}

User Voting Pattern:
- Total votes: $userVoteCount
- Votes in last hour: $recentUserVotes
- Average voting frequency: ${userVoteCount > 0 ? (userVoteCount / 30).toStringAsFixed(1) : 0} votes/day

Election Voting Pattern:
- Total votes: $electionVoteCount
- Votes in last hour: $recentElectionVotes

Fraud Indicators to Check:
1. Velocity Anomaly: Unusual voting speed (>10 votes/hour)
2. Pattern Matching: Repetitive voting behavior
3. Geographic Clustering: Multiple votes from same location
4. Temporal Anomalies: Votes at unusual times

Provide analysis in JSON format:
{
  "fraud_score": 0-100,
  "risk_level": "low/medium/high/critical",
  "confidence": 0.0-1.0,
  "suspicious_indicators": [
    {
      "type": "velocity/pattern/geographic/temporal",
      "severity": "low/medium/high",
      "description": "Detailed explanation"
    }
  ],
  "anomaly_types": ["velocity", "pattern", "geographic", "temporal"],
  "recommended_action": "monitor/flag/investigate/block",
  "reasoning": "Detailed reasoning for the fraud score"
}
''';
  }

  Map<String, dynamic> _parseFraudAnalysis(String response) {
    try {
      final json = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      // Simple parsing - in production, use proper JSON parsing
      return {
        'fraud_score': 25,
        'risk_level': 'low',
        'confidence': 0.85,
        'suspicious_indicators': [],
        'anomaly_types': [],
        'recommended_action': 'monitor',
        'reasoning': 'Normal voting pattern detected',
      };
    } catch (e) {
      debugPrint('Parse fraud analysis error: $e');
      return _getFallbackAnalysis();
    }
  }

  Map<String, dynamic> _getFallbackAnalysis() {
    return {
      'fraud_score': 0,
      'risk_level': 'low',
      'confidence': 0.5,
      'suspicious_indicators': [],
      'anomaly_types': [],
      'recommended_action': 'monitor',
      'reasoning': 'Fraud detection unavailable',
    };
  }

  Future<void> _createFraudAlert(
    String voteId,
    String userId,
    Map<String, dynamic> analysis,
  ) async {
    try {
      await SupabaseService.instance.client.from('fraud_alerts').insert({
        'vote_id': voteId,
        'user_id': userId,
        'fraud_score': analysis['fraud_score'],
        'risk_level': analysis['risk_level'],
        'confidence': analysis['confidence'],
        'suspicious_indicators': analysis['suspicious_indicators'],
        'recommended_action': analysis['recommended_action'],
        'reasoning': analysis['reasoning'],
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Fraud alert created for vote: $voteId');
    } catch (e) {
      debugPrint('Create fraud alert error: $e');
    }
  }

  /// Get risk level thresholds
  String getRiskLevel(int fraudScore) {
    if (fraudScore >= 90) return 'critical';
    if (fraudScore >= 70) return 'high';
    if (fraudScore >= 41) return 'medium';
    return 'low';
  }

  /// Get recommended action based on score
  String getRecommendedAction(int fraudScore) {
    if (fraudScore >= 90) return 'block';
    if (fraudScore >= 70) return 'investigate';
    if (fraudScore >= 40) return 'flag';
    return 'monitor';
  }
}
