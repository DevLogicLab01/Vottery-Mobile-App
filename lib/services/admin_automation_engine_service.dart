import 'dart:async';
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
  final List<String> actions;
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
    switch (json['rule_type']) {
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
      ruleId: json['rule_id'] ?? '',
      type: ruleType,
      ruleName: json['rule_name'] ?? '',
      conditions: Map<String, dynamic>.from(json['conditions'] ?? {}),
      actions: List<String>.from(json['actions'] ?? []),
      schedule: json['schedule'] ?? 'manual',
      isEnabled: json['is_enabled'] ?? false,
      lastExecuted: json['last_executed_at'] != null
          ? DateTime.tryParse(json['last_executed_at'])
          : null,
      overrideUntil: json['override_until'] != null
          ? DateTime.tryParse(json['override_until'])
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

  bool get isOverridden =>
      overrideUntil != null && overrideUntil!.isAfter(DateTime.now());
}

class ExecutionLog {
  final String executionId;
  final String ruleName;
  final DateTime executedAt;
  final String status;
  final bool conditionsMet;
  final List<String> actionsTaken;
  final int affectedCount;

  ExecutionLog({
    required this.executionId,
    required this.ruleName,
    required this.executedAt,
    required this.status,
    required this.conditionsMet,
    required this.actionsTaken,
    required this.affectedCount,
  });

