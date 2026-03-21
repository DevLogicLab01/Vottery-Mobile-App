import 'package:flutter/foundation.dart';

import './supabase_service.dart';

class BrandAlertService {
  static BrandAlertService? _instance;
  static BrandAlertService get instance =>
      _instance ??= BrandAlertService._();

  BrandAlertService._();

  Future<Map<String, dynamic>> getBudgetMonitoringDashboard({
    String timeRange = '24h',
  }) async {
    try {
      final client = SupabaseService.instance.client;
      final rows = await client
          .from('sponsored_elections')
          .select(
            'id,election_id,budget_total,budget_spent,total_engagements,cost_per_vote,status,updated_at',
          )
          .order('updated_at', ascending: false)
          .limit(100);

      final campaigns = rows.map<Map<String, dynamic>>((raw) {
        final row = Map<String, dynamic>.from(raw);
        final total = (row['budget_total'] as num?)?.toDouble() ?? 0;
        final spent = (row['budget_spent'] as num?)?.toDouble() ?? 0;
        final pct = total > 0 ? (spent / total) * 100 : 0.0;
        return {
          'id': row['id'],
          'electionId': row['election_id'],
          'budgetTotal': total,
          'budgetSpent': spent,
          'spendPercentage': pct,
          'status': pct >= 90 ? 'critical' : (pct >= 75 ? 'warning' : 'healthy'),
          'burnRate': (row['cost_per_vote'] as num?)?.toDouble() ?? 0,
          'totalEngagements': row['total_engagements'] ?? 0,
        };
      }).toList();

      return {
        'campaigns': campaigns,
        'timeRange': timeRange,
      };
    } catch (e) {
      debugPrint('getBudgetMonitoringDashboard error: $e');
      return {'campaigns': <Map<String, dynamic>>[]};
    }
  }

  Future<Map<String, dynamic>> monitorBudgetThresholds() async {
    final dashboard = await getBudgetMonitoringDashboard();
    final campaigns = List<Map<String, dynamic>>.from(dashboard['campaigns'] ?? []);
    final critical = campaigns.where((c) => c['status'] == 'critical').length;
    return {
      'monitored': campaigns.length,
      'criticalCampaigns': critical,
    };
  }

  Future<Map<String, dynamic>> sendBudgetAlert({
    required String campaignId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final client = SupabaseService.instance.client;
      await client.from('brand_alert_logs').insert({
        'campaign_id': campaignId,
        'alert_type': 'budget_threshold',
        'threshold': 90,
        'slack_status': 'queued',
        'discord_status': 'queued',
        'alert_data': payload,
      });
      return {'success': true};
    } catch (e) {
      debugPrint('sendBudgetAlert error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
