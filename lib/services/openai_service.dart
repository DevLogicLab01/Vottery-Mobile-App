import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/content_recommendation.dart';
import '../models/fraud_analysis_result.dart';
import '../models/quest.dart';
import './ai/ai_service_base.dart';

/// OpenAI Integration Service
/// Comprehensive AI features using GPT-5 for quest generation,
/// fraud detection, and content recommendations
class OpenAIService extends AIServiceBase {
  static OpenAIService? _instance;
  static OpenAIService get instance => _instance ??= OpenAIService._();

  OpenAIService._();

  static final SupabaseClient supabase = Supabase.instance.client;
  static bool _notificationsInitialized = false;
  static const bool _allowLegacyAI = bool.fromEnvironment(
    'ALLOW_LEGACY_AI',
    defaultValue: false,
  );

  static void _assertLegacyOpenAIAllowed() {
    if (!_allowLegacyAI) {
      throw AIServiceException(
        'OpenAI service is disabled by Batch-1 AI policy. Use Gemini/Anthropic routed services.',
      );
    }
  }

  /// Generate a text response to a prompt using the AI pipeline
  Future<String> generateResponse(String prompt, {String? systemPrompt}) async {
    _assertLegacyOpenAIAllowed();
    final response =
        await AIServiceBase.invokeAIFunction('openai-text-generation', {
          'prompt': prompt,
          'system_prompt': systemPrompt ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        });
    return response['content'] as String? ??
        response['text'] as String? ??
        jsonEncode(response);
  }

  /// Initialize notification system for security alerts
  static Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;

