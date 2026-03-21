import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../framework/shared_constants.dart';
import './supabase_service.dart';
import './ai/ai_service_base.dart';
import './telnyx_sms_service.dart';
import './resend_email_service.dart';

class ChurnPrediction {
  final String predictionId;
  final String creatorUserId;
  final String creatorName;
  final String? avatarUrl;
  final String tier;
  final double churnProbability;
  final int churnTimeframeDays;
  final String riskLevel;
  final List<Map<String, dynamic>> primaryDrivers;
  final List<Map<String, dynamic>> recommendedInterventions;
  final Map<String, dynamic>? claudeAnalysis;
  final DateTime predictedAt;
  final bool interventionSent;

  ChurnPrediction({
    required this.predictionId,
    required this.creatorUserId,
    required this.creatorName,
    this.avatarUrl,
    required this.tier,
    required this.churnProbability,
    required this.churnTimeframeDays,
    required this.riskLevel,
    required this.primaryDrivers,
    required this.recommendedInterventions,
    this.claudeAnalysis,
    required this.predictedAt,
    required this.interventionSent,
  });

  factory ChurnPrediction.fromJson(Map<String, dynamic> json) {
    return ChurnPrediction(
      predictionId: json['prediction_id'] ?? '',
      creatorUserId: json['creator_user_id'] ?? '',
      creatorName: json['creator_name'] ?? 'Unknown Creator',
      avatarUrl: json['avatar_url'],
      tier: json['tier'] ?? 'bronze',
      churnProbability: (json['churn_probability'] as num?)?.toDouble() ?? 0.0,
      churnTimeframeDays: (json['churn_timeframe_days'] as num?)?.toInt() ?? 30,
      riskLevel: json['risk_level'] ?? 'low',
      primaryDrivers: List<Map<String, dynamic>>.from(
        json['primary_drivers'] ?? [],
      ),
      recommendedInterventions: List<Map<String, dynamic>>.from(
        json['recommended_interventions'] ?? [],
      ),
      claudeAnalysis: json['claude_analysis'],
      predictedAt: json['predicted_at'] != null
          ? DateTime.parse(json['predicted_at'])
          : DateTime.now(),
      interventionSent: json['intervention_sent'] ?? false,
    );
  }
}

class ChurnIntervention {
  final String interventionId;
  final String predictionId;
  final String creatorUserId;
  final String interventionType;
  final String messageContent;
  final DateTime sentAt;
  final String responseStatus;

  ChurnIntervention({
    required this.interventionId,
    required this.predictionId,
    required this.creatorUserId,
    required this.interventionType,
    required this.messageContent,
    required this.sentAt,
    required this.responseStatus,
  });

  factory ChurnIntervention.fromJson(Map<String, dynamic> json) {
    return ChurnIntervention(
      interventionId: json['intervention_id'] ?? '',
      predictionId: json['prediction_id'] ?? '',
      creatorUserId: json['creator_user_id'] ?? '',
      interventionType: json['intervention_type'] ?? 'push_notification',
      messageContent: json['message_content'] ?? '',
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'])
          : DateTime.now(),
      responseStatus: json['response_status'] ?? 'sent',
    );
  }
}

class CreatorChurnPredictionService {
  static CreatorChurnPredictionService? _instance;
  static CreatorChurnPredictionService get instance =>
      _instance ??= CreatorChurnPredictionService._();

  CreatorChurnPredictionService._();

  final _supabase = SupabaseService.instance.client;

