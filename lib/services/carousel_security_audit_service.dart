import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class CarouselSecurityAuditService {
  static CarouselSecurityAuditService? _instance;
  static CarouselSecurityAuditService get instance =>
      _instance ??= CarouselSecurityAuditService._();

  CarouselSecurityAuditService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // 12 carousel systems being monitored
  static const List<String> carouselSystems = [
    'OpenAI Ranking',
    'Real-Time Monitoring',
    'Fraud Detection',
    'Feed Orchestration',
    'ROI Analytics',
    'Creator Studio',
    'Marketplace',
    'Claude Agent',
    'Community Hub',
    'Revenue Forecasting',
    'Perplexity Intelligence',
    'Health & Scaling',
  ];

  /// Get all compliance policies
  Future<List<Map<String, dynamic>>> getAllPolicies() async {
    try {
      final response = await _client
          .from('carousel_compliance_policies')
          .select()
          .eq('is_active', true)
          .order('policy_category')
          .order('policy_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get all policies error: $e');
      return [];
    }
  }

  /// Get all active violations
  Future<List<Map<String, dynamic>>> getActiveViolations({
    String? systemName,
    String? severity,
  }) async {
    try {
      var query = _client
          .from('carousel_compliance_violations')
          .select(
            '*, carousel_compliance_policies(policy_name, policy_category)',
          )
          .inFilter('status', ['open', 'investigating']);

      if (systemName != null) {
        query = query.eq('system_name', systemName);
      }

      if (severity != null) {
        query = query.eq('severity', severity);
      }

      final response = await query.order('detected_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get active violations error: $e');
      return [];
    }
  }

  /// Report violation
  Future<String?> reportViolation({
    required String systemName,
    required String violationType,
    required String severity,
    required String description,
    String? policyId,
    Map<String, dynamic>? evidence,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('carousel_compliance_violations')
          .insert({
            'policy_id': policyId,
            'system_name': systemName,
            'violation_type': violationType,
            'severity': severity,
            'description': description,
            'evidence': evidence ?? {},
            'detection_method': 'manual',
            'detected_by': _auth.currentUser!.id,
            'status': 'open',
          })
          .select('violation_id')
          .single();

      // Recalculate compliance score
      await calculateComplianceScore(systemName);

      return response['violation_id'] as String?;
    } catch (e) {
      debugPrint('Report violation error: $e');
      return null;
    }
  }

  /// Update violation status
  Future<bool> updateViolationStatus({
    required String violationId,
    required String status,
    String? remediationNotes,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final updates = <String, dynamic>{'status': status};

      if (status == 'remediated') {
        updates['remediated_at'] = DateTime.now().toIso8601String();
      }

      if (remediationNotes != null) {
        updates['remediation_notes'] = remediationNotes;
      }

      await _client
          .from('carousel_compliance_violations')
          .update(updates)
          .eq('violation_id', violationId);

      // Get system name to recalculate score
      final violation = await _client
          .from('carousel_compliance_violations')
          .select('system_name')
          .eq('violation_id', violationId)
          .single();

      await calculateComplianceScore(violation['system_name']);

      return true;
    } catch (e) {
      debugPrint('Update violation status error: $e');
      return false;
    }
  }

  /// Calculate compliance score for system
  Future<int> calculateComplianceScore(String systemName) async {
    try {
      final score = await _client.rpc(
        'calculate_carousel_compliance_score',
        params: {'p_system_name': systemName},
      );

      // Determine risk level based on score
      String riskLevel;
      if (score >= 90) {
        riskLevel = 'low';
      } else if (score >= 70) {
        riskLevel = 'medium';
      } else if (score >= 50) {
        riskLevel = 'high';
      } else {
        riskLevel = 'critical';
      }

      // Get violation count
      final violations = await _client
          .from('carousel_compliance_violations')
          .select('violation_id')
          .eq('system_name', systemName)
          .inFilter('status', ['open', 'investigating']);

      final violationCount = violations.length;

      // Store score
      await _client.from('carousel_compliance_scores').insert({
        'system_name': systemName,
        'compliance_score': score,
        'violation_count': violationCount,
        'risk_level': riskLevel,
      });

      return score as int;
    } catch (e) {
      debugPrint('Calculate compliance score error: $e');
      return 0;
    }
  }

  /// Get compliance scores for all systems
  Future<Map<String, Map<String, dynamic>>> getAllSystemScores() async {
    try {
      final scores = <String, Map<String, dynamic>>{};

      for (final system in carouselSystems) {
        final latestScore = await _client
            .from('carousel_compliance_scores')
            .select()
            .eq('system_name', system)
            .order('calculated_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (latestScore != null) {
          scores[system] = latestScore;
        } else {
          // Calculate if no score exists
          final score = await calculateComplianceScore(system);
          scores[system] = {
            'system_name': system,
            'compliance_score': score,
            'violation_count': 0,
            'risk_level': 'low',
            'calculated_at': DateTime.now().toIso8601String(),
          };
        }
      }

      return scores;
    } catch (e) {
      debugPrint('Get all system scores error: $e');
      return {};
    }
  }

  /// Get overall platform compliance score
  Future<double> getOverallComplianceScore() async {
    try {
      final systemScores = await getAllSystemScores();
      if (systemScores.isEmpty) return 0;

      final totalScore = systemScores.values.fold<int>(
        0,
        (sum, score) => sum + (score['compliance_score'] as int),
      );

      return totalScore / systemScores.length;
    } catch (e) {
      debugPrint('Get overall compliance score error: $e');
      return 0;
    }
  }

  /// Log remediation action
  Future<bool> logRemediationAction({
    required String violationId,
    required String actionType,
    required String actionDescription,
    required bool automated,
    required String result,
    String? resultDetails,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('carousel_remediation_actions').insert({
        'violation_id': violationId,
        'action_type': actionType,
        'action_description': actionDescription,
        'automated': automated,
        'executed_by': _auth.currentUser!.id,
        'result': result,
        'result_details': resultDetails,
      });

      return true;
    } catch (e) {
      debugPrint('Log remediation action error: $e');
      return false;
    }
  }

  /// Get remediation history for violation
  Future<List<Map<String, dynamic>>> getRemediationHistory(
    String violationId,
  ) async {
    try {
      final response = await _client
          .from('carousel_remediation_actions')
          .select('*, user_profiles!executed_by(full_name)')
          .eq('violation_id', violationId)
          .order('executed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get remediation history error: $e');
      return [];
    }
  }

  /// Get compliance trends (last 30 days)
  Future<List<Map<String, dynamic>>> getComplianceTrends({
    String? systemName,
  }) async {
    try {
      var query = _client
          .from('carousel_compliance_scores')
          .select()
          .gte(
            'calculated_at',
            DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          );

      if (systemName != null) {
        query = query.eq('system_name', systemName);
      }

      final response = await query.order('calculated_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get compliance trends error: $e');
      return [];
    }
  }

  /// Run automated compliance check
  Future<void> runAutomatedComplianceCheck() async {
    try {
      // This would be called by a scheduled job
      // For each system, run compliance checks
      for (final system in carouselSystems) {
        await _runSystemComplianceCheck(system);
      }
    } catch (e) {
      debugPrint('Run automated compliance check error: $e');
    }
  }

  /// Run compliance check for specific system
  Future<void> _runSystemComplianceCheck(String systemName) async {
    try {
      // Placeholder for automated checks
      // In production, this would:
      // 1. Analyze system logs
      // 2. Check database records
      // 3. Verify API calls
      // 4. Flag violations

      // For now, just recalculate score
      await calculateComplianceScore(systemName);
    } catch (e) {
      debugPrint('Run system compliance check error: $e');
    }
  }

  /// Get compliance dashboard summary
  Future<Map<String, dynamic>> getComplianceDashboardSummary() async {
    try {
      final overallScore = await getOverallComplianceScore();
      final activeViolations = await getActiveViolations();
      final systemScores = await getAllSystemScores();

      // Count violations by severity
      final violationsBySeverity = <String, int>{
        'critical': 0,
        'high': 0,
        'medium': 0,
        'low': 0,
      };

      for (final violation in activeViolations) {
        final severity = violation['severity'] as String;
        violationsBySeverity[severity] =
            (violationsBySeverity[severity] ?? 0) + 1;
      }

      // Identify systems with issues
      final systemsWithIssues = systemScores.entries
          .where((entry) => (entry.value['compliance_score'] as int) < 90)
          .map((entry) => entry.key)
          .toList();

      return {
        'overall_score': overallScore,
        'total_active_violations': activeViolations.length,
        'violations_by_severity': violationsBySeverity,
        'systems_with_issues': systemsWithIssues,
        'system_scores': systemScores,
        'compliance_status': overallScore >= 90 ? 'Compliant' : 'Non-Compliant',
      };
    } catch (e) {
      debugPrint('Get compliance dashboard summary error: $e');
      return {};
    }
  }

  /// Stream violations for real-time updates
  Stream<List<Map<String, dynamic>>> streamViolations() {
    return _client
        .from('carousel_compliance_violations')
        .stream(primaryKey: ['violation_id'])
        .inFilter('status', ['open', 'investigating'])
        .order('detected_at', ascending: false);
  }
}
