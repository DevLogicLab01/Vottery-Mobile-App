import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

/// SMS Compliance Manager Service
/// Implements GDPR/TCPA compliance tracking with consent management,
/// opt-out lists, retention policies, and automated compliance reporting
class SMSComplianceService {
  static SMSComplianceService? _instance;
  static SMSComplianceService get instance =>
      _instance ??= SMSComplianceService._();

  SMSComplianceService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // =====================================================
  // CONSENT MANAGEMENT
  // =====================================================

  /// Grant consent for SMS communications
  Future<Map<String, dynamic>?> grantConsent({
    required String phoneNumber,
    required String consentType,
    required String consentMethod,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final response = await _client
          .from('sms_consent_preferences')
          .insert({
            'user_id': _auth.currentUser!.id,
            'phone_number': phoneNumber,
            'consent_type': consentType,
            'consent_status': 'opted_in',
            'consent_method': consentMethod,
            'ip_address': ipAddress,
            'user_agent': userAgent,
          })
          .select()
          .single();

      // Log compliance event
      await logComplianceEvent(
        eventType: 'consent_granted',
        eventDetails: {
          'consent_type': consentType,
          'consent_method': consentMethod,
          'phone_number': phoneNumber,
        },
        ipAddress: ipAddress,
      );

      return response;
    } catch (e) {
      debugPrint('Grant consent error: $e');
      return null;
    }
  }

  /// Revoke consent (opt-out)
  Future<bool> revokeConsent({
    required String consentId,
    String? reason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Get consent record
      final consent = await _client
          .from('sms_consent_preferences')
          .select()
          .eq('consent_id', consentId)
          .eq('user_id', _auth.currentUser!.id)
          .single();

      // Update consent status
      await _client
          .from('sms_consent_preferences')
          .update({
            'consent_status': 'opted_out',
            'revoked_at': DateTime.now().toIso8601String(),
          })
          .eq('consent_id', consentId);

      // Add to suppression list
      await addToSuppressionList(
        phoneNumber: consent['phone_number'],
        reason: 'opted_out',
        notes: reason,
      );

      // Log compliance event
      await logComplianceEvent(
        eventType: 'consent_revoked',
        eventDetails: {
          'consent_id': consentId,
          'consent_type': consent['consent_type'],
          'reason': reason,
        },
      );

      return true;
    } catch (e) {
      debugPrint('Revoke consent error: $e');
      return false;
    }
  }

