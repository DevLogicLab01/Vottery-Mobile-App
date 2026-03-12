import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './ai_feature_adoption_analytics_service.dart';
import './auth_service.dart';
import './supabase_service.dart';

/// OpenAI Quest Generation Service
/// Generates personalized voting quests using GPT-5 with behavioral analysis
class OpenAIQuestService {
  static OpenAIQuestService? _instance;
  static OpenAIQuestService get instance =>
      _instance ??= OpenAIQuestService._();

  OpenAIQuestService._();

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

  /// Generate personalized quests based on user behavior
  Future<List<Map<String, dynamic>>> generatePersonalizedQuests({
    required String userId,
    String questType = 'daily',
  }) async {
    try {
      _initializeService();
      if (!_initialized || !_auth.isAuthenticated) {
        return _getFallbackQuests(questType);
      }

      final userBehavior = await _analyzeUserBehavior(userId);
      final prompt = _buildQuestPrompt(userBehavior, questType);

      final response = await OpenAI.instance.chat.create(
        model: 'gpt-4o',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                'You are a gamification AI that creates engaging civic participation quests. Generate quests in JSON format.',
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
        temperature: 0.7,
        maxTokens: 1000,
      );

      final content = response.choices.first.message.content?.first.text ?? '';
      final quests = _parseQuestResponse(content, userId, questType);

      if (quests.isEmpty) {
        return _getFallbackQuests(questType);
      }

      await _saveQuestsToDatabase(quests);

      // Fire GA4 ai_quest_generation event
      await AIFeatureAdoptionAnalyticsService.instance.logAIQuestGeneration(
        questCount: quests.length,
        difficulty:
            userBehavior['difficulty_preference'] as String? ?? 'medium',
        userPreferences: {
          'quest_type': questType,
          'top_categories': userBehavior['top_categories'] ?? [],
        },
        userId: userId,
      );

      return quests;
    } catch (e) {
      debugPrint('OpenAI quest generation error: $e');
      return _getFallbackQuests(questType);
    }
  }

  /// Advanced threat intelligence analysis
  Future<Map<String, dynamic>> analyzeThreatIntelligence({
    required Map<String, dynamic> threatData,
  }) async {
    try {
      if (apiKey.isEmpty) {
        return _getDefaultThreatAnalysis();
      }

      final prompt = _buildThreatPrompt(threatData);
      final response = await OpenAI.instance.chat.create(
        model: 'gpt-4o',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                'You are a security threat intelligence analyst. Analyze threats and provide comprehensive intelligence in JSON format.',
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
        temperature: 0.7,
        maxTokens: 1000,
      );

      final content = response.choices.first.message.content?.first.text ?? '';
      final analysis = _parseThreatResponse(content);

      await _logThreatAnalysis(threatData, analysis);
      return analysis;
    } catch (e) {
      debugPrint('OpenAI threat intelligence error: $e');
      return _getDefaultThreatAnalysis();
    }
  }

  String _buildThreatPrompt(Map<String, dynamic> threatData) {
    return '''
Analyze this security threat and provide comprehensive intelligence:

Threat Data:
${jsonEncode(threatData)}

Provide analysis in JSON format:
{
  "threat_level": "low|medium|high|critical",
  "threat_type": "...",
  "attack_vectors": [{"vector": "...", "likelihood": 0-1}],
  "indicators_of_compromise": ["..."],
  "recommended_actions": ["..."],
  "threat_actors": [{"name": "...", "motivation": "..."}],
  "forecast_60d": {"probability": 0-1, "confidence": 0-1},
  "mitigation_strategies": ["..."],
  "confidence": 0-1
}
''';
  }

