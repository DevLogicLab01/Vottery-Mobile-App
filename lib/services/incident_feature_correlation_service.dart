import 'package:flutter/material.dart';

import './supabase_service.dart';

class CorrelatedFeature {
  final String featureId;
  final String featureName;
  final DateTime deploymentDate;
  final String deployedBy;
  final double correlationScore;
  final String? featureDeploymentId;

  CorrelatedFeature({
    required this.featureId,
    required this.featureName,
    required this.deploymentDate,
    required this.deployedBy,
    required this.correlationScore,
    this.featureDeploymentId,
  });
}

class IncidentWithCorrelation {
  final String incidentId;
  final String alertType;
  final String severity;
  final DateTime timestamp;
  final String affectedComponent;
  final String message;
  final bool resolved;
  final List<CorrelatedFeature> correlatedFeatures;
  final String possibleCause;
  final List<String> recommendations;

  IncidentWithCorrelation({
    required this.incidentId,
    required this.alertType,
    required this.severity,
    required this.timestamp,
    required this.affectedComponent,
    required this.message,
    required this.resolved,
    required this.correlatedFeatures,
    required this.possibleCause,
    required this.recommendations,
  });
}

class IncidentFeatureCorrelationService {
  static final IncidentFeatureCorrelationService instance =
      IncidentFeatureCorrelationService._internal();
  IncidentFeatureCorrelationService._internal();

  final _client = SupabaseService.instance.client;

  Future<List<IncidentWithCorrelation>>
  getIncidentsWithCorrelatedFeatures() async {
    try {
      final sevenDaysAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .toIso8601String();

      // Fetch incidents
      final incidentsResponse = await _client
          .from('system_alerts')
          .select()
          .or('resolved.eq.false,timestamp.gte.$sevenDaysAgo')
          .order('timestamp', ascending: false)
          .limit(50);

      // Fetch feature deployments
      final deploymentsResponse = await _client
          .from('feature_deployment_log')
          .select()
          .gte('deployment_date', sevenDaysAgo)
          .order('deployment_date', ascending: false);

      final incidents = List<Map<String, dynamic>>.from(incidentsResponse);
      final deployments = List<Map<String, dynamic>>.from(deploymentsResponse);

      return incidents.map((incident) {
        final incidentTime = incident['timestamp'] != null
            ? DateTime.parse(incident['timestamp'].toString())
            : DateTime.now();

        final correlated = <CorrelatedFeature>[];
        for (final dep in deployments) {
          final depTime = dep['deployment_date'] != null
              ? DateTime.parse(dep['deployment_date'].toString())
              : null;
          if (depTime == null) continue;

          final diff = incidentTime.difference(depTime).abs();
          double proximityScore;
          if (diff.inMinutes <= 5) {
            proximityScore = 1.0;
          } else if (diff.inMinutes <= 15) {
            proximityScore = 0.8;
          } else if (diff.inHours <= 1) {
            proximityScore = 0.5;
          } else {
            continue; // outside correlation window
          }

          final severity = incident['severity']?.toString() ?? '';
          final affectedComponent =
              incident['affected_component']?.toString() ?? '';
          final featureName = dep['feature_name']?.toString() ?? '';

          double impactScore = 0.5;
          if (severity == 'critical' &&
              affectedComponent.toLowerCase().contains(
                featureName.toLowerCase(),
              )) {
            impactScore = 1.0;
          }

          final finalScore = proximityScore * impactScore;

          correlated.add(
            CorrelatedFeature(
              featureId: dep['feature_id']?.toString() ?? '',
              featureName: featureName,
              deploymentDate: depTime,
              deployedBy: dep['deployed_by']?.toString() ?? 'Unknown',
              correlationScore: finalScore,
              featureDeploymentId: dep['id']?.toString(),
            ),
          );
        }

        correlated.sort(
          (a, b) => b.correlationScore.compareTo(a.correlationScore),
        );

        String possibleCause = 'Unknown';
        List<String> recommendations = [];
        if (correlated.isNotEmpty && correlated.first.correlationScore > 0.7) {
          final topFeature = correlated.first;
          possibleCause =
              'Feature deployment: ${topFeature.featureName} at ${topFeature.deploymentDate.toLocal().toString().substring(0, 16)}';
          recommendations = [
            'Review recent changes in ${topFeature.featureName}',
            'Consider rollback if issue persists',
            'Check deployment logs for ${topFeature.deployedBy}',
          ];
        } else if (correlated.isNotEmpty) {
          possibleCause = 'Infrastructure issue (possible feature correlation)';
          recommendations = [
            'Monitor system metrics',
            'Check infrastructure health',
          ];
        } else {
          possibleCause = 'Infrastructure issue';
          recommendations = [
            'Check server logs',
            'Review infrastructure metrics',
          ];
        }

        return IncidentWithCorrelation(
          incidentId:
              incident['incident_id']?.toString() ??
              incident['id']?.toString() ??
              '',
          alertType: incident['alert_type']?.toString() ?? 'Unknown',
          severity: incident['severity']?.toString() ?? 'low',
          timestamp: incidentTime,
          affectedComponent: incident['affected_component']?.toString() ?? '',
          message: incident['message']?.toString() ?? '',
          resolved: incident['resolved'] as bool? ?? false,
          correlatedFeatures: correlated,
          possibleCause: possibleCause,
          recommendations: recommendations,
        );
      }).toList();
    } catch (e) {
      debugPrint('IncidentFeatureCorrelationService error: $e');
      return _getMockIncidents();
    }
  }

  Future<bool> resolveIncident(String incidentId) async {
    try {
      await _client
          .from('system_alerts')
          .update({'resolved': true})
          .eq('incident_id', incidentId);
      return true;
    } catch (e) {
      debugPrint('resolveIncident error: $e');
      return false;
    }
  }

  List<IncidentWithCorrelation> _getMockIncidents() {
    return [
      IncidentWithCorrelation(
        incidentId: 'INC-001',
        alertType: 'API Latency Spike',
        severity: 'critical',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        affectedComponent: 'payment-service',
        message: 'P99 latency exceeded 2000ms threshold',
        resolved: false,
        correlatedFeatures: [
          CorrelatedFeature(
            featureId: 'feat-001',
            featureName: 'Payment Flow v2',
            deploymentDate: DateTime.now().subtract(
              const Duration(hours: 2, minutes: 10),
            ),
            deployedBy: 'deploy-bot',
            correlationScore: 0.9,
          ),
        ],
        possibleCause: 'Feature deployment: Payment Flow v2',
        recommendations: [
          'Review Payment Flow v2 changes',
          'Consider rollback',
        ],
      ),
      IncidentWithCorrelation(
        incidentId: 'INC-002',
        alertType: 'Database Connection Error',
        severity: 'high',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        affectedComponent: 'database-pool',
        message: 'Connection pool exhausted',
        resolved: true,
        correlatedFeatures: [],
        possibleCause: 'Infrastructure issue',
        recommendations: ['Increase connection pool size'],
      ),
    ];
  }
}
