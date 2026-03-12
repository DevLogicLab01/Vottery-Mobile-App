import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class UnifiedIncidentAggregator {
  static final UnifiedIncidentAggregator _instance =
      UnifiedIncidentAggregator._internal();
  factory UnifiedIncidentAggregator() => _instance;
  UnifiedIncidentAggregator._internal();

  final _supabase = Supabase.instance.client;
  StreamController<UnifiedIncident>? _incidentStreamController;

  /// Start aggregating incidents from all sources
  Stream<UnifiedIncident> startAggregation() {
    _incidentStreamController = StreamController<UnifiedIncident>.broadcast();

    // Subscribe to fraud alerts
    _subscribeFraudAlerts();

    // Subscribe to AI failover events
    _subscribeAIFailoverEvents();

    // Subscribe to security incidents
    _subscribeSecurityIncidents();

    // Subscribe to performance anomalies
    _subscribePerformanceAnomalies();

    // Subscribe to system health alerts
    _subscribeSystemHealthAlerts();

    // Subscribe to compliance violations
    _subscribeComplianceViolations();

    return _incidentStreamController!.stream;
  }

  void _subscribeFraudAlerts() {
    _supabase
        .from('fraud_analysis_results')
        .stream(primaryKey: ['analysis_id'])
        .eq('severity', 'critical')
        .listen((data) {
          for (final record in data) {
            final incident = UnifiedIncident(
              incidentId: record['analysis_id'],
              incidentType: IncidentType.fraud,
              severity: _mapSeverity(record['severity']),
              title: 'Critical Fraud Pattern Detected',
              description:
                  'Fraud pattern: ${record['detected_patterns']?[0]?['pattern_name'] ?? 'Unknown'}',
              sourceSystem: 'fraud_analysis',
              detectedAt: DateTime.parse(record['created_at']),
              status: IncidentStatus.newIncident,
              affectedResources: _extractAffectedUsers(record),
              metadata: record,
            );
            _incidentStreamController?.add(incident);
          }
        });
  }

  void _subscribeAIFailoverEvents() {
    _supabase
        .from('failover_events')
        .stream(primaryKey: ['event_id'])
        .gte(
          'detected_at',
          DateTime.now().subtract(Duration(hours: 24)).toIso8601String(),
        )
        .listen((data) {
          for (final record in data) {
            final incident = UnifiedIncident(
              incidentId: record['event_id'],
              incidentType: IncidentType.aiFailover,
              severity: IncidentSeverity.high,
              title: 'AI Service Failover',
              description:
                  'Service ${record['failed_service']} failed over to ${record['backup_service']}',
              sourceSystem: 'ai_failover',
              detectedAt: DateTime.parse(record['detected_at']),
              status: IncidentStatus.newIncident,
              affectedResources: [record['failed_service']],
              metadata: record,
            );
            _incidentStreamController?.add(incident);
          }
        });
  }

  void _subscribeSecurityIncidents() {
    _supabase
        .from('security_incidents')
        .stream(primaryKey: ['id'])
        .inFilter('status', ['active', 'investigating'])
        .listen((data) {
          for (final record in data) {
            final incident = UnifiedIncident(
              incidentId: record['id'],
              incidentType: IncidentType.security,
              severity: _mapSeverity(record['severity']),
              title: record['title'] ?? 'Security Incident',
              description: record['description'] ?? '',
              sourceSystem: 'security',
              detectedAt: DateTime.parse(record['detected_at']),
              status: _mapStatus(record['status']),
              affectedResources: List<String>.from(
                record['affected_systems'] ?? [],
              ),
              metadata: record,
            );
            _incidentStreamController?.add(incident);
          }
        });
  }

  void _subscribePerformanceAnomalies() {
    _supabase
        .from('performance_anomalies')
        .stream(primaryKey: ['id'])
        .gte('severity', 'high')
        .listen((data) {
          for (final record in data) {
            final incident = UnifiedIncident(
              incidentId: record['id'],
              incidentType: IncidentType.performance,
              severity: _mapSeverity(record['severity']),
              title: 'Performance Anomaly Detected',
              description: record['description'] ?? '',
              sourceSystem: 'performance_monitoring',
              detectedAt: DateTime.parse(record['detected_at']),
              status: IncidentStatus.newIncident,
              affectedResources: [record['resource_name']],
              metadata: record,
            );
            _incidentStreamController?.add(incident);
          }
        });
  }

  void _subscribeSystemHealthAlerts() {
    _supabase
        .from('service_health_history')
        .stream(primaryKey: ['id'])
        .eq('status', 'down')
        .listen((data) {
          for (final record in data) {
            final incident = UnifiedIncident(
              incidentId: record['id'],
              incidentType: IncidentType.health,
              severity: IncidentSeverity.critical,
              title: 'Service Down',
              description: 'Service ${record['service_name']} is down',
              sourceSystem: 'health_monitoring',
              detectedAt: DateTime.parse(record['checked_at']),
              status: IncidentStatus.newIncident,
              affectedResources: [record['service_name']],
              metadata: record,
            );
            _incidentStreamController?.add(incident);
          }
        });
  }

  void _subscribeComplianceViolations() {
    _supabase
        .from('compliance_audits')
        .stream(primaryKey: ['id'])
        .eq('status', 'non_compliant')
        .listen((data) {
          for (final record in data) {
            final incident = UnifiedIncident(
              incidentId: record['id'],
              incidentType: IncidentType.compliance,
              severity: IncidentSeverity.medium,
              title: 'Compliance Violation',
              description: record['violation_details'] ?? '',
              sourceSystem: 'compliance',
              detectedAt: DateTime.parse(record['audit_date']),
              status: IncidentStatus.newIncident,
              affectedResources: [record['audit_type']],
              metadata: record,
            );
            _incidentStreamController?.add(incident);
          }
        });
  }

  IncidentSeverity _mapSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return IncidentSeverity.critical;
      case 'high':
        return IncidentSeverity.high;
      case 'medium':
        return IncidentSeverity.medium;
      case 'low':
        return IncidentSeverity.low;
      default:
        return IncidentSeverity.medium;
    }
  }

  IncidentStatus _mapStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'new':
        return IncidentStatus.newIncident;
      case 'triaged':
        return IncidentStatus.triaged;
      case 'investigating':
        return IncidentStatus.investigating;
      case 'resolved':
        return IncidentStatus.resolved;
      default:
        return IncidentStatus.newIncident;
    }
  }

  List<String> _extractAffectedUsers(Map<String, dynamic> record) {
    final patterns = record['detected_patterns'] as List?;
    if (patterns == null || patterns.isEmpty) return [];

    final affectedUsers = patterns[0]['affected_users'] as List?;
    return affectedUsers?.map((u) => u.toString()).toList() ?? [];
  }

  /// Calculate automated triage priority score
  int calculatePriorityScore(UnifiedIncident incident) {
    int score = 0;

    // Severity weight
    switch (incident.severity) {
      case IncidentSeverity.critical:
        score += 100;
        break;
      case IncidentSeverity.high:
        score += 75;
        break;
      case IncidentSeverity.medium:
        score += 50;
        break;
      case IncidentSeverity.low:
        score += 25;
        break;
    }

    // Affected users multiplier
    score += (incident.affectedResources.length * 0.5).toInt();

    // Business impact (from metadata)
    final revenueImpact = incident.metadata['revenue_impact'] as num? ?? 0;
    if (revenueImpact > 10000) score += 20;
    if (revenueImpact > 50000) score += 30;

    // Time sensitivity (SLA approaching)
    final age = DateTime.now().difference(incident.detectedAt).inMinutes;
    if (age > 30) score += 10;
    if (age > 60) score += 20;

    return score;
  }

  /// Assign priority based on score
  String assignPriority(int score) {
    if (score > 90) return 'P0';
    if (score >= 70) return 'P1';
    if (score >= 50) return 'P2';
    return 'P3';
  }

  /// Route incident to appropriate team
  String routeToTeam(IncidentType type) {
    switch (type) {
      case IncidentType.fraud:
        return 'security';
      case IncidentType.aiFailover:
        return 'devops';
      case IncidentType.security:
        return 'security';
      case IncidentType.performance:
        return 'sre';
      case IncidentType.health:
        return 'on_call_engineer';
      case IncidentType.compliance:
        return 'legal';
    }
  }

  void dispose() {
    _incidentStreamController?.close();
  }
}

// Unified incident model
class UnifiedIncident {
  final String incidentId;
  final IncidentType incidentType;
  final IncidentSeverity severity;
  final String title;
  final String description;
  final String sourceSystem;
  final DateTime detectedAt;
  final IncidentStatus status;
  final List<String> affectedResources;
  final Map<String, dynamic> metadata;
  String? assignedTo;
  int? priorityScore;

  UnifiedIncident({
    required this.incidentId,
    required this.incidentType,
    required this.severity,
    required this.title,
    required this.description,
    required this.sourceSystem,
    required this.detectedAt,
    required this.status,
    required this.affectedResources,
    required this.metadata,
    this.assignedTo,
    this.priorityScore,
  });
}

enum IncidentType {
  fraud,
  aiFailover,
  security,
  performance,
  health,
  compliance,
}

enum IncidentSeverity { critical, high, medium, low }

enum IncidentStatus { newIncident, triaged, investigating, resolved }