    try {
      await AwesomeNotifications().initialize(null, [
        NotificationChannel(
          channelKey: 'security_alerts',
          channelName: 'Security Alerts',
          channelDescription: 'High-priority fraud and security notifications',
          importance: NotificationImportance.Max,
          defaultColor: const Color(0xFFFF0000),
          ledColor: const Color(0xFFFF0000),
          playSound: true,
          enableVibration: true,
        ),
      ]);

      _notificationsInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  /// Personalized quest generation with GPT-5
  ///
  /// Generates AI-powered quests tailored to user behavior and preferences
  /// [userId] - User ID for personalization
  /// [difficulty] - Quest difficulty level (adaptive, easy, medium, hard)
  ///
  /// Returns List of personalized [Quest] objects
  static Future<List<Quest>> generatePersonalizedQuests({
    required String userId,
    String difficulty = 'adaptive',
  }) async {
    _assertLegacyOpenAIAllowed();
    try {
      final response =
          await AIServiceBase.invokeAIFunction('openai-quest-generation', {
            'user_id': userId,
            'difficulty': difficulty,
            'quest_count': 3,
            'timestamp': DateTime.now().toIso8601String(),
          });

      AIServiceBase.validateResponse(response, ['quests']);

      final questsData = response['quests'] as List<dynamic>;
      return questsData
          .map((e) => Quest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AIServiceException(
        'Failed to generate personalized quests: ${e.toString()}',
        e,
      );
    }
  }

  /// Real-time fraud detection with mobile notifications
  ///
  /// Analyzes voting data for fraud patterns using GPT-5
  /// Automatically triggers security alerts for high-risk fraud (score >= 70)
  ///
  /// [voteData] - Vote data to analyze
  /// [userId] - User ID associated with the vote
  ///
  /// Returns [FraudAnalysisResult] with risk assessment
  static Future<FraudAnalysisResult> analyzeFraudRisk({
    required Map<String, dynamic> voteData,
    required String userId,
  }) async {
    _assertLegacyOpenAIAllowed();
    try {
      final response =
          await AIServiceBase.invokeAIFunction('openai-fraud-detection', {
            'vote_data': voteData,
            'user_id': userId,
            'timestamp': DateTime.now().toIso8601String(),
          });

      AIServiceBase.validateResponse(response, [
        'analysis_id',
        'risk_score',
        'risk_level',
      ]);

      final result = FraudAnalysisResult.fromJson(response);

      // Trigger mobile notification for high-risk fraud
      if (result.riskScore >= 70) {
        await _triggerSecurityAlert(result);
      }

      return result;
    } catch (e) {
      throw AIServiceException(
        'Failed to analyze fraud risk: ${e.toString()}',
        e,
      );
    }
  }

  /// Trigger security alert notification for high-risk fraud
  ///
  /// Sends push notification to alert user of suspicious activity
  /// [result] - Fraud analysis result with risk details
  static Future<void> _triggerSecurityAlert(FraudAnalysisResult result) async {
    try {
      await _initializeNotifications();

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'security_alerts',
          title: '🚨 Security Alert: High-Risk Activity Detected',
          body:
              'Fraud risk score: ${result.riskScore.toStringAsFixed(1)}%. ${result.recommendation}',
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Alarm,
          criticalAlert: true,
          payload: {
            'analysis_id': result.analysisId,
            'risk_score': result.riskScore.toString(),
            'vote_id': result.voteId,
          },
        ),
      );

      // Log security alert
      await supabase.from('security_alerts').insert({
        'user_id': result.userId,
        'alert_type': 'fraud_detection',
        'severity': 'high',
        'analysis_id': result.analysisId,
        'risk_score': result.riskScore,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to trigger security alert: $e');
    }
  }

  /// AI-powered content recommendations
  ///
  /// Generates personalized content recommendations using GPT-5
  /// [userId] - User ID for personalization
  ///
  /// Returns List of [ContentRecommendation] objects
  static Future<List<ContentRecommendation>> getPersonalizedRecommendations(
    String userId,
  ) async {
    _assertLegacyOpenAIAllowed();
    try {
      final response = await AIServiceBase.invokeAIFunction(
        'openai-content-recommendations',
        {
          'user_id': userId,
          'recommendation_count': 10,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      AIServiceBase.validateResponse(response, ['recommendations']);

      final recommendationsData = response['recommendations'] as List<dynamic>;
      return recommendationsData
          .map((e) => ContentRecommendation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AIServiceException(
        'Failed to get personalized recommendations: ${e.toString()}',
        e,
      );
    }
  }

  /// Batch fraud analysis for multiple votes
  ///
  /// Analyzes multiple votes simultaneously for efficiency
  /// [voteDataList] - List of vote data to analyze
  ///
  /// Returns List of [FraudAnalysisResult]
  static Future<List<FraudAnalysisResult>> batchAnalyzeFraudRisk(
    List<Map<String, dynamic>> voteDataList,
  ) async {
    try {
      final results = await Future.wait(
        voteDataList.map(
          (voteData) => analyzeFraudRisk(
            voteData: voteData,
            userId: voteData['user_id'] as String? ?? '',
          ),
        ),
      );

      return results;
    } catch (e) {
      throw AIServiceException(
        'Batch fraud analysis failed: ${e.toString()}',
        e,
      );
    }
  }

  /// Generate quest with specific parameters
  ///
  /// Creates a single quest with custom requirements
  /// [userId] - User ID for personalization
  /// [questType] - Type of quest (daily, weekly, special)
  /// [parameters] - Custom quest parameters
  ///
  /// Returns single [Quest] object
  static Future<Quest> generateCustomQuest({
    required String userId,
    required String questType,
    Map<String, dynamic>? parameters,
  }) async {
    _assertLegacyOpenAIAllowed();
    try {
      final response =
          await AIServiceBase.invokeAIFunction('openai-quest-generation', {
            'user_id': userId,
            'quest_type': questType,
            'quest_count': 1,
            'parameters': parameters ?? {},
            'timestamp': DateTime.now().toIso8601String(),
          });

      AIServiceBase.validateResponse(response, ['quests']);

      final questsData = response['quests'] as List<dynamic>;
      if (questsData.isEmpty) {
        throw AIServiceException('No quest generated');
      }

      return Quest.fromJson(questsData.first as Map<String, dynamic>);
    } catch (e) {
      throw AIServiceException(
        'Failed to generate custom quest: ${e.toString()}',
        e,
      );
    }
  }

  /// Get fraud analysis history for user
  ///
  /// Retrieves past fraud analysis results
  /// [userId] - User ID to fetch history for
  /// [limit] - Maximum number of results
  ///
  /// Returns List of historical [FraudAnalysisResult]
  static Future<List<FraudAnalysisResult>> getFraudAnalysisHistory({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final response = await supabase
          .from('fraud_analysis_results')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map((e) => FraudAnalysisResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AIServiceException(
        'Failed to fetch fraud analysis history: ${e.toString()}',
        e,
      );
    }
  }

  /// Stream real-time fraud alerts
  ///
  /// Monitors fraud detection results in real-time
  /// [userId] - User ID to monitor
  ///
  /// Returns Stream of [FraudAnalysisResult]
  static Stream<FraudAnalysisResult> streamFraudAlerts(String userId) {
    try {
      return supabase
          .from('fraud_analysis_results')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((data) {
            if (data.isEmpty) {
              throw AIServiceException('No fraud data available');
            }
            return FraudAnalysisResult.fromJson(data.first);
          })
          .handleError((error) {
            throw AIServiceException(
              'Fraud alert stream error: ${error.toString()}',
              error,
            );
          });
    } catch (e) {
      throw AIServiceException(
        'Failed to create fraud alert stream: ${e.toString()}',
        e,
      );
    }
  }

  /// Check OpenAI service health
  ///
  /// Verifies that OpenAI integration is operational
  /// Returns true if service is healthy
  static Future<bool> isOpenAIServiceHealthy() async {
    try {
      final response = await AIServiceBase.invokeAIFunction('health-check', {
        'service': 'openai',
      });

      return response['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }

  /// Analyze text sentiment and themes
  static Future<Map<String, dynamic>> analyzeTextSentiment({
    required String text,
  }) async {
    try {
      final response =
          await AIServiceBase.invokeAIFunction('openai-text-analysis', {
            'text': text,
            'analysis_type': 'sentiment_and_themes',
            'timestamp': DateTime.now().toIso8601String(),
          });

      AIServiceBase.validateResponse(response, [
        'sentiment_score',
        'sentiment_label',
      ]);

      return {
        'sentiment_score': response['sentiment_score'] ?? 0.0,
        'sentiment_label': response['sentiment_label'] ?? 'neutral',
        'themes': response['themes'] ?? [],
        'moderation_flag': response['moderation_flag'] ?? false,
        'moderation_reason': response['moderation_reason'],
        'confidence': response['confidence'] ?? 0.0,
      };
    } catch (e) {
      debugPrint('Text sentiment analysis error: $e');
      return {
        'sentiment_score': 0.0,
        'sentiment_label': 'neutral',
        'themes': [],
        'moderation_flag': false,
        'moderation_reason': null,
        'confidence': 0.0,
      };
    }
  }
}
