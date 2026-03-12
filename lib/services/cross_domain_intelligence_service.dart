import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './fraud_detection_service.dart';
import './perplexity_service.dart';
import './claude_service.dart';
import './openai_fraud_service.dart';
import './gemini_service.dart';
import './multi_ai_orchestration_service.dart';

class CrossDomainIntelligenceService {
  static CrossDomainIntelligenceService? _instance;
  static CrossDomainIntelligenceService get instance =>
      _instance ??= CrossDomainIntelligenceService._();

  CrossDomainIntelligenceService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  FraudDetectionService get _fraudService => FraudDetectionService.instance;
  PerplexityService get _perplexity => PerplexityService.instance;
  ClaudeService get _claude => ClaudeService.instance;
  OpenAIFraudService get _openai => OpenAIFraudService.instance;
  GeminiService get _gemini => GeminiService.instance;
  MultiAIOrchestrationService get _orchestrator =>
      MultiAIOrchestrationService.instance;

  /// Get cross-domain intelligence summary
  Future<Map<String, dynamic>> getCrossDomainIntelligence({
    int timeWindowHours = 24,
  }) async {
    try {
      final response = await _client.rpc(
        'get_cross_domain_intelligence_summary',
        params: {'time_window_hours': timeWindowHours},
      );

      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      debugPrint('Get cross-domain intelligence error: $e');
      return {};
    }
  }

  /// Correlate fraud patterns across AI services
  Future<Map<String, dynamic>> correlateFraudPatterns() async {
    try {
      // Get fraud data from multiple sources
      final fraudAlerts = await _fraudService.getFraudAlerts(unresolved: true);
      final perplexityForecasts = await _perplexity.forecastFraudTrends(
        historicalData: [],
      );

      // Analyze patterns
      final patterns = <String, dynamic>{};

      // Perplexity threat forecasts
      patterns['perplexity_threats'] =
          perplexityForecasts['predicted_threats'] ?? [];

      // Claude dispute analysis
      final claudeDisputes = await _analyzeDisputesWithClaude(fraudAlerts);
      patterns['claude_disputes'] = claudeDisputes;

      // OpenAI semantic anomalies
      final openaiAnomalies = await _detectSemanticAnomalies(fraudAlerts);
      patterns['openai_anomalies'] = openaiAnomalies;

      // Calculate consensus
      final consensus = _calculateMultiAIConsensus(patterns);
      patterns['consensus_score'] = consensus;

      // Store correlation
      await _storeMetricCorrelation(
        metricA: 'fraud_patterns',
        metricB: 'multi_ai_consensus',
        correlation: consensus,
      );

      return patterns;
    } catch (e) {
      debugPrint('Correlate fraud patterns error: $e');
      return {};
    }
  }

  /// Analyze engagement trends across platforms
  Future<Map<String, dynamic>> analyzeEngagementTrends() async {
    try {
      final results = await Future.wait([
        _getVotePatterns(),
        _getCommentSentiment(),
        _getReactionDistributions(),
      ]);

      final votePatterns = results[0];
      final commentSentiment = results[1];
      final reactionDistributions = results[2];

      // Calculate correlations
      final voteCommentCorrelation = _calculateCorrelation(
        votePatterns['daily_votes'] ?? [],
        commentSentiment['daily_comments'] ?? [],
      );

      await _storeMetricCorrelation(
        metricA: 'vote_patterns',
        metricB: 'comment_sentiment',
        correlation: voteCommentCorrelation,
      );

      return {
        'vote_patterns': votePatterns,
        'comment_sentiment': commentSentiment,
        'reaction_distributions': reactionDistributions,
        'vote_comment_correlation': voteCommentCorrelation,
      };
    } catch (e) {
      debugPrint('Analyze engagement trends error: $e');
      return {};
    }
  }

  /// Analyze monetization metrics with cohort segmentation
  Future<Map<String, dynamic>> analyzeMonetizationMetrics() async {
    try {
      final results = await Future.wait([
        _getSubscriptionRevenue(),
        _getParticipationFees(),
        _getAdRevenue(),
      ]);

      final subscriptionRevenue = results[0];
      final participationFees = results[1];
      final adRevenue = results[2];

      // Cohort segmentation
      final cohorts = await _segmentUserCohorts();

      // Calculate total revenue
      final totalRevenue =
          (subscriptionRevenue['total'] ?? 0.0) +
          (participationFees['total'] ?? 0.0) +
          (adRevenue['total'] ?? 0.0);

      return {
        'subscription_revenue': subscriptionRevenue,
        'participation_fees': participationFees,
        'ad_revenue': adRevenue,
        'total_revenue': totalRevenue,
        'cohorts': cohorts,
      };
    } catch (e) {
      debugPrint('Analyze monetization metrics error: $e');
      return {};
    }
  }

