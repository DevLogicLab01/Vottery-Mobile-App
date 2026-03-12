import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './twilio_notification_service.dart';
import './resend_email_service.dart';
import './openai_service.dart';
import './audit_log_service.dart';

class IncidentResponseService {
  static IncidentResponseService? _instance;
  static IncidentResponseService get instance =>
      _instance ??= IncidentResponseService._();

  IncidentResponseService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  TwilioNotificationService get _twilio => TwilioNotificationService.instance;
  ResendEmailService get _resend => ResendEmailService.instance;
  OpenAIService get _openai => OpenAIService.instance;
  final AuditLogService _auditLog = AuditLogService.instance;

  /// Orchestrate complete incident response lifecycle
  Future<Map<String, dynamic>> orchestrateIncidentResponse({
    required Map<String, dynamic> incidentData,
  }) async {
    try {
      // Step 1: Classify severity
      final severity = await classifySeverity(incidentData);

      // Step 2: Create incident record
      final incident = await _createIncident(incidentData, severity);

      // Log audit event for incident creation
      await _auditLog.logAuditEvent(
        eventType: 'incident_resolution',
        actionType: 'create',
        entityType: 'incident',
        entityId: incident['id'],
        newValue: {
          'title': incident['title'],
          'severity': severity['level'],
          'status': 'detected',
        },
        reason: 'Automated incident detection and creation',
        metadata: {
          'severity_justification': severity['justification'],
          'users_affected': severity['users_affected'],
        },
      );

      // Step 3: Route escalation
      await routeEscalation(incident);

      // Step 4: Match and execute playbook
      final playbook = await matchPlaybook(incident);
      if (playbook != null) {
        await executePlaybook(incident['id'], playbook['id']);

        // Log playbook execution
        await _auditLog.logAuditEvent(
          eventType: 'playbook_execution',
          actionType: 'execute',
          entityType: 'playbook',
          entityId: playbook['id'],
          reason: 'Automated playbook execution for incident ${incident['id']}',
          metadata: {
            'incident_id': incident['id'],
            'playbook_name': playbook['name'],
          },
        );
      }

      return {
        'success': true,
        'incident_id': incident['id'],
        'severity': severity,
        'playbook_matched': playbook != null,
      };
    } catch (e) {
      debugPrint('Orchestrate incident response error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Classify incident severity (P0-P4)
  Future<Map<String, dynamic>> classifySeverity(
    Map<String, dynamic> incidentData,
  ) async {
    try {
      final systemWideOutage = incidentData['system_wide_outage'] == true;
      final dataBreach = incidentData['data_breach'] == true;
      final paymentDown = incidentData['payment_processing_down'] == true;
      final usersAffected =
          (incidentData['user_count_affected'] as num?)?.toInt() ?? 0;
      final revenueImpact =
          (incidentData['revenue_impact'] as num?)?.toDouble() ?? 0.0;

      String level;
      String justification;

      if (systemWideOutage ||
          dataBreach ||
          paymentDown ||
          usersAffected > 1000) {
        level = 'P0';
        justification = 'Critical: System-wide impact or security breach';
      } else if (incidentData['subsystem_down'] == true ||
          incidentData['security_exploit'] == true ||
          revenueImpact > 10000) {
        level = 'P1';
        justification =
            'High: Major subsystem failure or significant revenue impact';
      } else if (incidentData['performance_degradation'] == true ||
          incidentData['isolated_failures'] == true ||
          usersAffected < 100) {
        level = 'P2';
        justification = 'Medium: Performance issues or isolated failures';
      } else if (incidentData['minor_bugs'] == true ||
          incidentData['cosmetic_issues'] == true ||
          usersAffected == 1) {
        level = 'P3';
        justification = 'Low: Minor bugs or cosmetic issues';
      } else {
        level = 'P4';
        justification = 'Informational: Monitoring alerts';
      }

      return {
        'level': level,
        'justification': justification,
        'users_affected': usersAffected,
        'revenue_impact': revenueImpact,
      };
    } catch (e) {
      debugPrint('Classify severity error: $e');
      return {'level': 'P3', 'justification': 'Default classification'};
    }
  }

  /// Create incident record
  Future<Map<String, dynamic>> _createIncident(
    Map<String, dynamic> data,
    Map<String, dynamic> severity,
  ) async {
    try {
      final response = await _client
          .from('incidents')
          .insert({
            'title': data['title'],
            'description': data['description'],
            'severity': severity['level'],
            'severity_justification': severity['justification'],
            'affected_systems': data['affected_systems'],
            'status': 'detected',
            'detected_at': DateTime.now().toIso8601String(),
            'user_count_affected': severity['users_affected'],
            'revenue_impact': severity['revenue_impact'],
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Create incident error: $e');
      rethrow;
    }
  }

  /// Route escalation based on rules
  Future<void> routeEscalation(Map<String, dynamic> incident) async {
    try {
      final severity = incident['severity'] as String;
      final detectedAt = DateTime.parse(incident['detected_at'] as String);
      final responseTime = DateTime.now().difference(detectedAt).inMinutes;

      // Get escalation rules
      final rules = await _client
          .from('escalation_rules')
          .select()
          .eq('is_active', true)
          .order('priority', ascending: true);

      for (final rule in rules) {
        final conditions = rule['conditions'] as Map<String, dynamic>;
        if (_evaluateEscalationConditions(conditions, incident, responseTime)) {
          await _executeEscalationActions(rule['actions'] as List, incident);

          // Log escalation decision
          await _auditLog.logAuditEvent(
            eventType: 'escalation_decision',
            actionType: 'escalate',
            entityType: 'incident',
            entityId: incident['id'],
            reason: 'Escalation rule triggered: ${rule['name']}',
            metadata: {
              'rule_id': rule['id'],
              'severity': severity,
              'response_time_minutes': responseTime,
              'escalation_actions': rule['actions'],
            },
          );
        }
      }

      // Log escalation
      await _client.from('escalation_history').insert({
        'incident_id': incident['id'],
        'severity': severity,
        'response_time_minutes': responseTime,
        'escalated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Route escalation error: $e');
    }
  }

  /// Evaluate escalation conditions
  bool _evaluateEscalationConditions(
    Map<String, dynamic> conditions,
    Map<String, dynamic> incident,
    int responseTime,
  ) {
    if (conditions['severity'] != null &&
        incident['severity'] == conditions['severity']) {
      if (conditions['response_time_threshold'] != null) {
        return responseTime > (conditions['response_time_threshold'] as int);
      }
      return true;
    }
    return false;
  }

  /// Execute escalation actions
  Future<void> _executeEscalationActions(
    List actions,
    Map<String, dynamic> incident,
  ) async {
    for (final action in actions) {
      final actionMap = action as Map<String, dynamic>;
      final type = actionMap['type'] as String;

      switch (type) {
        case 'twilio_sms':
          await _twilio.sendVoteDeadlineNotification(
            phoneNumber: actionMap['phone_number'],
            voteTitle: 'Incident Alert',
            deadline: DateTime.now().add(const Duration(hours: 1)),
          );
          break;
        case 'resend_email':
          await ResendEmailService.instance.sendComplianceReport(
            recipientEmail: actionMap['email'],
            reportType: '${incident['severity']} Incident',
            reportData: {
              'title': incident['title'],
              'message': _formatIncidentMessage(incident),
            },
          );
          break;
        case 'slack_webhook':
          await _sendSlackNotification(actionMap['webhook_url'], incident);
          break;
      }
    }
  }

  /// Match remediation playbook
  Future<Map<String, dynamic>?> matchPlaybook(
    Map<String, dynamic> incident,
  ) async {
    try {
      final incidentType = incident['type'] ?? 'unknown';

      // Try exact match first
      final exactMatch = await _client
          .from('remediation_playbooks')
          .select()
          .eq('incident_type', incidentType)
          .maybeSingle();

      if (exactMatch != null) {
        return Map<String, dynamic>.from(exactMatch);
      }

      // Use similarity scoring
      final allPlaybooks = await _client.from('remediation_playbooks').select();

      double bestScore = 0.0;
      Map<String, dynamic>? bestMatch;

      for (final playbook in allPlaybooks) {
        final score = _calculateSimilarityScore(
          incident['description'] as String,
          playbook['description'] as String,
        );
        if (score > bestScore) {
          bestScore = score;
          bestMatch = Map<String, dynamic>.from(playbook);
        }
      }

      return bestScore > 0.6 ? bestMatch : null;
    } catch (e) {
      debugPrint('Match playbook error: $e');
      return null;
    }
  }

  /// Execute remediation playbook
  Future<void> executePlaybook(String incidentId, String playbookId) async {
    try {
      // Create execution record
      final execution = await _client
          .from('playbook_executions')
          .insert({
            'incident_id': incidentId,
            'playbook_id': playbookId,
            'status': 'in_progress',
            'started_at': DateTime.now().toIso8601String(),
            'current_step_index': 0,
          })
          .select()
          .single();

      // Get playbook steps
      final playbook = await _client
          .from('remediation_playbooks')
          .select()
          .eq('id', playbookId)
          .single();

      final steps = playbook['steps'] as List;

      // Execute automated steps
      for (int i = 0; i < steps.length; i++) {
        final step = steps[i] as Map<String, dynamic>;
        if (step['automated_action_possible'] == true) {
          await _executeAutomatedStep(step, execution['id']);
        }
      }
    } catch (e) {
      debugPrint('Execute playbook error: $e');
    }
  }

  /// Execute automated playbook step
  Future<void> _executeAutomatedStep(
    Map<String, dynamic> step,
    String executionId,
  ) async {
    try {
      final action = step['action_type'] as String;

      switch (action) {
        case 'restart_service':
          // Placeholder for service restart
          debugPrint('Executing: Restart service ${step['service_name']}');
          break;
        case 'clear_cache':
          // Placeholder for cache clear
          debugPrint('Executing: Clear cache');
          break;
        case 'rollback_deployment':
          // Placeholder for rollback
          debugPrint('Executing: Rollback deployment');
          break;
        case 'scale_up_resources':
          // Placeholder for scaling
          debugPrint('Executing: Scale up resources');
          break;
      }

      // Log step completion
      await _client.from('playbook_step_logs').insert({
        'execution_id': executionId,
        'step_description': step['description'],
        'action_type': action,
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Execute automated step error: $e');
    }
  }

  /// Generate post-incident analysis
  Future<Map<String, dynamic>> generatePostMortem(String incidentId) async {
    try {
      // Get incident details
      final incident = await _client
          .from('incidents')
          .select()
          .eq('id', incidentId)
          .single();

      // Get timeline events
      final timeline = await _client
          .from('incident_timeline')
          .select()
          .eq('incident_id', incidentId)
          .order('timestamp', ascending: true);

      // Generate AI analysis
      final prompt =
          '''Generate a post-incident analysis for:

Incident: ${incident['title']}
Severity: ${incident['severity']}
Duration: ${_calculateDuration(incident)}

Timeline:
${timeline.map((e) => '- ${e['timestamp']}: ${e['description']}').join('\n')}

Provide:
1. Root cause analysis
2. What went well
3. What needs improvement
4. Prevention recommendations
5. Action items

Respond in JSON format with these sections.''';

      final analysis = await OpenAIService.analyzeTextSentiment(text: prompt);

      // Calculate metrics
      final detectedAt = DateTime.parse(incident['detected_at'] as String);
      final acknowledgedAt = incident['acknowledged_at'] != null
          ? DateTime.parse(incident['acknowledged_at'] as String)
          : null;
      final resolvedAt = incident['resolved_at'] != null
          ? DateTime.parse(incident['resolved_at'] as String)
          : null;

      final mttd = acknowledgedAt?.difference(detectedAt).inMinutes ?? 0;
      final mtta = acknowledgedAt?.difference(detectedAt).inMinutes ?? 0;
      final mttr = resolvedAt?.difference(detectedAt).inMinutes ?? 0;

      // Store report
      await _client.from('post_incident_reports').insert({
        'incident_id': incidentId,
        'timeline_of_events': timeline,
        'root_cause_analysis': analysis,
        'impact_assessment': {
          'users_affected': incident['user_count_affected'],
          'revenue_loss': incident['revenue_impact'],
          'downtime_minutes': mttr,
        },
        'team_performance': {'mttd': mttd, 'mtta': mtta, 'mttr': mttr},
        'generated_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'metrics': {'mttd': mttd, 'mtta': mtta, 'mttr': mttr},
      };
    } catch (e) {
      debugPrint('Generate post-mortem error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Helper: Calculate similarity score
  double _calculateSimilarityScore(String text1, String text2) {
    final words1 = text1.toLowerCase().split(' ').toSet();
    final words2 = text2.toLowerCase().split(' ').toSet();
    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;
    return union > 0 ? intersection / union : 0.0;
  }

  /// Helper: Format incident message
  String _formatIncidentMessage(Map<String, dynamic> incident) {
    return '''🚨 ${incident['severity']} INCIDENT: ${incident['title']}
Affected: ${(incident['affected_systems'] as List).join(', ')}
Started: ${incident['detected_at']}
Acknowledge: ${const String.fromEnvironment('APP_URL')}/incidents/${incident['id']}''';
  }

  /// Helper: Format incident email HTML
  String _formatIncidentEmailHtml(Map<String, dynamic> incident) {
    return '''<html><body>
<h2 style="color: red;">🚨 ${incident['severity']} Incident</h2>
<h3>${incident['title']}</h3>
<p><strong>Severity:</strong> ${incident['severity']}</p>
<p><strong>Affected Systems:</strong> ${(incident['affected_systems'] as List).join(', ')}</p>
<p><strong>Started:</strong> ${incident['detected_at']}</p>
<p><strong>Users Affected:</strong> ${incident['user_count_affected']}</p>
<a href="${const String.fromEnvironment('APP_URL')}/incidents/${incident['id']}" style="background: red; color: white; padding: 10px; text-decoration: none;">View Incident</a>
</body></html>''';
  }

  /// Helper: Send Slack notification
  Future<void> _sendSlackNotification(
    String webhookUrl,
    Map<String, dynamic> incident,
  ) async {
    // Placeholder for Slack webhook integration
    debugPrint('Sending Slack notification to $webhookUrl');
  }

  /// Helper: Calculate incident duration
  String _calculateDuration(Map<String, dynamic> incident) {
    final start = DateTime.parse(incident['detected_at'] as String);
    final end = incident['resolved_at'] != null
        ? DateTime.parse(incident['resolved_at'] as String)
        : DateTime.now();
    final duration = end.difference(start);
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  /// Get active incidents
  Future<List<Map<String, dynamic>>> getActiveIncidents() async {
    try {
      final response = await _client
          .from('incidents')
          .select()
          .neq('status', 'resolved')
          .order('detected_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Get active incidents error: $e');
      return [];
    }
  }
}