  Map<String, dynamic> _parseThreatResponse(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return _getDefaultThreatAnalysis();
    }
  }

  Future<void> _logThreatAnalysis(
    Map<String, dynamic> threatData,
    Map<String, dynamic> analysis,
  ) async {
    try {
      await _client.from('threat_intelligence_logs').insert({
        'threat_data': threatData,
        'analysis_result': analysis,
        'ai_service': 'openai',
        'model': 'gpt-4o',
      });
    } catch (e) {
      debugPrint('Log threat analysis error: $e');
    }
  }

  Map<String, dynamic> _getDefaultThreatAnalysis() {
    return {
      'threat_level': 'low',
      'threat_type': 'unknown',
      'attack_vectors': [],
      'recommended_actions': ['Monitor situation', 'Review security logs'],
      'confidence': 0.5,
    };
  }

  /// Analyze user voting behavior for personalization
  Future<Map<String, dynamic>> _analyzeUserBehavior(String userId) async {
    try {
      final voteHistory = await _client
          .from('votes')
          .select('*, elections(category, title)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final categories = <String>{};
      int votingFrequency = voteHistory.length;
      String engagementLevel = votingFrequency > 20
          ? 'high'
          : votingFrequency > 10
          ? 'medium'
          : 'low';

      for (var vote in voteHistory) {
        final election = vote['elections'];
        if (election != null && election['category'] != null) {
          categories.add(election['category'] as String);
        }
      }

      final streakData = await _client
          .from('user_profiles')
          .select('voting_streak, level, xp')
          .eq('id', userId)
          .maybeSingle();

      return {
        'voting_frequency': votingFrequency,
        'favorite_categories': categories.toList(),
        'engagement_level': engagementLevel,
        'skill_level': streakData?['level'] ?? 1,
        'streak_count': streakData?['voting_streak'] ?? 0,
        'total_xp': streakData?['xp'] ?? 0,
      };
    } catch (e) {
      debugPrint('Analyze user behavior error: $e');
      return {
        'voting_frequency': 0,
        'favorite_categories': [],
        'engagement_level': 'low',
        'skill_level': 1,
        'streak_count': 0,
        'total_xp': 0,
      };
    }
  }

  String _buildQuestPrompt(
    Map<String, dynamic> userBehavior,
    String questType,
  ) {
    final duration = questType == 'daily' ? '24 hours' : '7 days';
    final questCount = 3;
    final skillLevel = userBehavior['skill_level'] as int;
    final categories = userBehavior['favorite_categories'] as List;

    return '''
Generate $questCount $questType quests for a civic engagement platform user.

User Profile:
- Voting Frequency: ${userBehavior['voting_frequency']}
- Favorite Categories: ${categories.join(', ')}
- Engagement Level: ${userBehavior['engagement_level']}
- Skill Level: $skillLevel
- Current Streak: ${userBehavior['streak_count']} days

Quest Requirements:
- Duration: $duration
- Types: voting, social, exploration, achievement
- Difficulty: ${_getDifficultyForLevel(skillLevel)}
- VP Rewards: ${_getVPRangeForLevel(skillLevel)}

Respond with ONLY a JSON array of quests:
[
  {
    "title": "Quest title",
    "description": "Quest description",
    "type": "voting|social|exploration|achievement",
    "difficulty": "easy|medium|hard",
    "target_value": 5,
    "vp_reward": 150,
    "requirements": {"category": "optional category"}
  }
]
''';
  }

  String _getDifficultyForLevel(int level) {
    if (level <= 4) return 'easy';
    if (level <= 9) return 'medium';
    return 'hard';
  }

  String _getVPRangeForLevel(int level) {
    if (level <= 4) return '50-150 VP';
    if (level <= 9) return '150-300 VP';
    return '300-500 VP';
  }

  List<Map<String, dynamic>> _parseQuestResponse(
    String response,
    String userId,
    String questType,
  ) {
    try {
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;
      if (jsonStart == -1 || jsonEnd == 0) return [];

      final jsonString = response.substring(jsonStart, jsonEnd);
      final List<dynamic> parsed = jsonDecode(jsonString);

      final duration = questType == 'daily' ? 24 : 168;
      final expiresAt = DateTime.now().add(Duration(hours: duration));

      return parsed.map((quest) {
        return {
          'user_id': userId,
          'title': quest['title'] ?? 'Complete Quest',
          'description': quest['description'] ?? '',
          'type': quest['type'] ?? 'voting',
          'difficulty': quest['difficulty'] ?? 'easy',
          'target_value': quest['target_value'] ?? 5,
          'current_progress': 0,
          'vp_reward': quest['vp_reward'] ?? 100,
          'status': 'active',
          'expires_at': expiresAt.toIso8601String(),
          'requirements': quest['requirements'] ?? {},
        };
      }).toList();
    } catch (e) {
      debugPrint('Parse quest response error: $e');
      return [];
    }
  }

  Future<void> _saveQuestsToDatabase(List<Map<String, dynamic>> quests) async {
    try {
      await _client.from('user_quests').insert(quests);
    } catch (e) {
      debugPrint('Save quests error: $e');
    }
  }

  List<Map<String, dynamic>> _getFallbackQuests(String questType) {
    final duration = questType == 'daily' ? 24 : 168;
    final expiresAt = DateTime.now().add(Duration(hours: duration));

    return [
      {
        'title': 'Cast Your First Vote',
        'description': 'Participate in any active election',
        'type': 'voting',
        'difficulty': 'easy',
        'target_value': 1,
        'vp_reward': 50,
        'expires_at': expiresAt.toIso8601String(),
      },
      {
        'title': 'Explore Categories',
        'description': 'Vote in 3 different categories',
        'type': 'exploration',
        'difficulty': 'medium',
        'target_value': 3,
        'vp_reward': 150,
        'expires_at': expiresAt.toIso8601String(),
      },
      {
        'title': 'Build Your Streak',
        'description': 'Vote on 5 consecutive days',
        'type': 'achievement',
        'difficulty': 'hard',
        'target_value': 5,
        'vp_reward': 300,
        'expires_at': expiresAt.toIso8601String(),
      },
    ];
  }

  Future<bool> updateQuestProgress({
    required String questId,
    required int progressIncrement,
  }) async {
    try {
      final quest = await _client
          .from('user_quests')
          .select()
          .eq('id', questId)
          .maybeSingle();

      if (quest == null) return false;

      final currentProgress = quest['current_progress'] as int;
      final targetValue = quest['target_value'] as int;
      final newProgress = currentProgress + progressIncrement;

      if (newProgress >= targetValue) {
        await _completeQuest(questId, quest['vp_reward'] as int);
        return true;
      }

      await _client
          .from('user_quests')
          .update({'current_progress': newProgress})
          .eq('id', questId);

      return false;
    } catch (e) {
      debugPrint('Update quest progress error: $e');
      return false;
    }
  }

  Future<void> _completeQuest(String questId, int vpReward) async {
    try {
      await _client
          .from('user_quests')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', questId);

      if (_auth.isAuthenticated) {
        await _client.rpc(
          'award_vp',
          params: {'user_id': _auth.currentUser!.id, 'vp_amount': vpReward},
        );
      }
    } catch (e) {
      debugPrint('Complete quest error: $e');
    }
  }
}
