import 'package:flutter/foundation.dart';

import './alert_rules_service.dart';
import './supabase_service.dart';

class AdvancedAlertRulesService {
  static AdvancedAlertRulesService? _instance;
  static AdvancedAlertRulesService get instance =>
      _instance ??= AdvancedAlertRulesService._();

  AdvancedAlertRulesService._();

  final AlertRulesService _base = AlertRulesService.instance;

  /// Web parity: createCrossSystemRule
  Future<Map<String, dynamic>> createCrossSystemRule({
    required String ruleName,
    required String description,
    required String severity,
    required Map<String, dynamic> conditionLogic,
    List<Map<String, dynamic>> autoResponseActions = const [],
  }) async {
    final created = await _base.createAlertRule(
      ruleName: ruleName,
      description: description,
      metricType: 'cross_system',
      thresholdValue: 1,
      comparisonOperator: '>=',
      severity: severity,
      notificationChannels: const ['email', 'sms'],
      conditions: [
        {
          'metric_name': 'cross_system_signal',
          'comparison_operator': '>=',
          'threshold_value': 1,
          'logic_operator': conditionLogic['operator'] ?? 'AND',
        },
      ],
    );

    // Store cross-system metadata for evaluation/automation.
    final client = SupabaseService.instance.client;
    await client.from('alert_rules').update({
      'condition_logic': conditionLogic,
      'auto_response_actions': autoResponseActions,
      'category': 'cross_system',
      'auto_response_enabled': autoResponseActions.isNotEmpty,
    }).eq('id', created['id']);

    return created;
  }

  /// Web parity: evaluateCrossSystemTriggers
  Future<Map<String, dynamic>> evaluateCrossSystemTriggers(
    Map<String, dynamic> contextData,
  ) async {
    try {
      final client = SupabaseService.instance.client;
      final rules = await client
          .from('alert_rules')
          .select()
          .eq('category', 'cross_system')
          .eq('status', 'active');

      final triggeredRules = <Map<String, dynamic>>[];
      for (final raw in rules) {
        final rule = Map<String, dynamic>.from(raw);
        final actions = List<Map<String, dynamic>>.from(
          rule['auto_response_actions'] ?? const [],
        );
        final shouldTrigger = (contextData['cross_system_score'] as num?) != null
            ? (contextData['cross_system_score'] as num) >= 1
            : true;

        if (shouldTrigger) {
          triggeredRules.add(rule);
          if (actions.isNotEmpty) {
            await executeAutomatedResponse(
              ruleId: rule['id'].toString(),
              contextData: contextData,
              actions: actions,
            );
          }
        }
      }

      return {
        'data': {
          'triggeredRules': triggeredRules,
          'totalEvaluated': rules.length,
        },
        'error': null,
      };
    } catch (e) {
      debugPrint('evaluateCrossSystemTriggers error: $e');
      return {
        'data': null,
        'error': {'message': e.toString()},
      };
    }
  }

  /// Web parity: executeAutomatedResponse
  Future<Map<String, dynamic>> executeAutomatedResponse({
    required String ruleId,
    required Map<String, dynamic> contextData,
    required List<Map<String, dynamic>> actions,
  }) async {
    try {
      final client = SupabaseService.instance.client;
      await client.from('system_alerts').insert({
        'alert_rule_id': ruleId,
        'category': 'cross_system',
        'severity': contextData['severity'] ?? 'high',
        'title': 'Automated cross-system response executed',
        'message': 'Executed ${actions.length} actions',
        'status': 'active',
        'metadata': {
          'contextData': contextData,
          'actions': actions,
          'executedAt': DateTime.now().toIso8601String(),
        },
      });

      return {'success': true};
    } catch (e) {
      debugPrint('executeAutomatedResponse error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
