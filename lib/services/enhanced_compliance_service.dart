import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class EnhancedComplianceService {
  static EnhancedComplianceService? _instance;
  static EnhancedComplianceService get instance =>
      _instance ??= EnhancedComplianceService._();

  EnhancedComplianceService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Generate multi-jurisdiction compliance report
  Future<String?> generateComplianceReport({
    required String jurisdiction,
    required String reportType,
    String? userId,
  }) async {
    try {
      final response = await _client.rpc(
        'generate_compliance_report',
        params: {
          'p_jurisdiction': jurisdiction,
          'p_report_type': reportType,
          'p_user_id': userId,
        },
      );

      return response?.toString();
    } catch (e) {
      debugPrint('Generate compliance report error: $e');
      return null;
    }
  }

  /// Get compliance reports
  Future<List<Map<String, dynamic>>> getComplianceReports({
    String? jurisdiction,
    String? status,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('compliance_reports').select();

      if (jurisdiction != null) {
        query = query.eq('jurisdiction', jurisdiction);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('generated_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get compliance reports error: $e');
      return [];
    }
  }

  /// Get compliance status by jurisdiction
  Future<Map<String, dynamic>> getComplianceStatusByJurisdiction(
    String jurisdiction,
  ) async {
    try {
      final response = await _client.rpc(
        'get_compliance_status_by_jurisdiction',
        params: {'p_jurisdiction': jurisdiction},
      );

      if (response != null && response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response[0]);
      }

      return _getDefaultJurisdictionStatus();
    } catch (e) {
      debugPrint('Get compliance status by jurisdiction error: $e');
      return _getDefaultJurisdictionStatus();
    }
  }

  /// Get data access audit trail
  Future<List<Map<String, dynamic>>> getDataAccessAuditTrail({
    String? jurisdiction,
    int limit = 100,
  }) async {
    try {
      var query = _client.from('data_access_audit_trail').select();

      if (jurisdiction != null) {
        query = query.eq('jurisdiction', jurisdiction);
      }

      final response = await query
          .order('timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get data access audit trail error: $e');
      return [];
    }
  }

  /// Log data access event
  Future<void> logDataAccess({
    required String actionType,
    required String ipAddress,
    required List<Map<String, dynamic>> affectedRecords,
    String? jurisdiction,
  }) async {
    try {
      await _client.rpc(
        'log_data_access',
        params: {
          'p_action_type': actionType,
          'p_ip_address': ipAddress,
          'p_affected_records': affectedRecords,
          'p_jurisdiction': jurisdiction,
        },
      );
    } catch (e) {
      debugPrint('Log data access error: $e');
    }
  }

  /// Get scheduled compliance deliveries
  Future<List<Map<String, dynamic>>> getScheduledDeliveries() async {
    try {
      final response = await _client
          .from('scheduled_compliance_deliveries')
          .select()
          .eq('is_active', true)
          .order('next_scheduled_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get scheduled deliveries error: $e');
      return [];
    }
  }

  /// Get data retention policies
  Future<List<Map<String, dynamic>>> getDataRetentionPolicies() async {
    try {
      final response = await _client
          .from('data_retention_policies')
          .select()
          .order('data_category');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get data retention policies error: $e');
      return [];
    }
  }

  /// Request automated data export
  Future<bool> requestDataExport({
    required String jurisdiction,
    String? userId,
  }) async {
    try {
      final reportId = await generateComplianceReport(
        jurisdiction: jurisdiction,
        reportType: 'data_export',
        userId: userId,
      );

      return reportId != null;
    } catch (e) {
      debugPrint('Request data export error: $e');
      return false;
    }
  }

  /// Request right to erasure
  Future<bool> requestRightToErasure({
    required String jurisdiction,
    String? userId,
  }) async {
    try {
      final reportId = await generateComplianceReport(
        jurisdiction: jurisdiction,
        reportType: 'right_to_erasure',
        userId: userId,
      );

      return reportId != null;
    } catch (e) {
      debugPrint('Request right to erasure error: $e');
      return false;
    }
  }

  /// Send compliance report via email (calls Resend edge function)
  Future<bool> sendComplianceReportEmail({
    required String reportId,
    required String recipientEmail,
    required String jurisdiction,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'send-compliance-report',
        body: {
          'report_id': reportId,
          'recipient_email': recipientEmail,
          'jurisdiction': jurisdiction,
        },
      );

      return response.status == 200;
    } catch (e) {
      debugPrint('Send compliance report email error: $e');
      return false;
    }
  }

  /// Get compliance health score (0-100)
  Future<double> getComplianceHealthScore() async {
    try {
      final jurisdictions = ['GDPR', 'CCPA', 'CCRA'];
      double totalScore = 0.0;

      for (final jurisdiction in jurisdictions) {
        final status = await getComplianceStatusByJurisdiction(jurisdiction);
        totalScore += (status['compliance_score'] ?? 0.0) as double;
      }

      return totalScore / jurisdictions.length;
    } catch (e) {
      debugPrint('Get compliance health score error: $e');
      return 0.0;
    }
  }

  Map<String, dynamic> _getDefaultJurisdictionStatus() {
    return {
      'total_reports': 0,
      'pending_reports': 0,
      'completed_reports': 0,
      'failed_reports': 0,
      'compliance_score': 100.0,
    };
  }
}