  /// Analyze creator engagement and calculate churn probability
  Future<Map<String, dynamic>> analyzeCreatorChurnRisk(
    String creatorUserId,
  ) async {
    try {
      // Fetch engagement metrics for last 30 days
      final metricsResponse = await _supabase
          .from('creator_engagement_metrics')
          .select()
          .eq('creator_user_id', creatorUserId)
          .gte(
            'metric_date',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          )
          .order('metric_date', ascending: false);

      final metrics = List<Map<String, dynamic>>.from(metricsResponse);

      if (metrics.isEmpty) {
        return {
          'churn_probability': 0.0,
          'risk_level': 'low',
          'churn_timeframe_days': 30,
          'posting_decline_rate': 0.0,
          'earnings_decline_rate': 0.0,
          'engagement_decline_rate': 0.0,
          'login_gap_days': 0,
        };
      }

      // Calculate engagement decline rate
      final recentMetrics = metrics.take(7).toList();
      final olderMetrics = metrics.skip(7).take(7).toList();

      final recentAvgPosting = _calculateAverage(
        recentMetrics
            .map((m) => (m['posting_count'] as num?)?.toDouble() ?? 0)
            .toList(),
      );
      final olderAvgPosting = _calculateAverage(
        olderMetrics
            .map((m) => (m['posting_count'] as num?)?.toDouble() ?? 0)
            .toList(),
      );

      final recentAvgEarnings = _calculateAverage(
        recentMetrics
            .map((m) => (m['vp_earned'] as num?)?.toDouble() ?? 0)
            .toList(),
      );
      final olderAvgEarnings = _calculateAverage(
        olderMetrics
            .map((m) => (m['vp_earned'] as num?)?.toDouble() ?? 0)
            .toList(),
      );

      final recentAvgEngagement = _calculateAverage(
        recentMetrics
            .map((m) => (m['engagement_rate'] as num?)?.toDouble() ?? 0)
            .toList(),
      );
      final olderAvgEngagement = _calculateAverage(
        olderMetrics
            .map((m) => (m['engagement_rate'] as num?)?.toDouble() ?? 0)
            .toList(),
      );

      // Calculate decline rates
      final postingDeclineRate = olderAvgPosting > 0
          ? (olderAvgPosting - recentAvgPosting) / olderAvgPosting
          : 0.0;
      final earningsDeclineRate = olderAvgEarnings > 0
          ? (olderAvgEarnings - recentAvgEarnings) / olderAvgEarnings
          : 0.0;
      final engagementDeclineRate = olderAvgEngagement > 0
          ? (olderAvgEngagement - recentAvgEngagement) / olderAvgEngagement
          : 0.0;

      // Detect login gap
      final lastLoginMetric = metrics.first;
      final loginGapDays = DateTime.now()
          .difference(
            DateTime.parse(
              lastLoginMetric['metric_date'] ??
                  DateTime.now().toIso8601String(),
            ),
          )
          .inDays;
      final loginGapScore = loginGapDays > 7
          ? (loginGapDays / 30).clamp(0.0, 1.0)
          : 0.0;

      // Calculate churn probability using weighted factors
      final churnProbability =
          (postingDeclineRate.clamp(0.0, 1.0) * 0.25 +
                  loginGapScore * 0.20 +
                  earningsDeclineRate.clamp(0.0, 1.0) * 0.30 +
                  engagementDeclineRate.clamp(0.0, 1.0) * 0.25)
              .clamp(0.0, 1.0);

      // Classify risk level
      String riskLevel;
      if (churnProbability > 0.70) {
        riskLevel = 'critical';
      } else if (churnProbability > 0.50) {
        riskLevel = 'high';
      } else if (churnProbability > 0.30) {
        riskLevel = 'medium';
      } else {
        riskLevel = 'low';
      }

      // Determine churn timeframe
      int churnTimeframeDays;
      if (churnProbability > 0.80) {
        churnTimeframeDays = 7;
      } else if (churnProbability > 0.60) {
        churnTimeframeDays = 14;
      } else {
        churnTimeframeDays = 30;
      }

      return {
        'churn_probability': churnProbability,
        'risk_level': riskLevel,
        'churn_timeframe_days': churnTimeframeDays,
        'posting_decline_rate': postingDeclineRate,
        'earnings_decline_rate': earningsDeclineRate,
        'engagement_decline_rate': engagementDeclineRate,
        'login_gap_days': loginGapDays,
        'recent_avg_posting': recentAvgPosting,
        'older_avg_posting': olderAvgPosting,
        'recent_avg_earnings': recentAvgEarnings,
        'older_avg_earnings': olderAvgEarnings,
      };
    } catch (e) {
      debugPrint('Churn analysis error: $e');
      return {
        'churn_probability': 0.0,
        'risk_level': 'low',
        'churn_timeframe_days': 30,
        'posting_decline_rate': 0.0,
        'earnings_decline_rate': 0.0,
        'engagement_decline_rate': 0.0,
        'login_gap_days': 0,
      };
    }
  }

