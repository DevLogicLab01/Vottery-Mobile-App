import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import './auth_service.dart';
import './voting_service.dart';

class GeminiService {
  static GeminiService? _instance;
  static GeminiService get instance => _instance ??= GeminiService._();

  GeminiService._();

  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');
  GenerativeModel? _model;

  AuthService get _auth => AuthService.instance;
  VotingService get _voting => VotingService.instance;

  void _initializeService() {
    if (apiKey.isEmpty) {
      debugPrint('GEMINI_API_KEY not configured');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({
    required List<Map<String, dynamic>> allVotes,
    int limit = 5,
  }) async {
    try {
      if (_model == null) {
        _initializeService();
      }

      if (_model == null || !_auth.isAuthenticated) {
        return _getFallbackRecommendations(allVotes, limit);
      }

      final userHistory = await _voting.getUserVoteHistory(limit: 20);
      final userContext = await _buildUserContext(userHistory, allVotes);

      final prompt = _buildRecommendationPrompt(userContext, allVotes);

      final response = await _model!.generateContent([Content.text(prompt)]);
      final recommendedIds = _parseRecommendations(response.text ?? '');

      final recommendations = allVotes.where((vote) {
        return recommendedIds.contains(vote['id']);
      }).toList();

      if (recommendations.isEmpty) {
        return _getFallbackRecommendations(allVotes, limit);
      }

      return recommendations.take(limit).toList();
    } catch (e) {
      debugPrint('Gemini recommendation error: $e');
      return _getFallbackRecommendations(allVotes, limit);
    }
  }

  Future<Map<String, dynamic>> _buildUserContext(
    List<Map<String, dynamic>> userHistory,
    List<Map<String, dynamic>> allVotes,
  ) async {
    final votedCategories = <String>{};
    final votedTopics = <String>[];

    for (var vote in userHistory) {
      final election = vote['elections'];
      if (election != null) {
        final category = election['category'] as String?;
        final title = election['title'] as String?;
        if (category != null) votedCategories.add(category);
        if (title != null) votedTopics.add(title);
      }
    }

    final trendingVotes = allVotes
        .where((v) => (v['trending_score'] as int? ?? 0) > 50)
        .take(10)
        .toList();

    return {
      'voted_categories': votedCategories.toList(),
      'voted_topics': votedTopics,
      'vote_count': userHistory.length,
      'trending_topics': trendingVotes.map((v) => v['title']).toList(),
    };
  }

  String _buildRecommendationPrompt(
    Map<String, dynamic> userContext,
    List<Map<String, dynamic>> allVotes,
  ) {
    final votedCategories = userContext['voted_categories'] as List;
    final votedTopics = userContext['voted_topics'] as List;
    final trendingTopics = userContext['trending_topics'] as List;

    final availableVotes = allVotes
        .map((vote) {
          return '${vote['id']}: ${vote['title']} (Category: ${vote['category']}, Votes: ${vote['totalVotes']})';
        })
        .join('\n');

    return '''
You are a civic engagement AI assistant. Recommend votes for a user based on their interests and trending topics.

User Profile:
- Previously voted in categories: ${votedCategories.join(', ')}
- Previously voted on topics: ${votedTopics.take(5).join(', ')}
- Total votes cast: ${userContext['vote_count']}

Trending Topics:
${trendingTopics.take(5).join(', ')}

Available Votes:
$availableVotes

Task: Recommend 5 vote IDs that match the user's interests and trending topics. Consider:
1. User's voting history and preferred categories
2. Trending topics with high engagement
3. Diverse recommendations across different categories
4. Votes with active participation

Respond ONLY with comma-separated vote IDs (e.g., vote_1,vote_2,vote_3,vote_4,vote_5). No explanations.
''';
  }

  List<String> _parseRecommendations(String response) {
    try {
      final cleaned = response.trim().replaceAll(RegExp(r'[\n\r]'), '');
      return cleaned
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Parse recommendations error: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _getFallbackRecommendations(
    List<Map<String, dynamic>> allVotes,
    int limit,
  ) {
    final sorted = List<Map<String, dynamic>>.from(allVotes);
    sorted.sort((a, b) {
      final aScore = (a['trending_score'] as int? ?? 0);
      final bScore = (b['trending_score'] as int? ?? 0);
      return bScore.compareTo(aScore);
    });
    return sorted.take(limit).toList();
  }

  Future<String> getVoteInsights({
    required String voteTitle,
    required String voteDescription,
    required int totalVotes,
    required List<Map<String, dynamic>> options,
  }) async {
    try {
      if (_model == null) {
        _initializeService();
      }

      if (_model == null) {
        return 'AI insights unavailable. Please configure GEMINI_API_KEY.';
      }

      final optionsText = options
          .map((opt) {
            return '${opt['option_text']}: ${opt['vote_count'] ?? 0} votes';
          })
          .join(', ');

      final prompt =
          '''
Analyze this civic vote and provide a brief insight (2-3 sentences):

Title: $voteTitle
Description: $voteDescription
Total Votes: $totalVotes
Options: $optionsText

Provide a concise analysis of voting patterns, engagement level, and what this indicates about community priorities.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate insights at this time.';
    } catch (e) {
      debugPrint('Gemini insights error: $e');
      return 'AI insights temporarily unavailable.';
    }
  }

  /// Analyze security incidents for health monitoring
  static Future<Map<String, dynamic>> analyzeSecurityIncident({
    required String incidentId,
    required Map<String, dynamic> incidentData,
  }) async {
    try {
      if (apiKey.isEmpty) {
        return {'status': 'error', 'message': 'GEMINI_API_KEY not configured'};
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 512,
        ),
      );

      final prompt =
          '''
Analyze security incident:

Incident ID: $incidentId
Data: ${incidentData.toString()}

Provide brief security assessment (1-2 sentences).
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return {
        'status': 'success',
        'analysis': response.text ?? 'Analysis completed',
        'incident_id': incidentId,
      };
    } catch (e) {
      debugPrint('Gemini security analysis error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