  /// Get user consent preferences
  Future<List<Map<String, dynamic>>> getUserConsents() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('sms_consent_preferences')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('consent_timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user consents error: $e');
      return [];
    }
  }

  /// Check if user has consent for specific type
  Future<bool> hasConsent({
    required String phoneNumber,
    required String consentType,
  }) async {
    try {
      final response = await _client
          .from('sms_consent_preferences')
          .select()
          .eq('phone_number', phoneNumber)
          .eq('consent_type', consentType)
          .eq('consent_status', 'opted_in')
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Check consent error: $e');
      return false;
    }
  }

  // =====================================================
  // SUPPRESSION LIST MANAGEMENT
  // =====================================================

  /// Add phone number to suppression list
  Future<bool> addToSuppressionList({
    required String phoneNumber,
    required String reason,
    String? notes,
  }) async {
    try {
      await _client.from('sms_suppression_list').upsert({
        'phone_number': phoneNumber,
        'suppression_reason': reason,
        'notes': notes,
      });

      // Log compliance event
      await logComplianceEvent(
        eventType: 'phone_suppressed',
        eventDetails: {'phone_number': phoneNumber, 'reason': reason},
      );

      return true;
    } catch (e) {
      debugPrint('Add to suppression list error: $e');
      return false;
    }
  }

  /// Remove phone number from suppression list
  Future<bool> removeFromSuppressionList(String phoneNumber) async {
    try {
      await _client
          .from('sms_suppression_list')
          .delete()
          .eq('phone_number', phoneNumber);

      // Log compliance event
      await logComplianceEvent(
        eventType: 'phone_unsuppressed',
        eventDetails: {'phone_number': phoneNumber},
      );

      return true;
    } catch (e) {
      debugPrint('Remove from suppression list error: $e');
      return false;
    }
  }

  /// Check if phone number is suppressed
  Future<bool> isPhoneSuppressed(String phoneNumber) async {
    try {
      final response = await _client.rpc(
        'is_phone_suppressed',
        params: {'p_phone_number': phoneNumber},
      );

      return response == true;
    } catch (e) {
      debugPrint('Check phone suppressed error: $e');
      return false;
    }
  }

  /// Get suppression list
  Future<List<Map<String, dynamic>>> getSuppressionList({
    String? reason,
    int limit = 100,
  }) async {
    try {
      var query = _client.from('sms_suppression_list').select();

      if (reason != null) {
        query = query.eq('suppression_reason', reason);
      }

      final response = await query
          .order('suppressed_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get suppression list error: $e');
      return [];
    }
  }

  /// Bulk import suppression list
  Future<int> bulkImportSuppressionList(
    List<Map<String, dynamic>> phoneNumbers,
  ) async {
    try {
      await _client.from('sms_suppression_list').upsert(phoneNumbers);

      // Log compliance event
      await logComplianceEvent(
        eventType: 'bulk_suppression_import',
        eventDetails: {'count': phoneNumbers.length},
      );

      return phoneNumbers.length;
    } catch (e) {
      debugPrint('Bulk import suppression list error: $e');
      return 0;
    }
  }

  // =====================================================
  // COMPLIANCE AUDIT & REPORTING
  // =====================================================

  /// Log compliance event
  Future<void> logComplianceEvent({
    required String eventType,
    Map<String, dynamic>? eventDetails,
    String? ipAddress,
  }) async {
    try {
      await _client.rpc(
        'log_compliance_event',
        params: {
          'p_event_type': eventType,
          'p_user_id': _auth.currentUser?.id,
          'p_admin_id': null,
          'p_event_details': eventDetails ?? {},
          'p_ip_address': ipAddress,
        },
      );
    } catch (e) {
      debugPrint('Log compliance event error: $e');
    }
  }

  /// Get compliance audit logs
  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? eventType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _client.from('sms_compliance_audit').select();

      if (eventType != null) {
        query = query.eq('event_type', eventType);
      }

      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }

      final response = await query
          .order('timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get audit logs error: $e');
      return [];
    }
  }

  /// Generate compliance report
  Future<Map<String, dynamic>> generateComplianceReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Get consent metrics
      final consents = await _client
          .from('sms_consent_preferences')
          .select()
          .gte('consent_timestamp', start.toIso8601String())
          .lte('consent_timestamp', end.toIso8601String());

      final optIns = consents
          .where((c) => c['consent_status'] == 'opted_in')
          .length;
      final optOuts = consents
          .where((c) => c['consent_status'] == 'opted_out')
          .length;

      // Get suppression metrics
      final suppressions = await _client
          .from('sms_suppression_list')
          .select()
          .gte('suppressed_at', start.toIso8601String())
          .lte('suppressed_at', end.toIso8601String());

      // Get audit events
      final auditEvents = await getAuditLogs(
        startDate: start,
        endDate: end,
        limit: 1000,
      );

      return {
        'report_period': {
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
        'consent_metrics': {
          'total_consents': consents.length,
          'opt_ins': optIns,
          'opt_outs': optOuts,
          'opt_in_rate': consents.isNotEmpty
              ? (optIns / consents.length * 100).toStringAsFixed(2)
              : '0.00',
          'opt_out_rate': consents.isNotEmpty
              ? (optOuts / consents.length * 100).toStringAsFixed(2)
              : '0.00',
        },
        'suppression_metrics': {
          'total_suppressions': suppressions.length,
          'by_reason': _groupByReason(suppressions),
        },
        'audit_metrics': {
          'total_events': auditEvents.length,
          'by_type': _groupByEventType(auditEvents),
        },
        'compliance_score': _calculateComplianceScore(
          optIns,
          optOuts,
          suppressions.length,
        ),
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Generate compliance report error: $e');
      return {};
    }
  }

  /// Export compliance report as CSV
  Future<String> exportComplianceReportCSV({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final report = await generateComplianceReport(
        startDate: startDate,
        endDate: endDate,
      );

      final csv = StringBuffer();
      csv.writeln('SMS Compliance Report');
      csv.writeln('Generated: ${report['generated_at']}');
      csv.writeln('');
      csv.writeln(
        'Period: ${report['report_period']['start_date']} to ${report['report_period']['end_date']}',
      );
      csv.writeln('');
      csv.writeln('Consent Metrics');
      csv.writeln(
        'Total Consents,${report['consent_metrics']['total_consents']}',
      );
      csv.writeln('Opt-Ins,${report['consent_metrics']['opt_ins']}');
      csv.writeln('Opt-Outs,${report['consent_metrics']['opt_outs']}');
      csv.writeln('Opt-In Rate,${report['consent_metrics']['opt_in_rate']}%');
      csv.writeln('Opt-Out Rate,${report['consent_metrics']['opt_out_rate']}%');
      csv.writeln('');
      csv.writeln('Suppression Metrics');
      csv.writeln(
        'Total Suppressions,${report['suppression_metrics']['total_suppressions']}',
      );
      csv.writeln('');
      csv.writeln('Compliance Score,${report['compliance_score']}');

      return csv.toString();
    } catch (e) {
      debugPrint('Export compliance report CSV error: $e');
      return '';
    }
  }

  // =====================================================
  // GDPR/TCPA COMPLIANCE FEATURES
  // =====================================================

  /// Handle GDPR data access request
  Future<Map<String, dynamic>> handleDataAccessRequest() async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final userId = _auth.currentUser!.id;

      // Compile all SMS-related data
      final consents = await getUserConsents();
      final auditLogs = await _client
          .from('sms_compliance_audit')
          .select()
          .eq('user_id', userId);

      // Log data access request
      await logComplianceEvent(
        eventType: 'data_access_request',
        eventDetails: {'user_id': userId},
      );

      return {
        'user_id': userId,
        'consents': consents,
        'audit_logs': auditLogs,
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Handle data access request error: $e');
      return {};
    }
  }

  /// Handle right to be forgotten (data deletion)
  Future<bool> handleDataDeletionRequest() async {
    try {
      if (!_auth.isAuthenticated) return false;

      final userId = _auth.currentUser!.id;

      // Anonymize consent records
      await _client
          .from('sms_consent_preferences')
          .update({
            'phone_number': 'REDACTED',
            'ip_address': null,
            'user_agent': null,
          })
          .eq('user_id', userId);

      // Log data deletion
      await logComplianceEvent(
        eventType: 'data_deletion_request',
        eventDetails: {'user_id': userId},
      );

      return true;
    } catch (e) {
      debugPrint('Handle data deletion request error: $e');
      return false;
    }
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  Map<String, int> _groupByReason(List<dynamic> suppressions) {
    final grouped = <String, int>{};
    for (final suppression in suppressions) {
      final reason = suppression['suppression_reason'] as String;
      grouped[reason] = (grouped[reason] ?? 0) + 1;
    }
    return grouped;
  }

  Map<String, int> _groupByEventType(List<Map<String, dynamic>> events) {
    final grouped = <String, int>{};
    for (final event in events) {
      final type = event['event_type'] as String;
      grouped[type] = (grouped[type] ?? 0) + 1;
    }
    return grouped;
  }

  int _calculateComplianceScore(int optIns, int optOuts, int suppressions) {
    if (optIns + optOuts == 0) return 100;

    final optInRate = optIns / (optIns + optOuts);
    final suppressionPenalty = suppressions * 0.01;

    final score = (optInRate * 100 - suppressionPenalty).clamp(0, 100);
    return score.round();
  }
}
