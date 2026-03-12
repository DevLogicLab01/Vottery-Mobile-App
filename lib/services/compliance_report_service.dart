import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import './supabase_service.dart';
import './auth_service.dart';
import './audit_log_service.dart';

class ComplianceReportService {
  static ComplianceReportService? _instance;
  static ComplianceReportService get instance =>
      _instance ??= ComplianceReportService._();

  ComplianceReportService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  AuditLogService get _auditLog => AuditLogService.instance;

  /// Generate compliance report
  Future<Map<String, dynamic>> generateComplianceReport({
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? auditCategories,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      // Query audit logs for the period
      final auditLogs = await _auditLog.getAuditLogs(
        startDate: startDate,
        endDate: endDate,
        eventTypes: _getEventTypesForFramework(reportType),
        limit: 10000,
      );

      // Aggregate compliance metrics
      final metrics = _aggregateComplianceMetrics(auditLogs, reportType);

      // Organize by compliance requirements
      final requirementData = _organizeByRequirements(auditLogs, reportType);

      // Generate report data
      final reportData = {
        'report_type': reportType,
        'reporting_period': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
        'executive_summary': {
          'total_events': auditLogs.length,
          'compliance_status': _calculateComplianceStatus(metrics),
          'critical_findings': metrics['critical_findings'] ?? 0,
          'recommendations': metrics['recommendations'] ?? 0,
        },
        'detailed_findings': requirementData,
        'compliance_metrics': metrics,
        'generated_at': DateTime.now().toIso8601String(),
      };

      // Calculate report hash
      final reportHash = _calculateReportHash(reportData);

      // Store report
      final response = await _client
          .from('generated_compliance_reports')
          .insert({
            'report_type': reportType,
            'reporting_period_start': startDate.toIso8601String(),
            'reporting_period_end': endDate.toIso8601String(),
            'generated_by': _auth.currentUser!.id,
            'compliance_status':
                (reportData['executive_summary']
                    as Map<String, dynamic>)['compliance_status'],
            'report_data': reportData,
            'report_hash': reportHash,
          })
          .select()
          .single();

      final reportId = response['report_id'] as String;

      // Generate digital signature
      await _generateDigitalSignature(reportId, reportHash);

      return {
        'success': true,
        'report_id': reportId,
        'report_data': reportData,
        'report_hash': reportHash,
      };
    } catch (e) {
      debugPrint('Generate compliance report error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get event types for compliance framework
  List<String> _getEventTypesForFramework(String framework) {
    switch (framework) {
      case 'GDPR':
        return [
          'user_data_access',
          'data_deletion',
          'consent_changes',
          'data_export',
          'security_policy_change',
        ];
      case 'SOC2':
        return [
          'security_policy_change',
          'incident_resolution',
          'configuration_change',
          'user_action',
        ];
      case 'HIPAA':
        return ['security_policy_change', 'incident_resolution', 'user_action'];
      case 'ISO27001':
        return [
          'security_policy_change',
          'incident_resolution',
          'configuration_change',
          'playbook_execution',
        ];
      default:
        return [];
    }
  }

  /// Aggregate compliance metrics
  Map<String, dynamic> _aggregateComplianceMetrics(
    List<Map<String, dynamic>> auditLogs,
    String reportType,
  ) {
    final metrics = <String, dynamic>{
      'total_events': auditLogs.length,
      'events_by_type': <String, int>{},
      'actors_involved': <String>{},
      'critical_findings': 0,
      'recommendations': 0,
    };

    for (final log in auditLogs) {
      final eventType = log['event_type'] as String? ?? 'unknown';
      metrics['events_by_type'][eventType] =
          (metrics['events_by_type'][eventType] ?? 0) + 1;

      final actorUsername = log['actor_username'] as String?;
      if (actorUsername != null) {
        (metrics['actors_involved'] as Set<String>).add(actorUsername);
      }
    }

    metrics['actors_involved'] =
        (metrics['actors_involved'] as Set<String>).length;

    return metrics;
  }

  /// Organize audit logs by compliance requirements
  List<Map<String, dynamic>> _organizeByRequirements(
    List<Map<String, dynamic>> auditLogs,
    String reportType,
  ) {
    final requirements = <Map<String, dynamic>>[];

    // Map event types to requirements
    final requirementMapping = _getRequirementMapping(reportType);

    requirementMapping.forEach((requirement, eventTypes) {
      final relevantLogs = auditLogs
          .where((log) => eventTypes.contains(log['event_type']))
          .toList();

      requirements.add({
        'requirement': requirement,
        'event_count': relevantLogs.length,
        'compliance_assessment': relevantLogs.isNotEmpty ? 'Met' : 'Not Met',
        'evidence': relevantLogs
            .take(10)
            .map(
              (log) => {
                'timestamp': log['event_timestamp'],
                'actor': log['actor_username'],
                'action': log['action_type'],
                'entity': log['entity_type'],
              },
            )
            .toList(),
      });
    });

    return requirements;
  }

  /// Get requirement mapping for framework
  Map<String, List<String>> _getRequirementMapping(String framework) {
    switch (framework) {
      case 'GDPR':
        return {
          'Article 32 - Security of Processing': ['security_policy_change'],
          'Article 15 - Right of Access': ['user_data_access', 'data_export'],
          'Article 17 - Right to Erasure': ['data_deletion'],
        };
      case 'SOC2':
        return {
          'CC6.1 - Logical Access': ['security_policy_change', 'user_action'],
          'CC7.2 - System Monitoring': ['incident_resolution'],
        };
      case 'HIPAA':
        return {
          '164.308(a)(1)(ii)(D) - Information System Activity Review': [
            'user_action',
            'security_policy_change',
          ],
          '164.312(a)(2)(i) - Unique User Identification': ['user_action'],
        };
      case 'ISO27001':
        return {
          'A.12.4.1 - Event Logging': ['user_action', 'security_policy_change'],
          'A.16.1.4 - Assessment and Decision': ['incident_resolution'],
        };
      default:
        return {};
    }
  }

  /// Calculate compliance status
  String _calculateComplianceStatus(Map<String, dynamic> metrics) {
    final totalEvents = metrics['total_events'] as int;
    if (totalEvents == 0) return 'No Data';

    final criticalFindings = metrics['critical_findings'] as int;
    if (criticalFindings > 0) return 'Non-Compliant';

    return 'Compliant';
  }

  /// Calculate report hash
  String _calculateReportHash(Map<String, dynamic> reportData) {
    final dataString = jsonEncode(reportData);
    final bytes = utf8.encode(dataString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate digital signature
  Future<void> _generateDigitalSignature(
    String reportId,
    String reportHash,
  ) async {
    try {
      // In production, use RSA key pair for signing
      // For now, store hash as signature
      await _client.from('report_signatures').insert({
        'report_id': reportId,
        'signature_hash': reportHash,
        'signed_by': _auth.currentUser!.id,
        'verification_method': 'SHA256',
      });
    } catch (e) {
      debugPrint('Generate digital signature error: $e');
    }
  }

  /// Schedule compliance report
  Future<String?> scheduleComplianceReport({
    required String reportType,
    required String frequency,
    required List<String> recipients,
    Map<String, dynamic>? reportScope,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final nextRunDate = _calculateNextRunDate(frequency);

      final response = await _client
          .from('compliance_report_schedules')
          .insert({
            'report_type': reportType,
            'frequency': frequency,
            'recipients': recipients,
            'report_scope': reportScope ?? {},
            'next_run_date': nextRunDate.toIso8601String(),
            'enabled': true,
            'created_by': _auth.currentUser!.id,
          })
          .select()
          .single();

      return response['schedule_id'] as String?;
    } catch (e) {
      debugPrint('Schedule compliance report error: $e');
      return null;
    }
  }

  /// Calculate next run date based on frequency
  DateTime _calculateNextRunDate(String frequency) {
    final now = DateTime.now();
    switch (frequency) {
      case 'weekly':
        return now.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(now.year, now.month + 1, now.day);
      case 'quarterly':
        return DateTime(now.year, now.month + 3, now.day);
      case 'annually':
        return DateTime(now.year + 1, now.month, now.day);
      default:
        return now.add(const Duration(days: 30));
    }
  }

  /// Send compliance report via email
  Future<bool> sendComplianceReport({
    required String reportId,
    required List<String> recipients,
  }) async {
    try {
      // Get report data
      final report = await _client
          .from('generated_compliance_reports')
          .select()
          .eq('report_id', reportId)
          .single();

      // Call edge function to send email
      final response = await _client.functions.invoke(
        'send-compliance-report',
        body: {
          'report_id': reportId,
          'report_type': report['report_type'],
          'report_data': report['report_data'],
          'recipients': recipients,
        },
      );

      return response.status == 200;
    } catch (e) {
      debugPrint('Send compliance report error: $e');
      return false;
    }
  }

  /// Get generated reports
  Future<List<Map<String, dynamic>>> getGeneratedReports({
    String? reportType,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('generated_compliance_reports').select();

      if (reportType != null) {
        query = query.eq('report_type', reportType);
      }

      final response = await query
          .order('generated_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get generated reports error: $e');
      return [];
    }
  }

  /// Get scheduled reports
  Future<List<Map<String, dynamic>>> getScheduledReports() async {
    try {
      final response = await _client
          .from('compliance_report_schedules')
          .select()
          .order('next_run_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get scheduled reports error: $e');
      return [];
    }
  }

  /// Verify report signature
  Future<bool> verifyReportSignature(String reportId) async {
    try {
      final report = await _client
          .from('generated_compliance_reports')
          .select()
          .eq('report_id', reportId)
          .single();

      final signature = await _client
          .from('report_signatures')
          .select()
          .eq('report_id', reportId)
          .single();

      final storedHash = report['report_hash'] as String;
      final signatureHash = signature['signature_hash'] as String;

      return storedHash == signatureHash;
    } catch (e) {
      debugPrint('Verify report signature error: $e');
      return false;
    }
  }
}
