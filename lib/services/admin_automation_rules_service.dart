import 'package:supabase_flutter/supabase_flutter.dart';

enum AutomationRuleType {
  festivalMode,
  fraudProneRegionPause,
  retentionCampaign,
  dynamicPricing,
  maintenanceMode,
}

class AutomationRule {
  final String ruleId;
  final AutomationRuleType type;
  final String ruleName;
  final Map<String, dynamic> conditions;
  final List<Map<String, dynamic>> actions;
  final String schedule;
  final bool isEnabled;
  final DateTime? lastExecuted;
  final DateTime? overrideUntil;

  AutomationRule({
    required this.ruleId,
    required this.type,
    required this.ruleName,
    required this.conditions,
    required this.actions,
    required this.schedule,
    required this.isEnabled,
    this.lastExecuted,
    this.overrideUntil,
  });

  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    AutomationRuleType ruleType;
    switch (json['rule_type']?.toString()) {
      case 'festivalMode':
        ruleType = AutomationRuleType.festivalMode;
        break;
      case 'fraudProneRegionPause':
        ruleType = AutomationRuleType.fraudProneRegionPause;
        break;
      case 'retentionCampaign':
        ruleType = AutomationRuleType.retentionCampaign;
        break;
      case 'dynamicPricing':
        ruleType = AutomationRuleType.dynamicPricing;
        break;
      default:
        ruleType = AutomationRuleType.maintenanceMode;
    }
    return AutomationRule(
      ruleId: json['rule_id']?.toString() ?? json['id']?.toString() ?? '',
      type: ruleType,
      ruleName: json['rule_name']?.toString() ?? 'Unnamed Rule',
      conditions: Map<String, dynamic>.from(json['conditions'] as Map? ?? {}),
      actions: List<Map<String, dynamic>>.from(
        (json['actions'] as List? ?? []).map(
          (e) => Map<String, dynamic>.from(e as Map? ?? {}),
        ),
      ),
      schedule: json['schedule']?.toString() ?? '',
      isEnabled: json['is_enabled'] == true,
      lastExecuted: json['last_executed_at'] != null
          ? DateTime.tryParse(json['last_executed_at'].toString())
          : null,
      overrideUntil: json['override_until'] != null
          ? DateTime.tryParse(json['override_until'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'rule_id': ruleId,
    'rule_type': type.name,
    'rule_name': ruleName,
    'conditions': conditions,
    'actions': actions,
    'schedule': schedule,
    'is_enabled': isEnabled,
    'last_executed_at': lastExecuted?.toIso8601String(),
    'override_until': overrideUntil?.toIso8601String(),
  };
}

class AutomationExecutionLog {
  final String executionId;
  final String ruleName;
  final DateTime executedAt;
  final String status;
  final bool conditionsMet;
  final List<String> actionsTaken;
  final int affectedCount;

  AutomationExecutionLog({
    required this.executionId,
    required this.ruleName,
    required this.executedAt,
    required this.status,
    required this.conditionsMet,
    required this.actionsTaken,
    required this.affectedCount,
  });

  factory AutomationExecutionLog.fromJson(Map<String, dynamic> json) {
    return AutomationExecutionLog(
      executionId:
          json['execution_id']?.toString() ?? json['id']?.toString() ?? '',
      ruleName: json['rule_name']?.toString() ?? 'Unknown Rule',
      executedAt:
          DateTime.tryParse(json['executed_at']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString() ?? 'unknown',
      conditionsMet: json['conditions_met'] == true,
      actionsTaken: List<String>.from(json['actions_taken'] as List? ?? []),
      affectedCount: (json['affected_count'] as num? ?? 0).toInt(),
    );
  }
}

class AdminAutomationRulesService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<AutomationRule>> getAutomationRules() async {
    try {
      final response = await _supabase
          .from('automation_rules')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map(
            (e) => AutomationRule.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<AutomationExecutionLog>> getExecutionHistory() async {
    try {
      final response = await _supabase
          .from('automation_execution_log')
          .select()
          .order('executed_at', ascending: false)
          .limit(50);
      return (response as List)
          .map(
            (e) => AutomationExecutionLog.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> toggleRule(String ruleId, bool enabled) async {
    try {
      await _supabase
          .from('automation_rules')
          .update({'is_enabled': enabled})
          .eq('rule_id', ruleId);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> executeRuleNow(AutomationRule rule) async {
    try {
      await _supabase.from('automation_execution_log').insert({
        'rule_id': rule.ruleId,
        'rule_name': rule.ruleName,
        'executed_at': DateTime.now().toIso8601String(),
        'status': 'success',
        'conditions_met': true,
        'actions_taken': rule.actions
            .map((a) => a['action']?.toString() ?? '')
            .toList(),
        'affected_count': 0,
        'triggered_by': 'manual',
      });
      await _supabase
          .from('automation_rules')
          .update({'last_executed_at': DateTime.now().toIso8601String()})
          .eq('rule_id', rule.ruleId);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> createRule(Map<String, dynamic> ruleData) async {
    try {
      await _supabase.from('automation_rules').insert({
        ...ruleData,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteRule(String ruleId) async {
    try {
      await _supabase.from('automation_rules').delete().eq('rule_id', ruleId);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setOverride(String ruleId, Duration duration) async {
    final overrideUntil = DateTime.now().add(duration);
    try {
      await _supabase
          .from('automation_rules')
          .update({
            'override_until': overrideUntil.toIso8601String(),
            'is_enabled': false,
          })
          .eq('rule_id', ruleId);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> emergencyStopAll() async {
    try {
      await _supabase.from('automation_rules').update({'is_enabled': false});
      await _supabase.from('automation_execution_log').insert({
        'rule_name': 'EMERGENCY_STOP_ALL',
        'executed_at': DateTime.now().toIso8601String(),
        'status': 'emergency_stop',
        'conditions_met': true,
        'actions_taken': ['disabled_all_rules'],
        'affected_count': 0,
        'triggered_by': 'admin_emergency',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

}