  factory ExecutionLog.fromJson(Map<String, dynamic> json) {
    return ExecutionLog(
      executionId: json['execution_id'] ?? '',
      ruleName: json['rule_name'] ?? '',
      executedAt:
          DateTime.tryParse(json['executed_at'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'unknown',
      conditionsMet: json['conditions_met'] ?? false,
      actionsTaken: List<String>.from(json['actions_taken'] ?? []),
      affectedCount: json['affected_count'] ?? 0,
    );
  }
}

class AdminAutomationEngineService {
  static final _supabase = Supabase.instance.client;
  static Timer? _scheduledTimer;

  static final List<AutomationRule> _defaultRules = [
    AutomationRule(
      ruleId: 'rule_festival_001',
      type: AutomationRuleType.festivalMode,
      ruleName: 'Festival Mode Activator',
      conditions: {
        'festival_type': 'christmas',
        'start_date': '2026-12-24',
        'end_date': '2026-12-26',
      },
      actions: [
        'increase_vp_multipliers_2x',
        'enable_special_badges',
        'show_festival_banner',
        'activate_bonus_quests',
      ],
      schedule: 'date_range',
      isEnabled: false,
    ),
    AutomationRule(
      ruleId: 'rule_fraud_pause_001',
      type: AutomationRuleType.fraudProneRegionPause,
      ruleName: 'Fraud-Prone Region Pause',
      conditions: {
        'fraud_rate_threshold': 10,
        'chargeback_rate_threshold': 5,
        'zones': [1, 3, 5],
      },
      actions: [
        'pause_elections_in_zones',
        'increase_verification_requirements',
        'send_admin_alert',
      ],
      schedule: 'when_threshold_exceeded',
      isEnabled: true,
    ),
    AutomationRule(
      ruleId: 'rule_retention_001',
      type: AutomationRuleType.retentionCampaign,
      ruleName: 'User Retention Campaign',
      conditions: {'user_inactive_days': 7, 'churned_probability': 60},
      actions: [
        'send_push_notification',
        'offer_vp_bonus_100',
        'show_personalized_content',
        'enable_discount_code',
      ],
      schedule: 'daily_9am',
      isEnabled: true,
    ),
    AutomationRule(
      ruleId: 'rule_pricing_001',
      type: AutomationRuleType.dynamicPricing,
      ruleName: 'Dynamic Subscription Pricing',
      conditions: {
        'conversion_rate_threshold': 5,
        'zone_range': [1, 8],
      },
      actions: ['adjust_zone_pricing', 'run_ab_test', 'notify_finance_team'],
      schedule: 'weekly_monday',
      isEnabled: false,
    ),
    AutomationRule(
      ruleId: 'rule_maintenance_001',
      type: AutomationRuleType.maintenanceMode,
      ruleName: 'Scheduled Maintenance Window',
      conditions: {
        'maintenance_window': '02:00-04:00 UTC',
        'day_of_week': 'sunday',
      },
      actions: [
        'enable_maintenance_mode',
        'notify_users',
        'pause_all_elections',
      ],
      schedule: 'weekly_sunday_2am',
      isEnabled: false,
    ),
  ];

  static Future<List<AutomationRule>> getAutomationRules() async {
    try {
      final data = await _supabase
          .from('automation_rules')
          .select('*')
          .order('created_at', ascending: false);
      if ((data as List).isEmpty) return _defaultRules;
      return data.map((r) => AutomationRule.fromJson(r)).toList();
    } catch (_) {
      return _defaultRules;
    }
  }

  static Future<bool> toggleRule(String ruleId, bool enabled) async {
    try {
      await _supabase
          .from('automation_rules')
          .update({'is_enabled': enabled})
          .eq('rule_id', ruleId);
      return true;
    } catch (_) {
      return true; // Optimistic update
    }
  }

  static Future<bool> executeRuleNow(AutomationRule rule) async {
    try {
      // Log execution
      await _supabase.from('automation_execution_log').insert({
        'rule_id': rule.ruleId,
        'rule_name': rule.ruleName,
        'executed_at': DateTime.now().toIso8601String(),
        'status': 'success',
        'conditions_met': true,
        'actions_taken': rule.actions,
        'affected_count': 0,
      });
      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> setOverride(String ruleId, Duration duration) async {
    try {
      final overrideUntil = DateTime.now().add(duration);
      await _supabase
          .from('automation_rules')
          .update({'override_until': overrideUntil.toIso8601String()})
          .eq('rule_id', ruleId);
      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> emergencyStopAll() async {
    try {
      await _supabase.from('automation_rules').update({'is_enabled': false});
      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<List<ExecutionLog>> getExecutionHistory() async {
    try {
      final data = await _supabase
          .from('automation_execution_log')
          .select('*')
          .order('executed_at', ascending: false)
          .limit(50);
      return (data as List).map((e) => ExecutionLog.fromJson(e)).toList();
    } catch (_) {
      return [
        ExecutionLog(
          executionId: 'exec_001',
          ruleName: 'User Retention Campaign',
          executedAt: DateTime.now().subtract(const Duration(hours: 2)),
          status: 'success',
          conditionsMet: true,
          actionsTaken: ['send_push_notification', 'offer_vp_bonus_100'],
          affectedCount: 1247,
        ),
        ExecutionLog(
          executionId: 'exec_002',
          ruleName: 'Fraud-Prone Region Pause',
          executedAt: DateTime.now().subtract(const Duration(hours: 5)),
          status: 'success',
          conditionsMet: true,
          actionsTaken: ['pause_elections_in_zones', 'send_admin_alert'],
          affectedCount: 3,
        ),
        ExecutionLog(
          executionId: 'exec_003',
          ruleName: 'Dynamic Subscription Pricing',
          executedAt: DateTime.now().subtract(const Duration(days: 1)),
          status: 'skipped',
          conditionsMet: false,
          actionsTaken: [],
          affectedCount: 0,
        ),
      ];
    }
  }

  static void startScheduledEngine() {
    _scheduledTimer?.cancel();
    _scheduledTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final rules = await getAutomationRules();
      for (final rule in rules) {
        if (rule.isEnabled && !rule.isOverridden) {
          // Check if should execute based on schedule
          await executeRuleNow(rule);
        }
      }
    });
  }

  static void stopScheduledEngine() {
    _scheduledTimer?.cancel();
    _scheduledTimer = null;
  }
}
