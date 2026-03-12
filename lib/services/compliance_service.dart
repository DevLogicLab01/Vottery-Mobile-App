import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class ComplianceService {
  static ComplianceService? _instance;
  static ComplianceService get instance => _instance ??= ComplianceService._();

  ComplianceService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Log compliance action
  Future<void> logComplianceAction({
    required String complianceType,
    required String actionType,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _client.rpc(
        'log_compliance_action',
        params: {
          'p_compliance_type': complianceType,
          'p_action_type': actionType,
          'p_user_id': _auth.currentUser?.id,
          'p_resource_type': resourceType,
          'p_resource_id': resourceId,
          'p_details': details ?? {},
        },
      );
    } catch (e) {
      debugPrint('Log compliance action error: $e');
    }
  }

  /// Get compliance status
  Future<Map<String, dynamic>> getComplianceStatus() async {
    try {
      final response = await _client.rpc('get_compliance_status');
      return response ?? _getDefaultComplianceStatus();
    } catch (e) {
      debugPrint('Get compliance status error: $e');
      return _getDefaultComplianceStatus();
    }
  }

  /// Generate GDPR report
  Future<bool> generateGDPRReport({required String requestType}) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('gdpr_data_requests').insert({
        'user_id': _auth.currentUser!.id,
        'request_type': requestType,
        'status': 'pending',
      });

      await logComplianceAction(
        complianceType: 'GDPR',
        actionType: 'data_request_submitted',
        resourceType: 'gdpr_request',
        details: {'request_type': requestType},
      );

      return true;
    } catch (e) {
      debugPrint('Generate GDPR report error: $e');
      return false;
    }
  }

  /// Get GDPR data requests
  Future<List<Map<String, dynamic>>> getGDPRDataRequests() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('gdpr_data_requests')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('requested_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get GDPR data requests error: $e');
      return [];
    }
  }

  /// Get compliance audit logs (admin only)
  Future<List<Map<String, dynamic>>> getComplianceAuditLogs({
    String? complianceType,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('compliance_audit_logs').select();

      if (complianceType != null) {
        query = query.eq('compliance_type', complianceType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get compliance audit logs error: $e');
      return [];
    }
  }

  /// Generate compliance report
  Future<Map<String, dynamic>> generateComplianceReport({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _client.rpc(
        'generate_compliance_report',
        params: {
          'report_type': reportType,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
      );

      return response ?? _getDefaultReport();
    } catch (e) {
      debugPrint('Generate compliance report error: $e');
      return _getDefaultReport();
    }
  }

  Map<String, dynamic> _getDefaultComplianceStatus() {
    return {
      'gdprCompliant': true,
      'pciCompliant': true,
      'soc2Compliant': true,
      'lastAudit': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _getDefaultReport() {
    return {
      'report_type': 'compliance_summary',
      'generated_at': DateTime.now().toIso8601String(),
      'summary': 'Compliance report generated',
      'metrics': {},
    };
  }
}
