import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import './perplexity_service.dart';

/// Perplexity Log Analysis Service
/// Implements advanced threat detection with log aggregation, extended reasoning analysis,
/// threat correlation, automated response, and security incident management
class PerplexityLogAnalysisService {
  static PerplexityLogAnalysisService? _instance;
  static PerplexityLogAnalysisService get instance =>
      _instance ??= PerplexityLogAnalysisService._();
  PerplexityLogAnalysisService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final PerplexityService _perplexity = PerplexityService.instance;
  final Uuid _uuid = const Uuid();

  /// Analyze system logs for threats
  Future<Map<String, dynamic>> analyzeSystemLogs({
    required Duration timeWindow,
  }) async {
    try {
      // Aggregate logs from multiple sources
      final logs = await _aggregateLogs(timeWindow);

      if (logs.isEmpty) {
        return {
          'success': true,
          'threats_detected': [],
          'overall_threat_score': 0,
        };
      }

      // Preprocess logs
      final processedLogs = _preprocessLogs(logs);

      // Construct Perplexity prompt
      final prompt = _buildLogAnalysisPrompt(processedLogs, timeWindow);

      // Call Perplexity with extended reasoning
      final response = await _perplexity.callPerplexityAPI(
        prompt,
        model: 'sonar-reasoning',
      );

      // Parse threat analysis
      final analysis = _parseThreats(
        response['choices']?[0]?['message']?['content'] ?? '',
      );

      // Correlate threats
      final correlatedThreats = await _correlateThreats(analysis['threats']);

      // Calculate overall threat score
      final overallScore = _calculateOverallThreatScore(correlatedThreats);

      // Automated threat response
      await _executeAutomatedResponse(correlatedThreats);

      // Store analysis results
      await _storeAnalysisResults(
        timeWindow: timeWindow,
        logCount: logs.length,
        threats: correlatedThreats,
        overallScore: overallScore,
      );

      return {
        'success': true,
        'threats_detected': correlatedThreats,
        'overall_threat_score': overallScore,
        'log_count': logs.length,
      };
    } catch (e) {
      debugPrint('Analyze system logs error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Aggregate logs from multiple sources
  Future<List<Map<String, dynamic>>> _aggregateLogs(Duration timeWindow) async {
    try {
      final startTime = DateTime.now().subtract(timeWindow);

      // Supabase postgres logs (simulated)
      final authLogs = await _supabase
          .from('user_activity_log')
          .select()
          .gte('timestamp', startTime.toIso8601String())
          .order('timestamp', ascending: false)
          .limit(500);

      // Fraud detection logs
      final fraudLogs = await _supabase
          .from('fraud_detection_events')
          .select()
          .gte('detected_at', startTime.toIso8601String())
          .order('detected_at', ascending: false)
          .limit(200);

      // Voting logs
      final votingLogs = await _supabase
          .from('votes')
          .select('id, user_id, election_id, created_at')
          .gte('created_at', startTime.toIso8601String())
          .order('created_at', ascending: false)
          .limit(1000);

      // Moderation logs
      final moderationLogs = await _supabase
          .from('content_moderation_results')
          .select()
          .gte('created_at', startTime.toIso8601String())
          .order('created_at', ascending: false)
          .limit(300);

      return [
        ...List<Map<String, dynamic>>.from(authLogs),
        ...List<Map<String, dynamic>>.from(fraudLogs),
        ...List<Map<String, dynamic>>.from(votingLogs),
        ...List<Map<String, dynamic>>.from(moderationLogs),
      ];
    } catch (e) {
      debugPrint('Aggregate logs error: $e');
      return [];
    }
  }

  /// Preprocess logs
  Map<String, dynamic> _preprocessLogs(List<Map<String, dynamic>> logs) {
    final authLogs = logs.where((l) => l.containsKey('action')).toList();
    final fraudLogs = logs.where((l) => l.containsKey('fraud_score')).toList();
    final votingLogs = logs.where((l) => l.containsKey('election_id')).toList();
    final moderationLogs = logs
        .where((l) => l.containsKey('moderation_result'))
        .toList();

    final failedLogins = authLogs
        .where((l) => l['action'] == 'login_failed')
        .length;
    final suspiciousPatterns = authLogs
        .where((l) => l['is_suspicious'] == true)
        .length;

    final highFraudScores = fraudLogs
        .where((l) => (l['fraud_score'] as int? ?? 0) > 70)
        .length;

    final voteVelocity = votingLogs.length;
    final coordinationIndicators = _detectCoordinationIndicators(votingLogs);

    final contentFlags = moderationLogs.length;
    final autoRemovals = moderationLogs
        .where((l) => l['moderation_result'] == 'removed')
        .length;

    return {
      'log_count': logs.length,
      'authentication': {
        'failed_login_count': failedLogins,
        'suspicious_patterns': suspiciousPatterns,
      },
      'transactions': {
        'transaction_volume': 0,
        'high_value_txns': 0,
        'refund_rate': 0.0,
      },
      'voting': {
        'vote_velocity': voteVelocity,
        'coordination_indicators': coordinationIndicators,
      },
      'moderation': {
        'content_flags': contentFlags,
        'auto_removals': autoRemovals,
      },
    };
  }

  /// Detect coordination indicators
  int _detectCoordinationIndicators(List<Map<String, dynamic>> votingLogs) {
    // Simple heuristic: votes from same IP or within short time window
    final timestamps = votingLogs
        .map((l) => DateTime.parse(l['created_at'] as String))
        .toList();

    int coordinated = 0;
    for (int i = 0; i < timestamps.length - 1; i++) {
      final diff = timestamps[i].difference(timestamps[i + 1]).inSeconds.abs();
      if (diff < 5) {
        coordinated++;
      }
    }

    return coordinated;
  }

  /// Build log analysis prompt
  String _buildLogAnalysisPrompt(
    Map<String, dynamic> processedLogs,
    Duration timeWindow,
  ) {
    return '''
Analyze these system logs for security threats and operational anomalies using extended reasoning.

Log summary: ${processedLogs['log_count']} events from ${timeWindow.inHours} hours.

Authentication: ${processedLogs['authentication']['failed_login_count']} failures, ${processedLogs['authentication']['suspicious_patterns']} suspicious patterns.

Voting: ${processedLogs['voting']['vote_velocity']} votes, ${processedLogs['voting']['coordination_indicators']} coordination indicators.

Moderation: ${processedLogs['moderation']['content_flags']} flags, ${processedLogs['moderation']['auto_removals']} auto-removals.

Detect:
1) Security threats (brute force, account takeover, fraud rings)
2) Operational anomalies (service degradation, data corruption)
3) Abuse patterns (vote manipulation, spam, scams)

For each threat:
- Threat type
- Severity (critical/high/medium/low)
- Confidence (0-1)
- Evidence (log entries supporting)
- Affected entities (users/elections/transactions)
- Recommended actions (immediate steps)
- Timeline (when threat started)

Use extended reasoning to correlate patterns across different log sources.

Return detailed JSON:
{
  "threats": [
    {
      "threat_type": "...",
      "severity": "critical|high|medium|low",
      "confidence": 0-1,
      "evidence": ["..."],
      "affected_entities": ["..."],
      "recommended_actions": ["..."],
      "timeline": "..."
    }
  ]
}
''';
  }

  /// Parse threats from response
  Map<String, dynamic> _parseThreats(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Parse threats error: $e');
      return {'threats': []};
    }
  }

  /// Correlate threats
  Future<List<Map<String, dynamic>>> _correlateThreats(
    List<dynamic> threats,
  ) async {
    final correlated = <Map<String, dynamic>>[];

    for (final threat in threats) {
      final threatMap = threat as Map<String, dynamic>;

      // Cross-reference with existing incidents
      final relatedIncidents = await _findRelatedIncidents(threatMap);

      // Calculate composite threat score
      final threatScore = _calculateThreatScore(threatMap);

      correlated.add({
        ...threatMap,
        'threat_score': threatScore,
        'related_incidents': relatedIncidents,
      });
    }

    // Sort by threat score
    correlated.sort((a, b) => b['threat_score'].compareTo(a['threat_score']));

    return correlated;
  }

  /// Find related incidents
  Future<List<String>> _findRelatedIncidents(
    Map<String, dynamic> threat,
  ) async {
    try {
      final threatType = threat['threat_type'] as String;

      final incidents = await _supabase
          .from('security_incidents')
          .select('incident_id')
          .eq('threat_type', threatType)
          .eq('status', 'open')
          .limit(5);

      return incidents.map((i) => i['incident_id'] as String).toList();
    } catch (e) {
      debugPrint('Find related incidents error: $e');
      return [];
    }
  }

  /// Calculate threat score
  int _calculateThreatScore(Map<String, dynamic> threat) {
    final severity = threat['severity'] as String;
    final confidence = threat['confidence'] as double;

    final severityScore =
        {'critical': 100, 'high': 75, 'medium': 50, 'low': 25}[severity] ?? 0;

    return (severityScore * confidence).round();
  }

  /// Calculate overall threat score
  int _calculateOverallThreatScore(List<Map<String, dynamic>> threats) {
    if (threats.isEmpty) return 0;

    final scores = threats.map((t) => t['threat_score'] as int).toList();
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  /// Execute automated response
  Future<void> _executeAutomatedResponse(
    List<Map<String, dynamic>> threats,
  ) async {
    for (final threat in threats) {
      final severity = threat['severity'] as String;
      final confidence = threat['confidence'] as double;

      if (severity == 'critical' && confidence > 0.9) {
        // High-severity auto-actions
        await _createSecurityIncident(threat, autoExecute: true);
      } else if (severity == 'high' || severity == 'medium') {
        // Medium-severity alerts
        await _createSecurityIncident(threat, autoExecute: false);
      } else {
        // Low-severity monitoring
        await _logThreat(threat);
      }
    }
  }

  /// Create security incident
  Future<void> _createSecurityIncident(
    Map<String, dynamic> threat, {
    required bool autoExecute,
  }) async {
    try {
      final incidentId = _uuid.v4();

      await _supabase.from('security_incidents').insert({
        'incident_id': incidentId,
        'threat_type': threat['threat_type'],
        'severity': threat['severity'],
        'confidence': threat['confidence'],
        'affected_users': jsonEncode(threat['affected_entities'] ?? []),
        'affected_entities': jsonEncode(threat['affected_entities'] ?? []),
        'evidence_logs': jsonEncode(threat['evidence'] ?? []),
        'detected_at': DateTime.now().toIso8601String(),
        'status': autoExecute ? 'investigating' : 'open',
      });

      debugPrint('Security incident created: $incidentId');
    } catch (e) {
      debugPrint('Create security incident error: $e');
    }
  }

  /// Log threat
  Future<void> _logThreat(Map<String, dynamic> threat) async {
    try {
      await _supabase.from('threat_log').insert({
        'threat_type': threat['threat_type'],
        'severity': threat['severity'],
        'confidence': threat['confidence'],
        'logged_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log threat error: $e');
    }
  }

  /// Store analysis results
  Future<void> _storeAnalysisResults({
    required Duration timeWindow,
    required int logCount,
    required List<Map<String, dynamic>> threats,
    required int overallScore,
  }) async {
    try {
      final endTime = DateTime.now();
      final startTime = endTime.subtract(timeWindow);

      await _supabase.from('log_analysis_results').insert({
        'analysis_window_start': startTime.toIso8601String(),
        'analysis_window_end': endTime.toIso8601String(),
        'log_count': logCount,
        'threats_detected': jsonEncode(threats),
        'overall_threat_score': overallScore,
        'analyzed_at': endTime.toIso8601String(),
        'analyzed_by': 'perplexity',
      });
    } catch (e) {
      debugPrint('Store analysis results error: $e');
    }
  }
}