  /// Generate predictive alerts
  Future<List<Map<String, dynamic>>> generatePredictiveAlerts() async {
    try {
      // Analyze time-series data for anomalies
      final fraudTrend = await _detectFraudSpike();
      final engagementTrend = await _detectEngagementDrop();
      final revenueTrend = await _detectRevenueAnomaly();

      final alerts = <Map<String, dynamic>>[];

      // Fraud spike prediction
      if (fraudTrend['predicted_spike'] == true) {
        alerts.add(
          await _createPredictiveAlert(
            alertType: 'fraud_spike',
            severity: 'critical',
            predictedEvent: 'Fraud spike predicted in 48 hours',
            confidenceInterval: fraudTrend['confidence'] ?? 0.0,
            predictionWindowHours: 48,
            alertData: fraudTrend,
          ),
        );
      }

      // Engagement drop prediction
      if (engagementTrend['predicted_drop'] == true) {
        alerts.add(
          await _createPredictiveAlert(
            alertType: 'engagement_drop',
            severity: 'high',
            predictedEvent: 'Engagement drop predicted in 24 hours',
            confidenceInterval: engagementTrend['confidence'] ?? 0.0,
            predictionWindowHours: 24,
            alertData: engagementTrend,
          ),
        );
      }

      // Revenue anomaly detection
      if (revenueTrend['anomaly_detected'] == true) {
        alerts.add(
          await _createPredictiveAlert(
            alertType: 'revenue_anomaly',
            severity: 'high',
            predictedEvent: 'Revenue anomaly detected',
            confidenceInterval: revenueTrend['confidence'] ?? 0.0,
            predictionWindowHours: 0,
            alertData: revenueTrend,
          ),
        );
      }

      return alerts;
    } catch (e) {
      debugPrint('Generate predictive alerts error: $e');
      return [];
    }
  }

