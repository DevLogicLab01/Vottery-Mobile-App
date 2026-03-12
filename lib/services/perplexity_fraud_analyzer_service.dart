import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/perplexity_service.dart';
import 'dart:convert';

class PerplexityFraudAnalyzerService {
  static final PerplexityFraudAnalyzerService _instance =
      PerplexityFraudAnalyzerService._internal();
  factory PerplexityFraudAnalyzerService() => _instance;
  PerplexityFraudAnalyzerService._internal();

  final _supabase = Supabase.instance.client;
  final _perplexityService = PerplexityService.instance;

  /// Analyze logs for fraud patterns using Perplexity extended reasoning
  Future<Map<String, dynamic>> analyzeLogs({
    DateTime? startTime,
    DateTime? endTime,
    int? maxLogs,
  }) async {
    final analysisStart = DateTime.now();
    final analysisId = _generateUuid();

    try {
      print('🔍 Starting Perplexity fraud analysis: $analysisId');

      // Default time range: last 15 minutes
      final logStartTime =
          startTime ?? DateTime.now().subtract(Duration(minutes: 15));
      final logEndTime = endTime ?? DateTime.now();

      // Fetch logs from aggregated table
      final logs = await _fetchLogsForAnalysis(
        logStartTime,
        logEndTime,
        maxLogs ?? 10000,
      );

      if (logs.isEmpty) {
        print('⚠️ No logs found for analysis period');
        return {'success': false, 'message': 'No logs found for analysis'};
      }

      print('📊 Analyzing ${logs.length} log entries');

      // Build comprehensive analysis prompt
      final prompt = await _buildAnalysisPrompt(logs, logStartTime, logEndTime);

      // Call Perplexity API with extended reasoning
      final perplexityResponse = await _callPerplexityAPI(prompt);

      // Parse structured analysis from response
      final analysisResult = _parseAnalysisResponse(perplexityResponse);

      // Store analysis results
      await _storeAnalysisResults(
        analysisId,
        logStartTime,
        logEndTime,
        logs.length,
        analysisResult,
        perplexityResponse,
        analysisStart,
      );

      // Create investigations for high-confidence patterns
      await _createInvestigations(analysisId, analysisResult);

      // Store threat predictions
      await _storeThreatPredictions(analysisId, analysisResult);

      final analysisEnd = DateTime.now();
      final durationSeconds = analysisEnd.difference(analysisStart).inSeconds;

      print('✅ Fraud analysis completed in ${durationSeconds}s');
      print(
        '   - Patterns detected: ${analysisResult['detected_patterns']?.length ?? 0}',
      );
      print(
        '   - Correlations found: ${analysisResult['threat_correlations']?.length ?? 0}',
      );
      print(
        '   - Predictions made: ${analysisResult['anomaly_predictions']?.length ?? 0}',
      );

      return {
        'success': true,
        'analysis_id': analysisId,
        'logs_analyzed': logs.length,
        'patterns_detected': analysisResult['detected_patterns']?.length ?? 0,
        'correlations_found':
            analysisResult['threat_correlations']?.length ?? 0,
        'predictions_made': analysisResult['anomaly_predictions']?.length ?? 0,
        'duration_seconds': durationSeconds,
      };
    } catch (e, stackTrace) {
      print('❌ Fraud analysis failed: $e');
      print(stackTrace);

      // Store failed analysis
      await _supabase.from('fraud_analysis_results').insert({
        'analysis_id': analysisId,
        'analysis_timestamp': analysisStart.toIso8601String(),
        'log_start_time':
            (startTime ?? DateTime.now().subtract(Duration(minutes: 15)))
                .toIso8601String(),
        'log_end_time': (endTime ?? DateTime.now()).toIso8601String(),
        'analyzed_log_count': 0,
        'status': 'failed',
        'error_message': e.toString(),
      });

      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch logs for analysis from platform_logs_aggregated
  Future<List<Map<String, dynamic>>> _fetchLogsForAnalysis(
    DateTime startTime,
    DateTime endTime,
    int maxLogs,
  ) async {
    final response = await _supabase
        .from('platform_logs_aggregated')
        .select()
        .gte('timestamp', startTime.toIso8601String())
        .lte('timestamp', endTime.toIso8601String())
        .order('timestamp', ascending: false)
        .limit(maxLogs);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Build comprehensive analysis prompt for Perplexity
  Future<String> _buildAnalysisPrompt(
    List<Map<String, dynamic>> logs,
    DateTime startTime,
    DateTime endTime,
  ) async {
    // Aggregate log statistics
    final typeBreakdown = <String, int>{};
    final severityBreakdown = <String, int>{};
    final uniqueUsers = <String>{};
    final uniqueIPs = <String>{};

    for (final log in logs) {
      final eventType = log['event_type'] as String?;
      final severity = log['severity'] as String?;
      final userId = log['user_id'] as String?;
      final ipAddress = log['ip_address'] as String?;

      if (eventType != null) {
        typeBreakdown[eventType] = (typeBreakdown[eventType] ?? 0) + 1;
      }
      if (severity != null) {
        severityBreakdown[severity] = (severityBreakdown[severity] ?? 0) + 1;
      }
      if (userId != null) uniqueUsers.add(userId);
      if (ipAddress != null) uniqueIPs.add(ipAddress);
    }

    // Get recent fraud patterns
    final recentFraud = await _getRecentFraudPatterns();

    // Build activity summary
    final activitySummary = _buildActivitySummary(logs);
    final paymentSummary = _buildPaymentSummary(logs);
    final securitySummary = _buildSecuritySummary(logs);

    return '''
Analyze these platform logs for fraud and security threats using extended reasoning.

**Analysis Period**: ${startTime.toIso8601String()} to ${endTime.toIso8601String()}
**Total Events**: ${logs.length}
**Unique Users**: ${uniqueUsers.length}
**Unique IP Addresses**: ${uniqueIPs.length}

**Log Summary by Type**:
${typeBreakdown.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

**Severity Distribution**:
${severityBreakdown.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

**Recent Fraud Incidents**:
$recentFraud

**User Activity Patterns**:
$activitySummary

**Payment Anomalies**:
$paymentSummary

**Security Events**:
$securitySummary

Using extended reasoning, identify:

**1) FRAUD PATTERNS**:
- Multi-account abuse (same device/IP for multiple accounts, coordinated actions)
- Account takeover (unusual login location after password reset, rapid permission changes)
- Payment fraud (failed attempts followed by successful fraud, stolen cards, refund abuse)
- Credential stuffing (rapid login attempts across accounts with common passwords)
- Referral fraud (fake referrals for bonus exploitation, circular referral chains)
- Vote manipulation (coordinated voting patterns, bot-like behavior, timing anomalies)

**2) THREAT CORRELATIONS**:
- Link related events across users, IPs, sessions, devices
- Identify attack campaigns showing coordinated actions
- Find attack sequences showing ordered patterns (reconnaissance → exploitation → data theft)
- Build event graphs showing nodes as events and edges as relationships

**3) ANOMALY PREDICTIONS (24-48 hours)**:
- Forecast threats based on current patterns
- Identify indicators to watch (early warning signs)
- Estimate likelihood and timing of predicted attacks
- Recommend preventive actions

**Return structured analysis in JSON format**:
{
  "detected_patterns": [
    {
      "pattern_name": "string",
      "pattern_description": "string",
      "confidence_score": 0.0-1.0,
      "evidence": ["log_entry_ids"],
      "affected_users": ["user_ids"],
      "severity": "critical|high|medium|low",
      "recommended_actions": ["action1", "action2"]
    }
  ],
  "threat_correlations": [
    {
      "correlation_type": "string",
      "related_events": ["event_ids"],
      "attack_vector": "string",
      "timeline": "string"
    }
  ],
  "anomaly_predictions": [
    {
      "predicted_threat_type": "string",
      "likelihood_percentage": 0-100,
      "predicted_timeframe": "string",
      "warning_signs": ["sign1", "sign2"],
      "target_systems": ["system1", "system2"],
      "preventive_actions": ["action1", "action2"]
    }
  ]
}
''';
  }

  /// Call Perplexity API with extended reasoning
  Future<String> _callPerplexityAPI(String prompt) async {
    try {
      final response = await _perplexityService.callPerplexityAPI(
        prompt,
        model: 'sonar-pro', // Extended reasoning model
      );

      return response['choices']?[0]?['message']?['content'] as String? ?? '';
    } catch (e) {
      print('❌ Perplexity API call failed: $e');
      rethrow;
    }
  }

  /// Parse structured analysis from Perplexity response
  Map<String, dynamic> _parseAnalysisResponse(String response) {
    try {
      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }

      // Fallback: Parse markdown sections
      return _parseMarkdownResponse(response);
    } catch (e) {
      print('⚠️ Failed to parse structured response, using fallback: $e');
      return {
        'detected_patterns': [],
        'threat_correlations': [],
        'anomaly_predictions': [],
        'raw_response': response,
      };
    }
  }

  /// Parse markdown-formatted response
  Map<String, dynamic> _parseMarkdownResponse(String response) {
    return {
      'detected_patterns': _extractPatterns(response),
      'threat_correlations': _extractCorrelations(response),
      'anomaly_predictions': _extractPredictions(response),
      'raw_response': response,
    };
  }

  /// Extract patterns from markdown
  List<Map<String, dynamic>> _extractPatterns(String response) {
    final patterns = <Map<String, dynamic>>[];
    final patternSection = RegExp(
      r'FRAUD PATTERNS[\s\S]*?(?=THREAT CORRELATIONS|ANOMALY PREDICTIONS|\$)',
    ).firstMatch(response);

    if (patternSection != null) {
      final content = patternSection.group(0)!;
      // Simple extraction - in production, use more sophisticated parsing
      patterns.add({
        'pattern_name': 'Detected Pattern',
        'pattern_description': content.substring(
          0,
          content.length > 200 ? 200 : content.length,
        ),
        'confidence_score': 0.7,
        'severity': 'medium',
        'recommended_actions': ['Review logs', 'Monitor activity'],
      });
    }

    return patterns;
  }

  /// Extract correlations from markdown
  List<Map<String, dynamic>> _extractCorrelations(String response) {
    final correlations = <Map<String, dynamic>>[];
    final correlationSection = RegExp(
      r'THREAT CORRELATIONS[\s\S]*?(?=ANOMALY PREDICTIONS|\$)',
    ).firstMatch(response);

    if (correlationSection != null) {
      correlations.add({
        'correlation_type': 'temporal',
        'related_events': [],
        'attack_vector': 'Coordinated activity detected',
      });
    }

    return correlations;
  }

  /// Extract predictions from markdown
  List<Map<String, dynamic>> _extractPredictions(String response) {
    final predictions = <Map<String, dynamic>>[];
    final predictionSection = RegExp(
      r'ANOMALY PREDICTIONS[\s\S]*',
    ).firstMatch(response);

    if (predictionSection != null) {
      predictions.add({
        'predicted_threat_type': 'Potential fraud activity',
        'likelihood_percentage': 60,
        'predicted_timeframe': 'Next 24-48 hours',
        'warning_signs': ['Increased failed login attempts'],
        'preventive_actions': ['Enable additional monitoring'],
      });
    }

    return predictions;
  }

  /// Store analysis results in database
  Future<void> _storeAnalysisResults(
    String analysisId,
    DateTime logStartTime,
    DateTime logEndTime,
    int logCount,
    Map<String, dynamic> analysisResult,
    String perplexityResponse,
    DateTime analysisStart,
  ) async {
    final durationSeconds = DateTime.now().difference(analysisStart).inSeconds;
    final confidenceScore = _calculateOverallConfidence(analysisResult);

    await _supabase.from('fraud_analysis_results').insert({
      'analysis_id': analysisId,
      'analysis_timestamp': analysisStart.toIso8601String(),
      'log_start_time': logStartTime.toIso8601String(),
      'log_end_time': logEndTime.toIso8601String(),
      'analyzed_log_count': logCount,
      'detected_patterns': analysisResult['detected_patterns'] ?? [],
      'threat_correlations': analysisResult['threat_correlations'] ?? [],
      'anomaly_predictions': analysisResult['anomaly_predictions'] ?? [],
      'confidence_score': confidenceScore,
      'perplexity_response': perplexityResponse,
      'perplexity_model': 'sonar-pro',
      'processing_time_seconds': durationSeconds,
      'status': 'completed',
    });
  }

  /// Create investigations for high-confidence patterns
  Future<void> _createInvestigations(
    String analysisId,
    Map<String, dynamic> analysisResult,
  ) async {
    final patterns = analysisResult['detected_patterns'] as List? ?? [];

    for (final pattern in patterns) {
      final confidence = pattern['confidence_score'] as num? ?? 0;
      final severity = pattern['severity'] as String? ?? 'medium';

      // Create investigation for high-confidence or critical patterns
      if (confidence >= 0.7 || severity == 'critical') {
        await _supabase.from('fraud_investigations').insert({
          'analysis_id': analysisId,
          'pattern_name': pattern['pattern_name'],
          'title': 'Fraud Pattern: ${pattern['pattern_name']}',
          'description': pattern['pattern_description'],
          'status': 'pending_review',
          'priority': severity == 'critical' ? 'critical' : 'high',
          'affected_users': pattern['affected_users'] ?? [],
        });
      }
    }
  }

  /// Store threat predictions
  Future<void> _storeThreatPredictions(
    String analysisId,
    Map<String, dynamic> analysisResult,
  ) async {
    final predictions = analysisResult['anomaly_predictions'] as List? ?? [];

    for (final prediction in predictions) {
      await _supabase.from('threat_predictions').insert({
        'analysis_id': analysisId,
        'predicted_threat': prediction['predicted_threat_type'],
        'threat_category': _mapThreatCategory(
          prediction['predicted_threat_type'],
        ),
        'likelihood_percentage': prediction['likelihood_percentage'],
        'predicted_timeframe': prediction['predicted_timeframe'],
        'warning_signs': prediction['warning_signs'] ?? [],
        'target_systems': prediction['target_systems'] ?? [],
        'preventive_actions': prediction['preventive_actions'] ?? [],
        'confidence_level': _mapConfidenceLevel(
          prediction['likelihood_percentage'],
        ),
        'status': 'active',
      });
    }
  }

  /// Helper methods
  Future<String> _getRecentFraudPatterns() async {
    try {
      final response = await _supabase
          .from('fraud_detection_log')
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      if (response.isEmpty) return 'No recent fraud incidents';

      return (response as List)
          .map(
            (f) =>
                '- ${f['detection_type']}: ${f['details']?['description'] ?? ""}',
          )
          .join('\n');
    } catch (e) {
      return 'Unable to fetch recent fraud patterns';
    }
  }

  String _buildActivitySummary(List<Map<String, dynamic>> logs) {
    final userActions = logs
        .where((l) => l['event_type'] == 'user_action')
        .length;
    return 'Total user actions: $userActions';
  }

  String _buildPaymentSummary(List<Map<String, dynamic>> logs) {
    final payments = logs.where(
      (l) => l['event_type'] == 'payment_transaction',
    );
    final failed = payments
        .where((l) => l['action']?.toString().contains('failed') ?? false)
        .length;
    return 'Total payments: ${payments.length}, Failed: $failed';
  }

  String _buildSecuritySummary(List<Map<String, dynamic>> logs) {
    final security = logs
        .where((l) => l['event_type'] == 'security_event')
        .length;
    return 'Security events: $security';
  }

  double _calculateOverallConfidence(Map<String, dynamic> result) {
    final patterns = result['detected_patterns'] as List? ?? [];
    if (patterns.isEmpty) return 0.0;

    final scores = patterns
        .map((p) => p['confidence_score'] as num? ?? 0)
        .toList();

    return scores.reduce((a, b) => a + b) / scores.length;
  }

  String _mapThreatCategory(String? threatType) {
    if (threatType == null) return 'other';

    final lower = threatType.toLowerCase();
    if (lower.contains('auth') || lower.contains('login')) {
      return 'authentication';
    }
    if (lower.contains('payment')) return 'payments';
    if (lower.contains('data')) return 'user_data';
    if (lower.contains('election') || lower.contains('vote')) {
      return 'elections';
    }
    if (lower.contains('content')) return 'content';

    return 'other';
  }

  String _mapConfidenceLevel(int? likelihood) {
    if (likelihood == null) return 'low';
    if (likelihood >= 80) return 'very_high';
    if (likelihood >= 60) return 'high';
    if (likelihood >= 40) return 'medium';
    return 'low';
  }

  String _generateUuid() {
    return '${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond % 1000}';
  }
}
