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
      return _mockRules();
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
      return _mockExecutionLogs();
    }
  }

  static Future<void> toggleRule(String ruleId, bool enabled) async {
    try {
      await _supabase
          .from('automation_rules')
          .update({'is_enabled': enabled})
          .eq('rule_id', ruleId);
    } catch (e) {
      // Silent fail for demo
    }
  }

  static Future<void> executeRuleNow(AutomationRule rule) async {
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
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> createRule(Map<String, dynamic> ruleData) async {
    try {
      await _supabase.from('automation_rules').insert({
        ...ruleData,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> deleteRule(String ruleId) async {
    try {
      await _supabase.from('automation_rules').delete().eq('rule_id', ruleId);
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> setOverride(String ruleId, Duration duration) async {
    final overrideUntil = DateTime.now().add(duration);
    try {
      await _supabase
          .from('automation_rules')
          .update({
            'override_until': overrideUntil.toIso8601String(),
            'is_enabled': false,
          })
          .eq('rule_id', ruleId);
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> emergencyStopAll() async {
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
    } catch (e) {
      // Silent fail
    }
  }

  static List<AutomationRule> _mockRules() => [
    AutomationRule(
      ruleId: 'rule_001',
      type: AutomationRuleType.festivalMode,
      ruleName: 'Christmas Festival Mode',
      conditions: {
        'festival_type': 'christmas',
        'start_date': '2026-12-24',
        'end_date': '2026-12-26',
      },
      actions: [
        {'action': 'increase_vp_multipliers', 'value': 2},
        {'action': 'enable_special_badges'},
        {'action': 'show_festival_banner'},
        {'action': 'activate_bonus_quests'},
      ],
      schedule: '0 0 24 12 *',
      isEnabled: false,
      lastExecuted: DateTime.now().subtract(const Duration(days: 30)),
    ),
    AutomationRule(
      ruleId: 'rule_002',
      type: AutomationRuleType.fraudProneRegionPause,
      ruleName: 'High Fraud Zone Pause',
      conditions: {'fraud_rate_threshold': 0.10, 'chargeback_rate': 0.05},
      actions: [
        {
          'action': 'pause_elections_in_zones',
          'zones': [1, 3, 5],
        },
        {'action': 'increase_verification_requirements'},
        {'action': 'send_admin_alert'},
      ],
      schedule: '*/30 * * * *',
      isEnabled: true,
      lastExecuted: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AutomationRule(
      ruleId: 'rule_003',
      type: AutomationRuleType.retentionCampaign,
      ruleName: 'Inactive User Re-engagement',
      conditions: {'user_inactive_days': 7, 'churned_probability': 0.60},
      actions: [
        {'action': 'send_push_notification', 'message': 'We miss you!'},
        {'action': 'offer_vp_bonus', 'amount': 100},
        {'action': 'show_personalized_content'},
        {'action': 'enable_discount_code'},
      ],
      schedule: '0 9 * * *',
      isEnabled: true,
      lastExecuted: DateTime.now().subtract(const Duration(hours: 15)),
    ),
    AutomationRule(
      ruleId: 'rule_004',
      type: AutomationRuleType.dynamicPricing,
      ruleName: 'Market-Responsive Pricing',
      conditions: {'demand_threshold': 0.80, 'competitor_price_change': 0.05},
      actions: [
        {
          'action': 'adjust_subscription_price',
          'zones': [1, 2, 3],
        },
        {'action': 'update_cpe_rates'},
      ],
      schedule: '0 */6 * * *',
      isEnabled: false,
      lastExecuted: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static List<AutomationExecutionLog> _mockExecutionLogs() => [
    AutomationExecutionLog(
      executionId: 'exec_001',
      ruleName: 'High Fraud Zone Pause',
      executedAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'success',
      conditionsMet: true,
      actionsTaken: ['pause_elections_in_zones', 'send_admin_alert'],
      affectedCount: 3,
    ),
    AutomationExecutionLog(
      executionId: 'exec_002',
      ruleName: 'Inactive User Re-engagement',
      executedAt: DateTime.now().subtract(const Duration(hours: 15)),
      status: 'success',
      conditionsMet: true,
      actionsTaken: ['send_push_notification', 'offer_vp_bonus'],
      affectedCount: 247,
    ),
    AutomationExecutionLog(
      executionId: 'exec_003',
      ruleName: 'High Fraud Zone Pause',
      executedAt: DateTime.now().subtract(const Duration(hours: 32)),
      status: 'skipped',
      conditionsMet: false,
      actionsTaken: [],
      affectedCount: 0,
    ),
  ];
}