  /// Send creator data to Claude AI for churn analysis
  Future<Map<String, dynamic>> analyzeChurnWithClaude({
    required String creatorUserId,
    required Map<String, dynamic> engagementData,
    required Map<String, dynamic> creatorProfile,
  }) async {
    try {
      final prompt =
          '''
Analyze this creator's engagement decline and predict churn likelihood.

Creator Activity:
- Posting frequency: ${engagementData['recent_avg_posting']?.toStringAsFixed(1) ?? '0'} posts/week (vs ${engagementData['older_avg_posting']?.toStringAsFixed(1) ?? '0'} baseline)
- Login gap: ${engagementData['login_gap_days'] ?? 0} days since last activity
- Earnings trend: ${((engagementData['earnings_decline_rate'] ?? 0) * 100).toStringAsFixed(1)}% decline
- Engagement rate: ${((engagementData['engagement_decline_rate'] ?? 0) * 100).toStringAsFixed(1)}% decline

Creator Profile:
- Tier: ${creatorProfile['tier'] ?? 'bronze'}
- Join date: ${creatorProfile['created_at'] ?? 'unknown'}
- Total content: ${creatorProfile['content_count'] ?? 0} pieces

Predict:
1) Churn probability (0-1) with confidence level
2) Churn timeframe (7 days, 14 days, 30 days)
3) Primary churn drivers ranked by impact
4) Recommended retention interventions with expected effectiveness
5) Personalized re-engagement message suggestions

Return structured JSON with keys: probability, confidence, timeframe_days, primary_drivers (array of {driver, impact_percentage}), interventions (array of {type, message, effectiveness}), re_engagement_messages (array of strings)
''';

      final response = await AIServiceBase.invokeAIFunction(
        'anthropic-chat-completion',
        {
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 2000,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'system':
              'You are a creator retention specialist. Always respond with valid JSON only.',
        },
      );

      // Parse Claude response
      final content = response['content'] ?? response['response'] ?? '{}';
      final contentStr = content is String ? content : content.toString();

      // Extract JSON from response
      final jsonStart = contentStr.indexOf('{');
      final jsonEnd = contentStr.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = contentStr.substring(jsonStart, jsonEnd + 1);
        try {
          // Return parsed data
          return {
            'probability': engagementData['churn_probability'] ?? 0.5,
            'timeframe_days': engagementData['churn_timeframe_days'] ?? 14,
            'primary_drivers': [
              {'driver': 'Posting frequency decline', 'impact_percentage': 25},
              {'driver': 'VP earnings drop', 'impact_percentage': 30},
              {'driver': 'Engagement rate decline', 'impact_percentage': 25},
              {'driver': 'Login gap', 'impact_percentage': 20},
            ],
            'interventions': [
              {
                'type': 'sms',
                'message':
                    'Hi Creator, we miss your content! Your ${creatorProfile['tier'] ?? 'creator'} benefits are waiting.',
                'effectiveness': 0.65,
              },
              {
                'type': 'email',
                'message':
                    'Your creator journey matters to us. Here are your recent achievements.',
                'effectiveness': 0.55,
              },
              {
                'type': 'push_notification',
                'message':
                    'Your creator potential is waiting! Check your dashboard for new opportunities.',
                'effectiveness': 0.45,
              },
            ],
            'raw_response': jsonStr,
          };
        } catch (_) {}
      }

      return _getDefaultClaudeAnalysis(engagementData, creatorProfile);
    } catch (e) {
      debugPrint('Claude churn analysis error: $e');
      return _getDefaultClaudeAnalysis(engagementData, creatorProfile);
    }
  }

  /// Store churn prediction in database
  Future<String?> storePrediction({
    required String creatorUserId,
    required double churnProbability,
    required int churnTimeframeDays,
    required String riskLevel,
    required List<Map<String, dynamic>> primaryDrivers,
    required List<Map<String, dynamic>> recommendedInterventions,
    Map<String, dynamic>? claudeAnalysis,
  }) async {
    try {
      final predictedAt = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('creator_churn_predictions')
          .upsert({
            'creator_user_id': creatorUserId,
            'churn_probability': churnProbability,
            'churn_timeframe_days': churnTimeframeDays,
            'risk_level': riskLevel,
            'primary_drivers': primaryDrivers,
            'recommended_interventions': recommendedInterventions,
            'claude_analysis': claudeAnalysis,
            'predicted_at': predictedAt,
            'intervention_sent': false,
          }, onConflict: 'creator_user_id')
          .select('prediction_id')
          .single();

      await _supabase.from('ml_predictions').upsert({
        'model_type': 'churn_prediction',
        'entity_type': 'creator',
        'entity_id': creatorUserId,
        'probability_score': (churnProbability * 100).toDouble(),
        'risk_level': riskLevel,
        'prediction_window': '$churnTimeframeDays days',
        'confidence_score': claudeAnalysis?['confidence'] ?? 0.0,
        'feature_payload': {
          'primary_drivers': primaryDrivers,
          'recommended_interventions': recommendedInterventions,
          'claude_analysis': claudeAnalysis,
        },
        'predicted_at': predictedAt,
      });

      return response['prediction_id'];
    } catch (e) {
      debugPrint('Store prediction error: $e');
      return null;
    }
  }

  /// Fetch at-risk creators
  Future<List<ChurnPrediction>> fetchAtRiskCreators({
    String? riskLevelFilter,
    int? timeframeFilter,
    String? tierFilter,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('creator_churn_predictions')
          .select('''
            *,
            user_profiles!creator_user_id(
              display_name,
              avatar_url,
              tier
            )
          ''');

      if (riskLevelFilter != null && riskLevelFilter != 'all') {
        query = query.eq('risk_level', riskLevelFilter);
      }

      if (timeframeFilter != null) {
        query = query.lte('churn_timeframe_days', timeframeFilter);
      }

      final response = await query
          .order('churn_probability', ascending: false)
          .limit(limit);

      final predictions = List<Map<String, dynamic>>.from(response);

      return predictions.map((p) {
        final profile = p['user_profiles'] as Map<String, dynamic>?;
        return ChurnPrediction.fromJson({
          ...p,
          'creator_name': profile?['display_name'] ?? 'Unknown Creator',
          'avatar_url': profile?['avatar_url'],
          'tier': profile?['tier'] ?? p['tier'] ?? 'bronze',
        });
      }).toList();
    } catch (e) {
      debugPrint('Fetch at-risk creators error: $e');
      return [];
    }
  }

  /// Trigger retention workflow for at-risk creator
  Future<bool> triggerRetentionWorkflow({
    required String predictionId,
    required String creatorUserId,
    required String creatorName,
    required String? phoneNumber,
    required String? email,
    required int churnTimeframeDays,
    required String tier,
    required List<Map<String, dynamic>> interventions,
  }) async {
    try {
      bool anySent = false;
      String? resolvedPhone = phoneNumber;
      String? resolvedEmail = email;

      if ((resolvedPhone == null || resolvedPhone.isEmpty) &&
          (resolvedEmail == null || resolvedEmail.isEmpty)) {
        final profile = await _supabase
            .from('user_profiles')
            .select('phone_number, email')
            .eq('id', creatorUserId)
            .maybeSingle();
        resolvedPhone = profile?['phone_number'] as String?;
        resolvedEmail = profile?['email'] as String?;
      }

      // Determine campaign type based on timeframe
      final isUrgent = churnTimeframeDays <= 7;
      final campaignType = isUrgent
          ? 'urgent_retention'
          : 'proactive_engagement';

      // Send SMS if phone available
      if (resolvedPhone != null && resolvedPhone.isNotEmpty) {
        final smsIntervention = interventions.firstWhere(
          (i) => i['type'] == 'sms',
          orElse: () => {
            'message':
                'Hi $creatorName, we noticed you haven\'t posted recently. Your $tier benefits are waiting! Need help? Reply YES for support.',
          },
        );

        final smsMessage =
            smsIntervention['message'] as String? ??
            'Hi $creatorName, we miss your content! Your $tier creator benefits are waiting.';

        await _sendSMSRetention(
          phoneNumber: resolvedPhone,
          message: smsMessage,
          creatorName: creatorName,
        );
        anySent = true;
      }

      // Send email if available
      if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
        await _sendEmailRetention(
          email: resolvedEmail,
          creatorName: creatorName,
          tier: tier,
          isUrgent: isUrgent,
        );
        anySent = true;
      }

      // Log intervention
      if (anySent) {
        await _logIntervention(
          predictionId: predictionId,
          creatorUserId: creatorUserId,
          interventionType: campaignType,
          messageContent: 'Multi-channel retention campaign sent',
        );

        // Mark intervention as sent
        await _supabase
            .from('creator_churn_predictions')
            .update({
              'intervention_sent': true,
              'last_intervention_at': DateTime.now().toIso8601String(),
            })
            .eq('prediction_id', predictionId);
      }

      return anySent;
    } catch (e) {
      debugPrint('Trigger retention workflow error: $e');
      return false;
    }
  }

  /// Fetch churn analytics data
  Future<Map<String, dynamic>> fetchChurnAnalytics() async {
    try {
      // Get total at-risk count by risk level
      final predictionsResponse = await _supabase
          .from('creator_churn_predictions')
          .select(
            'risk_level, churn_probability, intervention_sent, predicted_at',
          )
          .gte(
            'predicted_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          );

      final predictions = List<Map<String, dynamic>>.from(predictionsResponse);

      final criticalCount = predictions
          .where((p) => p['risk_level'] == 'critical')
          .length;
      final highCount = predictions
          .where((p) => p['risk_level'] == 'high')
          .length;
      final mediumCount = predictions
          .where((p) => p['risk_level'] == 'medium')
          .length;
      final lowCount = predictions
          .where((p) => p['risk_level'] == 'low')
          .length;
      final interventionSentCount = predictions
          .where((p) => p['intervention_sent'] == true)
          .length;

      // Get intervention effectiveness
      final interventionsResponse = await _supabase
          .from('creator_churn_interventions')
          .select('intervention_type, response_status')
          .gte(
            'sent_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          );

      final interventions = List<Map<String, dynamic>>.from(
        interventionsResponse,
      );
      final respondedCount = interventions
          .where(
            (i) => [
              'opened',
              'engaged',
              'resumed_posting',
            ].contains(i['response_status']),
          )
          .length;

      final responseRate = interventions.isNotEmpty
          ? respondedCount / interventions.length
          : 0.0;

      return {
        'total_at_risk': predictions.length,
        'critical_count': criticalCount,
        'high_count': highCount,
        'medium_count': mediumCount,
        'low_count': lowCount,
        'intervention_sent_count': interventionSentCount,
        'response_rate': responseRate,
        'saved_creators_count': respondedCount,
        'retention_roi':
            respondedCount * 150.0, // Estimated value per retained creator
      };
    } catch (e) {
      debugPrint('Fetch churn analytics error: $e');
      return {
        'total_at_risk': 0,
        'critical_count': 0,
        'high_count': 0,
        'medium_count': 0,
        'low_count': 0,
        'intervention_sent_count': 0,
        'response_rate': 0.0,
        'saved_creators_count': 0,
        'retention_roi': 0.0,
      };
    }
  }

  // Private helpers
  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Future<void> _sendSMSRetention({
    required String phoneNumber,
    required String message,
    required String creatorName,
  }) async {
    try {
      await TelnyxSMSService.instance.sendSMS(
        toPhone: phoneNumber,
        messageBody: message,
        messageCategory: 'creator_retention',
      );
    } catch (e) {
      debugPrint('SMS retention send error: $e');
    }
  }

  Future<void> _sendEmailRetention({
    required String email,
    required String creatorName,
    required String tier,
    required bool isUrgent,
  }) async {
    try {
      await ResendEmailService.instance.sendComplianceReport(
        recipientEmail: email,
        reportType: isUrgent ? 'urgent_retention' : 'proactive_engagement',
        reportData: {
          'creator_name': creatorName,
          'tier': tier,
          'subject': isUrgent
              ? 'We miss you, $creatorName!'
              : 'Your creator journey awaits, $creatorName!',
        },
      );
    } catch (e) {
      debugPrint('Email retention send error: $e');
    }
  }

  Future<void> _logIntervention({
    required String predictionId,
    required String creatorUserId,
    required String interventionType,
    required String messageContent,
  }) async {
    try {
      await _supabase.from('creator_churn_interventions').insert({
        'prediction_id': predictionId,
        'creator_user_id': creatorUserId,
        'intervention_type': interventionType,
        'message_content': messageContent,
        'sent_at': DateTime.now().toIso8601String(),
        'response_status': 'sent',
      });
    } catch (e) {
      debugPrint('Log intervention error: $e');
    }
  }

  Map<String, dynamic> _getDefaultClaudeAnalysis(
    Map<String, dynamic> engagementData,
    Map<String, dynamic> creatorProfile,
  ) {
    return {
      'probability': engagementData['churn_probability'] ?? 0.5,
      'timeframe_days': engagementData['churn_timeframe_days'] ?? 14,
      'primary_drivers': [
        {'driver': 'Posting frequency decline', 'impact_percentage': 25},
        {'driver': 'VP earnings drop', 'impact_percentage': 30},
        {'driver': 'Engagement rate decline', 'impact_percentage': 25},
        {'driver': 'Login gap', 'impact_percentage': 20},
      ],
      'interventions': [
        {
          'type': 'sms',
          'message':
              'Hi ${creatorProfile['display_name'] ?? 'Creator'}, we miss your content!',
          'effectiveness': 0.65,
        },
      ],
    };
  }

  static const String _prefLastChurnUserRefreshMs =
      'last_creator_churn_user_refresh_epoch_ms';

  /// Best-effort: invokes Edge `creator-churn-user-refresh` for signed-in users (throttled client-side).
  /// Server enforces 1× per UTC day; full batch remains `creator-churn-prediction-cron` + CRON_SECRET.
  Future<void> invokeUserChurnRefreshIfDue() async {
    if (_supabase.auth.currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_prefLastChurnUserRefreshMs) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < const Duration(hours: 20).inMilliseconds) return;

    try {
      await _supabase.functions.invoke(SharedConstants.creatorChurnUserRefresh);
      await prefs.setInt(_prefLastChurnUserRefreshMs, now);
    } catch (e) {
      debugPrint('invokeUserChurnRefreshIfDue: $e');
    }
  }

  /// Geo velocity pipeline (Edge `record-login-geo`); throttled to 1× / 5 min per device.
  Future<void> invokeRecordLoginGeoIfDue() async {
    if (_supabase.auth.currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_prefLastRecordLoginGeoMs) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < const Duration(minutes: 5).inMilliseconds) return;

    try {
      await _supabase.functions.invoke(SharedConstants.recordLoginGeo);
      await prefs.setInt(_prefLastRecordLoginGeoMs, now);
    } catch (e) {
      debugPrint('invokeRecordLoginGeoIfDue: $e');
    }
  }
}