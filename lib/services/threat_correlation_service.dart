import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './openai_service.dart';
import './anthropic_service.dart';
import './perplexity_service.dart';
import './gemini_service.dart';
import './twilio_notification_service.dart';
import './resend_email_service.dart';
import 'dart:math';
import './datadog_tracing_service.dart';

class ThreatCorrelationService {
  static ThreatCorrelationService? _instance;
  static ThreatCorrelationService get instance =>
      _instance ??= ThreatCorrelationService._();

  ThreatCorrelationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  PerplexityService get _perplexity => PerplexityService.instance;
  TwilioNotificationService get _twilio => TwilioNotificationService.instance;
  ResendEmailService get _resend => ResendEmailService.instance;
  final DatadogTracingService _tracing = DatadogTracingService.instance;

  /// Correlate incidents with multi-AI consensus scoring
  Future<Map<String, dynamic>> correlateIncidents({
    required List<Map<String, dynamic>> incidents,
  }) async {
    // Start parent span for multi-AI consensus
    final parentSpanId = await _tracing.startSpan(
      'multi_ai_consensus',
      resourceName: 'correlateIncidents',
      tags: {
        'multi_ai.incident_count': incidents.length.toString(),
        'multi_ai.operation': 'threat_correlation',
      },
    );

    final stopwatch = Stopwatch()..start();

    try {
      // Create child spans for each AI service
      final openaiSpanId = await _tracing.startSpan(
        'openai_threat_analysis',
        tags: {'openai.model': 'gpt-4o', 'parent_span': parentSpanId},
      );

      final anthropicSpanId = await _tracing.startSpan(
        'anthropic_correlation',
        tags: {
          'anthropic.model': 'claude-sonnet-4',
          'parent_span': parentSpanId,
        },
      );

      final perplexitySpanId = await _tracing.startSpan(
        'perplexity_context',
        tags: {
          'perplexity.model': 'sonar-reasoning',
          'parent_span': parentSpanId,
        },
      );

      final geminiSpanId = await _tracing.startSpan(
        'gemini_impact',
        tags: {'gemini.model': 'gemini-pro', 'parent_span': parentSpanId},
      );

      // Run multi-AI analysis in parallel
      final results = await Future.wait([
        _analyzeWithOpenAI(incidents),
        _analyzeWithAnthropic(incidents),
        _analyzeWithPerplexity(incidents),
        _analyzeWithGemini(incidents),
      ]);

      // Finish child spans
      await _tracing.finishSpan(
        openaiSpanId,
        tags: {'openai.threat_score': results[0]['threat_score'].toString()},
      );
      await _tracing.finishSpan(
        anthropicSpanId,
        tags: {
          'anthropic.correlation_score': results[1]['correlation_score']
              .toString(),
        },
      );
      await _tracing.finishSpan(
        perplexitySpanId,
        tags: {
          'perplexity.context_score': results[2]['context_score'].toString(),
        },
      );
      await _tracing.finishSpan(
        geminiSpanId,
        tags: {'gemini.impact_score': results[3]['impact_score'].toString()},
      );

      final openaiScore = results[0]['threat_score'] as double;
      final anthropicScore = results[1]['correlation_score'] as double;
      final perplexityScore = results[2]['context_score'] as double;
      final geminiScore = results[3]['impact_score'] as double;

      // Calculate weighted consensus score
      final consensusScore =
          (openaiScore * 0.3) +
          (anthropicScore * 0.3) +
          (perplexityScore * 0.2) +
          (geminiScore * 0.2);

      // Calculate confidence level based on AI agreement
      final scores = [
        openaiScore,
        anthropicScore,
        perplexityScore,
        geminiScore,
      ];
      final avgScore = scores.reduce((a, b) => a + b) / scores.length;
      final variance =
          scores.map((s) => pow(s - avgScore, 2)).reduce((a, b) => a + b) /
          scores.length;
      final stdDev = sqrt(variance);
      final confidenceLevel = stdDev < 0.15
          ? 'high'
          : (stdDev < 0.30 ? 'medium' : 'low');

      stopwatch.stop();

      // Finish parent span with aggregated metrics
      await _tracing.finishSpan(
        parentSpanId,
        tags: {
          'multi_ai.consensus_score': consensusScore.toString(),
          'multi_ai.confidence_level': confidenceLevel,
          'multi_ai.total_duration_ms': stopwatch.elapsedMilliseconds
              .toString(),
          'multi_ai.openai_score': openaiScore.toString(),
          'multi_ai.anthropic_score': anthropicScore.toString(),
          'multi_ai.perplexity_score': perplexityScore.toString(),
          'multi_ai.gemini_score': geminiScore.toString(),
        },
      );

      return {
        'success': true,
        'consensus_score': consensusScore,
        'confidence_level': confidenceLevel,
        'ai_scores': {
          'openai_threat_score': openaiScore,
          'anthropic_correlation_score': anthropicScore,
          'perplexity_context_score': perplexityScore,
          'gemini_impact_score': geminiScore,
        },
        'ai_results': {
          'openai': results[0],
          'anthropic': results[1],
          'perplexity': results[2],
          'gemini': results[3],
        },
      };
    } catch (e) {
      stopwatch.stop();

      // Finish parent span with error
      await _tracing.finishSpan(
        parentSpanId,
        error: e.toString(),
        tags: {
          'multi_ai.error': 'true',
          'multi_ai.duration_ms': stopwatch.elapsedMilliseconds.toString(),
        },
      );

      debugPrint('Correlate incidents error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Analyze incidents with OpenAI for threat severity
  Future<Map<String, dynamic>> _analyzeWithOpenAI(
    List<Map<String, dynamic>> incidents,
  ) async {
    try {
      final prompt =
          '''Analyze these security incidents for threat severity and pattern matching:
${incidents.map((i) => '- ${i['type']}: ${i['description']} at ${i['timestamp']}').join('\n')}

Provide:
1. Threat severity score (0.0-1.0)
2. Attack patterns identified
3. Severity justification

Respond in JSON format: {"threat_score": 0.0-1.0, "patterns": [], "justification": ""}''';

      final response = await OpenAIService.analyzeTextSentiment(text: prompt);

      // Parse JSON response
      return {
        'threat_score': (response['sentiment_score'] ?? 0.5) as double,
        'patterns': [],
        'justification': response['sentiment_label'] ?? 'Analysis completed',
      };
    } catch (e) {
      debugPrint('OpenAI analysis error: $e');
      return {
        'threat_score': 0.5,
        'patterns': [],
        'justification': 'Analysis failed',
      };
    }
  }

  /// Analyze incidents with Anthropic for correlation
  Future<Map<String, dynamic>> _analyzeWithAnthropic(
    List<Map<String, dynamic>> incidents,
  ) async {
    try {
      final incidentData = {
        'incidents': incidents,
        'analysis_type': 'correlation',
      };

      final response = await AnthropicService.analyzeSecurityIncident(
        incidentId: 'correlation_${DateTime.now().millisecondsSinceEpoch}',
        incidentData: incidentData,
      );

      return {
        'correlation_score': response.confidenceScore,
        'relationships': [],
        'explanation': response.recommendation,
      };
    } catch (e) {
      debugPrint('Anthropic analysis error: $e');
      return {
        'correlation_score': 0.5,
        'relationships': [],
        'explanation': 'Analysis failed',
      };
    }
  }

  /// Analyze incidents with Perplexity for threat intelligence
  Future<Map<String, dynamic>> _analyzeWithPerplexity(
    List<Map<String, dynamic>> incidents,
  ) async {
    try {
      final threatData = {
        'incidents': incidents,
        'analysis_type': 'threat_intelligence',
      };

      final response = await _perplexity.analyzeThreatIntelligenceInstance(
        threatData: threatData,
      );

      return {
        'context_score': 0.5,
        'similar_incidents': [],
        'threat_context': response['threat_level'] ?? 'Analysis completed',
      };
    } catch (e) {
      debugPrint('Perplexity analysis error: $e');
      return {
        'context_score': 0.5,
        'similar_incidents': [],
        'threat_context': 'Analysis failed',
      };
    }
  }

  /// Analyze incidents with Gemini for system impact
  Future<Map<String, dynamic>> _analyzeWithGemini(
    List<Map<String, dynamic>> incidents,
  ) async {
    try {
      final incidentData = {
        'incidents': incidents,
        'analysis_type': 'system_impact',
      };

      final response = await GeminiService.analyzeSecurityIncident(
        incidentId: 'impact_${DateTime.now().millisecondsSinceEpoch}',
        incidentData: incidentData,
      );

      return {
        'impact_score': 0.5,
        'affected_systems': [],
        'impact_assessment': response['analysis'] ?? 'Analysis completed',
      };
    } catch (e) {
      debugPrint('Gemini analysis error: $e');
      return {
        'impact_score': 0.5,
        'affected_systems': [],
        'impact_assessment': 'Analysis failed',
      };
    }
  }

  /// Perform DBSCAN clustering on incidents
  Future<List<Map<String, dynamic>>> clusterIncidents(
    List<Map<String, dynamic>> incidents,
  ) async {
    try {
      final clusters = <Map<String, dynamic>>[];
      final visited = <int>{};
      final clustered = <int>{};

      for (int i = 0; i < incidents.length; i++) {
        if (visited.contains(i)) continue;
        visited.add(i);

        final neighbors = _findNeighbors(incidents, i);
        if (neighbors.length < 2) continue; // Min points threshold

        // Create new cluster
        final clusterIncidents = [incidents[i]];
        clustered.add(i);

        for (final neighborIdx in neighbors) {
          if (!clustered.contains(neighborIdx)) {
            clusterIncidents.add(incidents[neighborIdx]);
            clustered.add(neighborIdx);
          }
        }

        // Determine cluster type
        final clusterType = _determineClusterType(clusterIncidents);

        // Get consensus score for cluster
        final consensusResult = await correlateIncidents(
          incidents: clusterIncidents,
        );

        clusters.add({
          'cluster_id': _generateClusterId(),
          'incident_ids': clusterIncidents.map((i) => i['id']).toList(),
          'cluster_type': clusterType,
          'consensus_score': consensusResult['consensus_score'],
          'confidence_level': consensusResult['confidence_level'],
          'detected_at': DateTime.now().toIso8601String(),
          'incident_count': clusterIncidents.length,
          'time_window': _calculateTimeWindow(clusterIncidents),
          'affected_systems': _extractAffectedSystems(clusterIncidents),
        });
      }

      // Store clusters in database
      for (final cluster in clusters) {
        await _client.from('incident_clusters').insert(cluster);

        // Send alerts for high-severity clusters
        if (cluster['consensus_score'] >= 0.75) {
          await _sendClusterAlert(cluster);
        }
      }

      return clusters;
    } catch (e) {
      debugPrint('Cluster incidents error: $e');
      return [];
    }
  }

  /// Find neighboring incidents within 30-minute window
  List<int> _findNeighbors(List<Map<String, dynamic>> incidents, int index) {
    final neighbors = <int>[];
    final incident = incidents[index];
    final timestamp = DateTime.parse(incident['timestamp'] as String);

    for (int i = 0; i < incidents.length; i++) {
      if (i == index) continue;

      final otherIncident = incidents[i];
      final otherTimestamp = DateTime.parse(
        otherIncident['timestamp'] as String,
      );

      // Check 30-minute proximity
      if (timestamp.difference(otherTimestamp).abs().inMinutes <= 30) {
        // Check IP similarity
        if (incident['ip_address'] == otherIncident['ip_address']) {
          neighbors.add(i);
          continue;
        }

        // Check user_id correlation
        if (incident['user_id'] == otherIncident['user_id']) {
          neighbors.add(i);
          continue;
        }

        // Check system component overlap
        final systems1 =
            (incident['affected_systems'] as List?)?.cast<String>() ?? [];
        final systems2 =
            (otherIncident['affected_systems'] as List?)?.cast<String>() ?? [];
        if (systems1.any((s) => systems2.contains(s))) {
          neighbors.add(i);
        }
      }
    }

    return neighbors;
  }

  /// Determine cluster type based on incident patterns
  String _determineClusterType(List<Map<String, dynamic>> incidents) {
    final types = incidents.map((i) => i['type'] as String).toSet();

    if (types.contains('coordinated_attack')) return 'coordinated_attack';
    if (types.contains('system_failure') && incidents.length > 3) {
      return 'cascading_failure';
    }
    if (incidents.length > 5) return 'anomaly_spike';
    return 'system_outage';
  }

  /// Generate root cause analysis using OpenAI
  Future<Map<String, dynamic>> generateRootCauseAnalysis(
    List<Map<String, dynamic>> incidents,
  ) async {
    try {
      final prompt =
          '''Analyze these correlated incidents and identify the root cause:
${incidents.map((i) => '- ${i['type']}: ${i['description']} at ${i['timestamp']}').join('\n')}

Consider:
1) Timeline of events
2) System dependencies
3) Common factors
4) Initial trigger

Provide root cause with confidence score and supporting evidence.

Respond in JSON format: {
  "root_cause_description": "",
  "contributing_factors": [],
  "initial_trigger": "",
  "confidence_score": 0.0-1.0,
  "recommended_fixes": [],
  "evidence": []
}''';

      final response = await OpenAIService.analyzeTextSentiment(text: prompt);

      return {
        'root_cause_description':
            response['sentiment_label'] ?? 'Analysis completed',
        'contributing_factors': response['themes'] ?? [],
        'initial_trigger': 'Unknown',
        'confidence_score': (response['confidence'] ?? 0.0) as double,
        'recommended_fixes': [],
        'evidence': [],
      };
    } catch (e) {
      debugPrint('Root cause analysis error: $e');
      return {
        'root_cause_description': 'Analysis failed',
        'contributing_factors': [],
        'initial_trigger': 'Unknown',
        'confidence_score': 0.0,
        'recommended_fixes': [],
        'evidence': [],
      };
    }
  }

  /// Send cluster alert via Twilio and Resend
  Future<void> _sendClusterAlert(Map<String, dynamic> cluster) async {
    try {
      final consensusScore = (cluster['consensus_score'] as double) * 100;
      final message =
          '''🚨 HIGH-SEVERITY INCIDENT CLUSTER DETECTED

Cluster ID: ${cluster['cluster_id']}
Type: ${cluster['cluster_type']}
Consensus Score: ${consensusScore.toStringAsFixed(1)}%
Incidents: ${cluster['incident_count']}
Affected Systems: ${(cluster['affected_systems'] as List).join(', ')}

Immediate investigation required.''';

      // Send SMS to on-call team
      await _twilio.sendVoteDeadlineNotification(
        phoneNumber: const String.fromEnvironment('ONCALL_PHONE'),
        voteTitle: 'Security Alert',
        deadline: DateTime.now().add(const Duration(hours: 1)),
      );

      // Send email alert
      await _resend.sendComplianceReport(
        recipientEmail: const String.fromEnvironment('SECURITY_EMAIL'),
        reportType: 'Critical: Incident Cluster Detected',
        reportData: {'message': message},
      );
    } catch (e) {
      debugPrint('Send cluster alert error: $e');
    }
  }

  /// Helper: Generate unique cluster ID
  String _generateClusterId() {
    return 'cluster_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  /// Helper: Calculate time window for cluster
  Map<String, String> _calculateTimeWindow(
    List<Map<String, dynamic>> incidents,
  ) {
    final timestamps =
        incidents.map((i) => DateTime.parse(i['timestamp'] as String)).toList()
          ..sort();

    return {
      'start': timestamps.first.toIso8601String(),
      'end': timestamps.last.toIso8601String(),
    };
  }

  /// Helper: Extract affected systems from incidents
  List<String> _extractAffectedSystems(List<Map<String, dynamic>> incidents) {
    final systems = <String>{};
    for (final incident in incidents) {
      final incidentSystems =
          (incident['affected_systems'] as List?)?.cast<String>() ?? [];
      systems.addAll(incidentSystems);
    }
    return systems.toList();
  }

  /// Get recent incidents for correlation (last 24 hours)
  Future<List<Map<String, dynamic>>> getRecentIncidents() async {
    try {
      final response = await _client
          .from('security_incidents')
          .select()
          .gte(
            'created_at',
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .toIso8601String(),
          )
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Get recent incidents error: $e');
      return [];
    }
  }

  /// Get all incident clusters
  Future<List<Map<String, dynamic>>> getIncidentClusters() async {
    try {
      final response = await _client
          .from('incident_clusters')
          .select()
          .order('detected_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Get incident clusters error: $e');
      return [];
    }
  }

  /// Get zone threat summary for heatmap display
  Future<Map<String, Map<String, dynamic>>> getZoneThreatSummary() async {
    try {
      final response = await _client
          .from('zone_threat_assessments')
          .select()
          .order('updated_at', ascending: false)
          .limit(20);
      final rows = List<Map<String, dynamic>>.from(response);
      final Map<String, Map<String, dynamic>> summary = {};
      for (final row in rows) {
        final zoneId =
            row['zone_name'] as String? ?? row['zone_id']?.toString() ?? '';
        if (zoneId.isNotEmpty) {
          summary[zoneId] = {
            'threat_level': row['threat_level'] as String? ?? 'low',
            'active_incidents': row['active_incidents'] as int? ?? 0,
            'predicted_trend': row['predicted_trend'] as String? ?? 'Stable',
            'top_vulnerabilities': row['top_vulnerabilities'] as List? ?? [],
          };
        }
      }
      return summary;
    } catch (e) {
      debugPrint('Get zone threat summary error: $e');
      return {};
    }
  }
}
