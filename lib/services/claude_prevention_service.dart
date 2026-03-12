import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import './supabase_service.dart';
import './claude_service.dart';
import './datadog_tracing_service.dart';
import './audit_log_service.dart';

class ClaudePreventionService {
  static ClaudePreventionService? _instance;
  static ClaudePreventionService get instance =>
      _instance ??= ClaudePreventionService._();

  ClaudePreventionService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  ClaudeService get _claude => ClaudeService.instance;

  final DatadogTracingService _tracing = DatadogTracingService.instance;
  final AuditLogService _auditLog = AuditLogService.instance;

  static const String claudeModel = 'claude-3-opus-20240229';

  /// Analyze attack patterns and generate prevention rules
  Future<Map<String, dynamic>> analyzeAttackPatterns({
    required List<Map<String, dynamic>> detectedAttacks,
  }) async {
    // Start Datadog span
    final spanId = await _tracing.startSpan(
      'claude_rule_generation',
      resourceName: 'analyzeAttackPatterns',
      tags: {
        'claude.model': claudeModel,
        'claude.attack_pattern_count': detectedAttacks.length.toString(),
        'claude.operation': 'analyze_attack_patterns',
      },
    );

    final stopwatch = Stopwatch()..start();

    try {
      if (detectedAttacks.isEmpty) {
        await _tracing.finishSpan(spanId, error: 'No attacks to analyze');
        return {'success': false, 'error': 'No attacks to analyze'};
      }

      // Construct Claude prompt
      final prompt = _buildAttackAnalysisPrompt(detectedAttacks);

      final response = await _claude.callClaudeAPI(prompt);

      final result = _parseAttackAnalysis(response);

      // Validate generated rules
      final validatedRules = await _validateRules(result['generated_rules']);

      stopwatch.stop();

      // Log audit event for policy generation
      await _auditLog.logAuditEvent(
        eventType: 'security_policy_change',
        actionType: 'create',
        entityType: 'prevention_policy',
        newValue: {
          'generated_rules': validatedRules,
          'attack_patterns': result['attack_patterns'],
        },
        reason: 'Automated prevention rule generation from detected attacks',
        metadata: {
          'attack_count': detectedAttacks.length,
          'rules_generated': validatedRules.length,
        },
      );

      // Finish span successfully
      await _tracing.finishSpan(
        spanId,
        tags: {
          'claude.success': 'true',
          'claude.rules_generated': validatedRules.length.toString(),
        },
      );

      return {
        'success': true,
        'generated_rules': validatedRules,
        'attack_patterns': result['attack_patterns'],
      };
    } catch (e) {
      stopwatch.stop();

      // Finish span with error
      await _tracing.finishSpan(
        spanId,
        error: e.toString(),
        tags: {
          'claude.error': 'true',
          'claude.duration_ms': stopwatch.elapsedMilliseconds.toString(),
        },
      );

      debugPrint('Analyze attack patterns error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Generate compliance-based policies
  Future<Map<String, dynamic>> generateCompliancePolicies({
    required List<String> regulations,
    required Map<String, dynamic> systemDescription,
  }) async {
    try {
      final prompt =
          '''
Generate security policies to ensure compliance with these requirements: ${regulations.join(', ')}.

Analyze our current system: ${jsonEncode(systemDescription)}

Generate policies to fill compliance gaps.

Respond in JSON format:
{
  "compliance_policies": [
    {
      "regulation_reference": "",
      "policy_description": "",
      "implementation_steps": [],
      "compliance_verification_method": ""
    }
  ]
}
''';

      final response = await _claude.callClaudeAPI(prompt);

      final result = _parseCompliancePolicies(response);

      // Store compliance policies
      for (final policy in result['compliance_policies']) {
        await _storeCompliancePolicy(policy);
      }

      return {'success': true, 'policies': result['compliance_policies']};
    } catch (e) {
      debugPrint('Generate compliance policies error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test rules against historical data
  Future<Map<String, dynamic>> testRules({
    required List<Map<String, dynamic>> rules,
  }) async {
    try {
      final results = <Map<String, dynamic>>[];

      for (final rule in rules) {
        final testResult = await _simulateRuleApplication(rule);
        results.add(testResult);
      }

      return {'success': true, 'test_results': results};
    } catch (e) {
      debugPrint('Test rules error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Apply approved rules
  Future<bool> applyRule(Map<String, dynamic> rule) async {
    try {
      await _client.from('active_security_policies').insert({
        'rule_definition': rule,
        'policy_status': 'enabled',
        'created_by': 'claude_ai',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Log policy application
      await _client.from('policy_audit_log').insert({
        'action': 'rule_applied',
        'rule_definition': rule,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Apply rule error: $e');
      return false;
    }
  }

  /// Get active security policies
  Future<List<Map<String, dynamic>>> getActivePolicies() async {
    try {
      final response = await _client
          .from('active_security_policies')
          .select()
          .eq('policy_status', 'enabled')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get active policies error: $e');
      return [];
    }
  }

  /// Get pending rules for review
  Future<List<Map<String, dynamic>>> getPendingRules() async {
    try {
      final response = await _client
          .from('pending_security_rules')
          .select()
          .eq('review_status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get pending rules error: $e');
      return [];
    }
  }

  /// Update rule status
  Future<bool> updateRuleStatus({
    required String ruleId,
    required String status,
  }) async {
    try {
      await _client
          .from('active_security_policies')
          .update({'policy_status': status})
          .eq('id', ruleId);

      return true;
    } catch (e) {
      debugPrint('Update rule status error: $e');
      return false;
    }
  }

  // Private helper methods

  String _buildAttackAnalysisPrompt(List<Map<String, dynamic>> attacks) {
    return '''
You are a cybersecurity policy expert. Analyze these attack patterns and generate preventive security policies to block similar attacks.

Attack Patterns:
${attacks.map((a) => '- Type: ${a['type']}, Success: ${a['success']}, Indicators: ${a['indicators']}').join('\n')}

Policies should be specific, actionable, and technically implementable.

Respond in JSON format:
{
  "attack_patterns": [
    {"pattern": "", "frequency": 0, "severity": "low|medium|high|critical"}
  ],
  "generated_rules": [
    {
      "rule_type": "rate_limit|ip_block|pattern_block|auth_requirement|input_validation",
      "rule_conditions": {},
      "rule_actions": {},
      "confidence_score": 0.0-1.0,
      "potential_false_positive_rate": 0.0-1.0,
      "implementation_complexity": "low|medium|high"
    }
  ]
}
''';
  }

  Map<String, dynamic> _parseAttackAnalysis(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return {'attack_patterns': [], 'generated_rules': []};
    }
  }

  Map<String, dynamic> _parseCompliancePolicies(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return {'compliance_policies': []};
    }
  }

  Future<List<Map<String, dynamic>>> _validateRules(List<dynamic> rules) async {
    final validatedRules = <Map<String, dynamic>>[];

    for (final rule in rules) {
      final ruleMap = rule as Map<String, dynamic>;

      // Check for conflicts with existing rules
      final hasConflict = await _checkRuleConflicts(ruleMap);
      if (hasConflict) {
        ruleMap['validation_status'] = 'conflict';
        continue;
      }

      // Check for impossible conditions
      if (_hasImpossibleConditions(ruleMap)) {
        ruleMap['validation_status'] = 'impossible';
        continue;
      }

      // Check if overly broad
      if (_isOverlyBroad(ruleMap)) {
        ruleMap['validation_status'] = 'too_broad';
        continue;
      }

      ruleMap['validation_status'] = 'valid';
      validatedRules.add(ruleMap);
    }

    return validatedRules;
  }

  Future<bool> _checkRuleConflicts(Map<String, dynamic> rule) async {
    try {
      final existingRules = await getActivePolicies();

      for (final existing in existingRules) {
        final existingDef = existing['rule_definition'] as Map<String, dynamic>;
        if (_rulesConflict(rule, existingDef)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  bool _rulesConflict(Map<String, dynamic> rule1, Map<String, dynamic> rule2) {
    // Simple conflict detection - same type and overlapping conditions
    return rule1['rule_type'] == rule2['rule_type'];
  }

  bool _hasImpossibleConditions(Map<String, dynamic> rule) {
    // Check for logically impossible conditions
    return false; // Simplified for now
  }

  bool _isOverlyBroad(Map<String, dynamic> rule) {
    // Check if rule would block too much legitimate traffic
    final fpRate = rule['potential_false_positive_rate'] as double? ?? 0.0;
    return fpRate > 0.1; // More than 10% false positive rate
  }

  Future<Map<String, dynamic>> _simulateRuleApplication(
    Map<String, dynamic> rule,
  ) async {
    try {
      // Get historical traffic logs
      final logs = await _getHistoricalLogs();

      int legitimateBlocked = 0;
      int attacksBlocked = 0;

      for (final log in logs) {
        final wouldBlock = _wouldRuleBlock(rule, log);
        if (wouldBlock) {
          if (log['is_attack'] == true) {
            attacksBlocked++;
          } else {
            legitimateBlocked++;
          }
        }
      }

      final totalSimulated = logs.length;
      final fpRate = totalSimulated > 0
          ? legitimateBlocked / totalSimulated
          : 0.0;
      final effectiveness = totalSimulated > 0
          ? attacksBlocked / totalSimulated
          : 0.0;

      return {
        'rule': rule,
        'total_traffic_simulated': totalSimulated,
        'legitimate_requests_blocked': legitimateBlocked,
        'attacks_blocked': attacksBlocked,
        'false_positive_rate': fpRate,
        'effectiveness_rate': effectiveness,
      };
    } catch (e) {
      debugPrint('Simulate rule application error: $e');
      return {'rule': rule, 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> _getHistoricalLogs() async {
    try {
      final response = await _client
          .from('request_logs')
          .select()
          .limit(1000)
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  bool _wouldRuleBlock(Map<String, dynamic> rule, Map<String, dynamic> log) {
    // Simplified rule matching logic
    final ruleType = rule['rule_type'] as String;

    switch (ruleType) {
      case 'rate_limit':
        return false; // Would need rate tracking
      case 'ip_block':
        final conditions = rule['rule_conditions'] as Map<String, dynamic>;
        return conditions['blocked_ips']?.contains(log['ip_address']) ?? false;
      case 'pattern_block':
        final conditions = rule['rule_conditions'] as Map<String, dynamic>;
        final pattern = conditions['pattern'] as String? ?? '';
        return log['request_path']?.contains(pattern) ?? false;
      default:
        return false;
    }
  }

  Future<void> _storeCompliancePolicy(Map<String, dynamic> policy) async {
    try {
      await _client.from('compliance_policies').insert({
        'regulation_reference': policy['regulation_reference'],
        'policy_description': policy['policy_description'],
        'implementation_steps': policy['implementation_steps'],
        'compliance_verification_method':
            policy['compliance_verification_method'],
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Store compliance policy error: $e');
    }
  }
}
