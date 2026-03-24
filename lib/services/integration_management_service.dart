import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class IntegrationManagementService {
  static IntegrationManagementService? _instance;
  static IntegrationManagementService get instance =>
      _instance ??= IntegrationManagementService._();

  IntegrationManagementService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  static const Map<String, String> _integrationNameAliases = {
    'gemini': 'Gemini',
    'anthropic': 'Anthropic',
    'resend': 'Resend',
    'twilio': 'Twilio',
    'telnyx': 'Telnyx',
    'whatsapp': 'WhatsApp (Twilio)',
    'push': 'Push Notifications',
    'google_analytics': 'Google Analytics',
    'google_adsense': 'Google AdSense',
    'stripe': 'Stripe',
  };
  static const List<Map<String, String>> _externalAdNetworkDefaults = [
    {
      'integration_name': 'Google AdSense',
      'integration_type': 'advertising',
    },
    {
      'integration_name': 'Google Analytics',
      'integration_type': 'analytics',
    },
  ];

  String _normalizeIntegrationName(String name) {
    final key = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return _integrationNameAliases[key] ?? name;
  }

  /// Get all integration settings
  Future<List<Map<String, dynamic>>> getAllIntegrations() async {
    try {
      final response = await _client
          .from('integration_settings')
          .select()
          .order('integration_type')
          .order('integration_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get all integrations error: $e');
      return [];
    }
  }

  /// Get integrations by type
  Future<List<Map<String, dynamic>>> getIntegrationsByType(String type) async {
    try {
      final response = await _client
          .from('integration_settings')
          .select()
          .eq('integration_type', type)
          .order('integration_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get integrations by type error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getIntegrationByName(String integrationName) async {
    try {
      final normalized = _normalizeIntegrationName(integrationName);
      final response = await _client
          .from('integration_settings')
          .select()
          .eq('integration_name', normalized)
          .maybeSingle();
      return response == null ? null : Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Get integration by name error: $e');
      return null;
    }
  }

  Future<void> ensureBatch1ExternalAdDefaults() async {
    try {
      final userId = _auth.currentUser?.id;
      for (final row in _externalAdNetworkDefaults) {
        final integrationName = row['integration_name']!;
        final existing = await getIntegrationByName(integrationName);
        await _client.from('integration_settings').upsert({
          'integration_name': integrationName,
          'integration_type':
              existing?['integration_type'] ?? row['integration_type'],
          'is_enabled': existing?['is_enabled'] ?? true,
          'weekly_budget_cap': existing?['weekly_budget_cap'] ?? 0,
          'monthly_budget_cap': existing?['monthly_budget_cap'] ?? 0,
          'current_weekly_usage': existing?['current_weekly_usage'] ?? 0,
          'current_monthly_usage': existing?['current_monthly_usage'] ?? 0,
          'rate_limit_per_minute': existing?['rate_limit_per_minute'] ?? 60,
          'config': existing?['config'] ?? <String, dynamic>{},
          'updated_at': DateTime.now().toIso8601String(),
          'last_modified_by': userId,
        }, onConflict: 'integration_name');
      }
    } catch (e) {
      debugPrint('Ensure Batch-1 external ad defaults error: $e');
    }
  }

  Future<Map<String, dynamic>> canUseIntegration(
    String integrationName, {
    double projectedCost = 0,
  }) async {
    final config = await getIntegrationByName(integrationName);
    if (config == null) {
      return {
        'allowed': false,
        'reason': 'Integration "$integrationName" is not configured',
      };
    }
    if (config['is_enabled'] != true) {
      return {
        'allowed': false,
        'reason': '${config['integration_name']} is disabled',
      };
    }

    final weeklyCap = (config['weekly_budget_cap'] as num?)?.toDouble() ?? 0;
    final monthlyCap = (config['monthly_budget_cap'] as num?)?.toDouble() ?? 0;
    final weeklyUsage =
        (config['current_weekly_usage'] as num?)?.toDouble() ?? 0;
    final monthlyUsage =
        (config['current_monthly_usage'] as num?)?.toDouble() ?? 0;

    if (weeklyCap > 0 && (weeklyUsage + projectedCost) > weeklyCap) {
      return {
        'allowed': false,
        'reason': '${config['integration_name']} weekly cap exceeded',
      };
    }
    if (monthlyCap > 0 && (monthlyUsage + projectedCost) > monthlyCap) {
      return {
        'allowed': false,
        'reason': '${config['integration_name']} monthly cap exceeded',
      };
    }
    return {'allowed': true, 'reason': null, 'config': config};
  }

  Future<bool> recordUsage(String integrationName, {double costDelta = 0}) async {
    try {
      final config = await getIntegrationByName(integrationName);
      if (config == null) return false;
      final id = config['id'];
      if (id == null) return false;
      await _client
          .from('integration_settings')
          .update({
            'current_weekly_usage':
                ((config['current_weekly_usage'] as num?)?.toDouble() ?? 0) +
                    costDelta,
            'current_monthly_usage':
                ((config['current_monthly_usage'] as num?)?.toDouble() ?? 0) +
                    costDelta,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Record integration usage error: $e');
      return false;
    }
  }

  /// Update integration status
  Future<bool> updateIntegrationStatus({
    required String integrationId,
    required bool isEnabled,
  }) async {
    try {
      final userId = _auth.currentUser?.id;
      if (userId == null) return false;

      await _client
          .from('integration_settings')
          .update({
            'is_enabled': isEnabled,
            'last_modified_by': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', integrationId);

      await _logAudit(
        action: 'update_integration_status',
        targetType: 'integration_setting',
        targetId: integrationId,
        newValue: {'is_enabled': isEnabled},
      );

      return true;
    } catch (e) {
      debugPrint('Update integration status error: $e');
      return false;
    }
  }

  /// Update budget caps
  Future<bool> updateBudgetCaps({
    required String integrationId,
    required double weeklyBudgetCap,
    required double monthlyBudgetCap,
  }) async {
    try {
      final userId = _auth.currentUser?.id;
      if (userId == null) return false;

      await _client
          .from('integration_settings')
          .update({
            'weekly_budget_cap': weeklyBudgetCap,
            'monthly_budget_cap': monthlyBudgetCap,
            'last_modified_by': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', integrationId);

      return true;
    } catch (e) {
      debugPrint('Update budget caps error: $e');
      return false;
    }
  }

  /// Get integration usage logs
  Future<List<Map<String, dynamic>>> getIntegrationUsageLogs({
    required String integrationId,
    int days = 7,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _client
          .from('integration_usage_logs')
          .select()
          .eq('integration_id', integrationId)
          .gte('timestamp', startDate.toIso8601String())
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get integration usage logs error: $e');
      return [];
    }
  }

  /// Get usage analytics (aggregated)
  Future<Map<String, dynamic>> getUsageAnalytics(String integrationId) async {
    try {
      final logs = await getIntegrationUsageLogs(
        integrationId: integrationId,
        days: 30,
      );

      if (logs.isEmpty) {
        return {
          'total_calls': 0,
          'total_cost': 0.0,
          'avg_response_time': 0,
          'error_rate': 0.0,
          'daily_breakdown': [],
        };
      }

      final totalCalls = logs.fold<int>(
        0,
        (sum, log) => sum + (log['api_calls_count'] as int),
      );
      final totalCost = logs.fold<double>(
        0,
        (sum, log) => sum + (log['cost'] as num).toDouble(),
      );
      final avgResponseTime =
          logs
              .where((log) => log['response_time_ms'] != null)
              .fold<int>(
                0,
                (sum, log) => sum + (log['response_time_ms'] as int),
              ) ~/
          logs.length;
      final errorCount = logs
          .where((log) => (log['status_code'] as int?) != 200)
          .length;
      final errorRate = (errorCount / logs.length) * 100;

      // Group by day
      final dailyBreakdown = <String, Map<String, dynamic>>{};
      for (final log in logs) {
        final date = DateTime.parse(log['timestamp'] as String);
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        if (!dailyBreakdown.containsKey(dateKey)) {
          dailyBreakdown[dateKey] = {'date': dateKey, 'calls': 0, 'cost': 0.0};
        }

        dailyBreakdown[dateKey]!['calls'] =
            (dailyBreakdown[dateKey]!['calls'] as int) +
            (log['api_calls_count'] as int);
        dailyBreakdown[dateKey]!['cost'] =
            (dailyBreakdown[dateKey]!['cost'] as double) +
            (log['cost'] as num).toDouble();
      }

      return {
        'total_calls': totalCalls,
        'total_cost': totalCost,
        'avg_response_time': avgResponseTime,
        'error_rate': errorRate,
        'daily_breakdown': dailyBreakdown.values.toList(),
      };
    } catch (e) {
      debugPrint('Get usage analytics error: $e');
      return {
        'total_calls': 0,
        'total_cost': 0.0,
        'avg_response_time': 0,
        'error_rate': 0.0,
        'daily_breakdown': [],
      };
    }
  }

  /// Stream integration settings (real-time)
  Stream<List<Map<String, dynamic>>> streamIntegrations() {
    return _client
        .from('integration_settings')
        .stream(primaryKey: ['id'])
        .order('integration_type')
        .order('integration_name')
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Check budget alert threshold
  bool shouldShowBudgetAlert({
    required double currentUsage,
    required double budgetCap,
  }) {
    if (budgetCap == 0) return false;
    final percentage = (currentUsage / budgetCap) * 100;
    return percentage >= 80;
  }

  Future<void> _logAudit({
    required String action,
    required String targetType,
    required String targetId,
    Map<String, dynamic>? newValue,
  }) async {
    try {
      final userId = _auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('admin_audit_logs').insert({
        'admin_id': userId,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'new_value': newValue,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log audit error: $e');
    }
  }
}