  /// Get multi-AI consensus results
  Future<List<Map<String, dynamic>>> getMultiAIConsensusResults({
    String? analysisType,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('multi_ai_consensus_results').select();

      if (analysisType != null) {
        query = query.eq('analysis_type', analysisType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get multi-AI consensus results error: $e');
      return [];
    }
  }

  /// Get metric correlations
  Future<List<Map<String, dynamic>>> getMetricCorrelations() async {
    try {
      final response = await _client
          .from('metric_correlations')
          .select()
          .order('correlation_coefficient', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get metric correlations error: $e');
      return [];
    }
  }

  /// Get predictive alerts
  Future<List<Map<String, dynamic>>> getPredictiveAlerts({
    String? alertType,
    String? severity,
    bool unresolvedOnly = true,
  }) async {
    try {
      var query = _client.from('predictive_alerts').select();

      if (alertType != null) {
        query = query.eq('alert_type', alertType);
      }

      if (severity != null) {
        query = query.eq('alert_severity', severity);
      }

      if (unresolvedOnly) {
        query = query.isFilter('resolved_at', null);
      }

      final response = await query
          .order('triggered_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get predictive alerts error: $e');
      return [];
    }
  }

  /// Acknowledge predictive alert
  Future<bool> acknowledgePredictiveAlert(String alertId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('predictive_alerts')
          .update({
            'acknowledged_at': DateTime.now().toIso8601String(),
            'acknowledged_by': _auth.currentUser!.id,
          })
          .eq('id', alertId);

      return true;
    } catch (e) {
      debugPrint('Acknowledge predictive alert error: $e');
      return false;
    }
  }

  /// Resolve predictive alert
  Future<bool> resolvePredictiveAlert({
    required String alertId,
    required String resolutionNotes,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('predictive_alerts')
          .update({
            'resolved_at': DateTime.now().toIso8601String(),
            'resolution_notes': resolutionNotes,
          })
          .eq('id', alertId);

      return true;
    } catch (e) {
      debugPrint('Resolve predictive alert error: $e');
      return false;
    }
  }

  /// Store intelligence metric
  Future<void> storeIntelligenceMetric({
    required String metricType,
    required String metricName,
    required double metricValue,
    required String aiService,
    Map<String, dynamic>? correlationData,
  }) async {
    try {
      await _client.from('cross_domain_intelligence_metrics').insert({
        'metric_type': metricType,
        'metric_name': metricName,
        'metric_value': metricValue,
        'ai_service': aiService,
        'correlation_data': correlationData,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Store intelligence metric error: $e');
    }
  }

  // Private helper methods

  Future<Map<String, dynamic>> _analyzeDisputesWithClaude(
    List<Map<String, dynamic>> fraudAlerts,
  ) async {
    try {
      final disputes = fraudAlerts
          .where((alert) => alert['severity'] == 'high')
          .toList();

      if (disputes.isEmpty) return {'count': 0, 'patterns': []};

      final analysis = await _claude.analyzeSecurityIncident(
        incidentData: {'incident_type': 'fraud_disputes', 'disputes': disputes},
      );

      return {
        'count': disputes.length,
        'patterns': analysis['patterns'] ?? [],
        'confidence': analysis['confidence_score'] ?? 0.0,
      };
    } catch (e) {
      debugPrint('Analyze disputes with Claude error: $e');
      return {'count': 0, 'patterns': []};
    }
  }

  Future<Map<String, dynamic>> _detectSemanticAnomalies(
    List<Map<String, dynamic>> fraudAlerts,
  ) async {
    try {
      final anomalies = <Map<String, dynamic>>[];

      for (var alert in fraudAlerts.take(10)) {
        final analysis = await _openai.analyzeFraudRisk(
          voteId: alert['vote_id'] ?? 'unknown',
          voteData: alert,
        );

        if ((analysis['fraud_score'] ?? 0.0) > 80) {
          anomalies.add({
            'vote_id': alert['vote_id'],
            'fraud_score': analysis['fraud_score'],
            'reasoning': analysis['reasoning'],
          });
        }
      }

      return {'count': anomalies.length, 'anomalies': anomalies};
    } catch (e) {
      debugPrint('Detect semantic anomalies error: $e');
      return {'count': 0, 'anomalies': []};
    }
  }

  double _calculateMultiAIConsensus(Map<String, dynamic> patterns) {
    try {
      final perplexityThreats =
          (patterns['perplexity_threats'] as List?)?.length ?? 0;
      final claudeDisputes =
          (patterns['claude_disputes']?['count'] as int?) ?? 0;
      final openaiAnomalies =
          (patterns['openai_anomalies']?['count'] as int?) ?? 0;

      final totalSignals = perplexityThreats + claudeDisputes + openaiAnomalies;
      final agreementCount = [
        perplexityThreats > 0,
        claudeDisputes > 0,
        openaiAnomalies > 0,
      ].where((signal) => signal).length;

      return agreementCount / 3.0;
    } catch (e) {
      debugPrint('Calculate multi-AI consensus error: $e');
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> _getVotePatterns() async {
    try {
      final response = await _client
          .from('votes')
          .select('created_at')
          .gte(
            'created_at',
            DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          );

      final votes = List<Map<String, dynamic>>.from(response);
      final dailyVotes = <int>[];

      for (var i = 0; i < 30; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final count = votes.where((v) {
          final voteDate = DateTime.parse(v['created_at']);
          return voteDate.year == date.year &&
              voteDate.month == date.month &&
              voteDate.day == date.day;
        }).length;
        dailyVotes.add(count);
      }

      return {'daily_votes': dailyVotes};
    } catch (e) {
      debugPrint('Get vote patterns error: $e');
      return {'daily_votes': []};
    }
  }

  Future<Map<String, dynamic>> _getCommentSentiment() async {
    try {
      final response = await _client
          .from('election_comments')
          .select('created_at')
          .gte(
            'created_at',
            DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          );

      final comments = List<Map<String, dynamic>>.from(response);
      final dailyComments = <int>[];

      for (var i = 0; i < 30; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final count = comments.where((c) {
          final commentDate = DateTime.parse(c['created_at']);
          return commentDate.year == date.year &&
              commentDate.month == date.month &&
              commentDate.day == date.day;
        }).length;
        dailyComments.add(count);
      }

      return {'daily_comments': dailyComments};
    } catch (e) {
      debugPrint('Get comment sentiment error: $e');
      return {'daily_comments': []};
    }
  }

  Future<Map<String, dynamic>> _getReactionDistributions() async {
    try {
      final response = await _client
          .from('election_reactions')
          .select('reaction_type')
          .gte(
            'created_at',
            DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          );

      final reactions = List<Map<String, dynamic>>.from(response);
      final distribution = <String, int>{};

      for (var reaction in reactions) {
        final type = reaction['reaction_type'] as String? ?? 'unknown';
        distribution[type] = (distribution[type] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      debugPrint('Get reaction distributions error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getSubscriptionRevenue() async {
    try {
      final response = await _client
          .from('subscription_transactions')
          .select('amount')
          .gte(
            'created_at',
            DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          );

      final transactions = List<Map<String, dynamic>>.from(response);
      final total = transactions.fold<double>(
        0.0,
        (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0),
      );

      return {'total': total, 'count': transactions.length};
    } catch (e) {
      debugPrint('Get subscription revenue error: $e');
      return {'total': 0.0, 'count': 0};
    }
  }

  Future<Map<String, dynamic>> _getParticipationFees() async {
    try {
      final response = await _client
          .from('participation_fee_transactions')
          .select('amount_usd')
          .gte(
            'created_at',
            DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          );

      final transactions = List<Map<String, dynamic>>.from(response);
      final total = transactions.fold<double>(
        0.0,
        (sum, t) => sum + ((t['amount_usd'] as num?)?.toDouble() ?? 0.0),
      );

      return {'total': total, 'count': transactions.length};
    } catch (e) {
      debugPrint('Get participation fees error: $e');
      return {'total': 0.0, 'count': 0};
    }
  }

  Future<Map<String, dynamic>> _getAdRevenue() async {
    try {
      // Mock ad revenue data
      return {'total': 0.0, 'count': 0};
    } catch (e) {
      debugPrint('Get ad revenue error: $e');
      return {'total': 0.0, 'count': 0};
    }
  }

  Future<Map<String, dynamic>> _segmentUserCohorts() async {
    try {
      final users = await _client
          .from('user_profiles')
          .select('id, subscription_tier, created_at');

      final cohorts = {
        'premium': 0,
        'free': 0,
        'new_users': 0,
        'active_users': 0,
      };

      for (var user in users) {
        if (user['subscription_tier'] == 'premium') {
          cohorts['premium'] = (cohorts['premium'] ?? 0) + 1;
        } else {
          cohorts['free'] = (cohorts['free'] ?? 0) + 1;
        }

        final accountAge = DateTime.now()
            .difference(DateTime.parse(user['created_at']))
            .inDays;
        if (accountAge <= 30) {
          cohorts['new_users'] = (cohorts['new_users'] ?? 0) + 1;
        }
      }

      return cohorts;
    } catch (e) {
      debugPrint('Segment user cohorts error: $e');
      return {};
    }
  }

  double _calculateCorrelation(List<int> seriesA, List<int> seriesB) {
    try {
      if (seriesA.isEmpty ||
          seriesB.isEmpty ||
          seriesA.length != seriesB.length) {
        return 0.0;
      }

      final n = seriesA.length;
      final meanA = seriesA.reduce((a, b) => a + b) / n;
      final meanB = seriesB.reduce((a, b) => a + b) / n;

      double numerator = 0.0;
      double denomA = 0.0;
      double denomB = 0.0;

      for (var i = 0; i < n; i++) {
        final diffA = seriesA[i] - meanA;
        final diffB = seriesB[i] - meanB;
        numerator += diffA * diffB;
        denomA += diffA * diffA;
        denomB += diffB * diffB;
      }

      if (denomA == 0 || denomB == 0) return 0.0;

      return numerator / (denomA * denomB).abs();
    } catch (e) {
      debugPrint('Calculate correlation error: $e');
      return 0.0;
    }
  }

  Future<void> _storeMetricCorrelation({
    required String metricA,
    required String metricB,
    required double correlation,
  }) async {
    try {
      await _client.from('metric_correlations').upsert({
        'metric_a': metricA,
        'metric_b': metricB,
        'correlation_coefficient': correlation,
        'sample_size': 30,
        'calculated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Store metric correlation error: $e');
    }
  }

  Future<Map<String, dynamic>> _detectFraudSpike() async {
    try {
      final fraudAlerts = await _fraudService.getFraudHistory(limit: 100);

      // Simple trend analysis
      final recentAlerts = fraudAlerts.where((alert) {
        final createdAt = DateTime.parse(alert['created_at']);
        return DateTime.now().difference(createdAt).inHours <= 24;
      }).length;

      final previousAlerts = fraudAlerts.where((alert) {
        final createdAt = DateTime.parse(alert['created_at']);
        final diff = DateTime.now().difference(createdAt).inHours;
        return diff > 24 && diff <= 48;
      }).length;

      final predictedSpike = recentAlerts > previousAlerts * 1.5;

      return {
        'predicted_spike': predictedSpike,
        'confidence': predictedSpike ? 0.75 : 0.25,
        'recent_count': recentAlerts,
        'previous_count': previousAlerts,
      };
    } catch (e) {
      debugPrint('Detect fraud spike error: $e');
      return {'predicted_spike': false, 'confidence': 0.0};
    }
  }

  Future<Map<String, dynamic>> _detectEngagementDrop() async {
    try {
      final votePatterns = await _getVotePatterns();
      final dailyVotes = votePatterns['daily_votes'] as List<int>? ?? [];

      if (dailyVotes.length < 7) {
        return {'predicted_drop': false, 'confidence': 0.0};
      }

      final recentAvg = dailyVotes.take(3).reduce((a, b) => a + b) / 3;
      final previousAvg =
          dailyVotes.skip(3).take(4).reduce((a, b) => a + b) / 4;

      final predictedDrop = recentAvg < previousAvg * 0.7;

      return {
        'predicted_drop': predictedDrop,
        'confidence': predictedDrop ? 0.70 : 0.30,
        'recent_avg': recentAvg,
        'previous_avg': previousAvg,
      };
    } catch (e) {
      debugPrint('Detect engagement drop error: $e');
      return {'predicted_drop': false, 'confidence': 0.0};
    }
  }

  Future<Map<String, dynamic>> _detectRevenueAnomaly() async {
    try {
      final monetization = await analyzeMonetizationMetrics();
      final totalRevenue = monetization['total_revenue'] as double? ?? 0.0;

      // Z-score anomaly detection (simplified)
      final anomalyDetected = totalRevenue < 1000; // Placeholder threshold

      return {
        'anomaly_detected': anomalyDetected,
        'confidence': anomalyDetected ? 0.65 : 0.35,
        'total_revenue': totalRevenue,
      };
    } catch (e) {
      debugPrint('Detect revenue anomaly error: $e');
      return {'anomaly_detected': false, 'confidence': 0.0};
    }
  }

  Future<Map<String, dynamic>> _createPredictiveAlert({
    required String alertType,
    required String severity,
    required String predictedEvent,
    required double confidenceInterval,
    required int predictionWindowHours,
    required Map<String, dynamic> alertData,
  }) async {
    try {
      // Get multi-AI consensus
      final consensusScore = await _getAIConsensusForAlert(
        alertType,
        alertData,
      );

      final alert = {
        'alert_type': alertType,
        'alert_severity': severity,
        'predicted_event': predictedEvent,
        'confidence_interval': confidenceInterval,
        'prediction_window_hours': predictionWindowHours,
        'ai_consensus_score': consensusScore['score'],
        'contributing_services': consensusScore['services'],
        'alert_data': alertData,
      };

      final response = await _client
          .from('predictive_alerts')
          .insert(alert)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Create predictive alert error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getAIConsensusForAlert(
    String alertType,
    Map<String, dynamic> alertData,
  ) async {
    try {
      final services = <String>[];
      var totalScore = 0.0;
      var count = 0;

      // Check each AI service
      if (alertData['perplexity_confidence'] != null) {
        services.add('perplexity');
        totalScore += (alertData['perplexity_confidence'] as num).toDouble();
        count++;
      }

      if (alertData['claude_confidence'] != null) {
        services.add('claude');
        totalScore += (alertData['claude_confidence'] as num).toDouble();
        count++;
      }

      if (alertData['openai_confidence'] != null) {
        services.add('openai');
        totalScore += (alertData['openai_confidence'] as num).toDouble();
        count++;
      }

      final consensusScore = count > 0 ? totalScore / count : 0.0;

      return {'score': consensusScore, 'services': services};
    } catch (e) {
      debugPrint('Get AI consensus for alert error: $e');
      return {'score': 0.0, 'services': []};
    }
  }
}
