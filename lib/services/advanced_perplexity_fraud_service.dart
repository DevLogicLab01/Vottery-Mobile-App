import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Parity with Web `advancedPerplexityFraudService.getFraudIntelligenceSignalsFromSupabase`.
class AdvancedPerplexityFraudService {
  AdvancedPerplexityFraudService._();
  static final AdvancedPerplexityFraudService instance =
      AdvancedPerplexityFraudService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  String _norm(dynamic s) => s?.toString().toLowerCase().trim() ?? '';

  Future<Map<String, dynamic>> getFraudIntelligenceSignalsFromSupabase({
    int days = 30,
  }) async {
    final sinceMs = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final since =
        DateTime.fromMillisecondsSinceEpoch(sinceMs, isUtc: true).toIso8601String();
    final midMs = sinceMs + (DateTime.now().millisecondsSinceEpoch - sinceMs) ~/ 2;
    final mid = DateTime.fromMillisecondsSinceEpoch(midMs, isUtc: true)
        .toIso8601String();

    const resolvedStatuses = {
      'resolved',
      'closed',
      'dismissed',
      'rejected',
    };

    try {
      final alertsRes = await _client
          .from('fraud_alerts')
          .select('id, severity, status, created_at')
          .gte('created_at', since);
      final flagsRes = await _client
          .from('content_flags')
          .select('id, severity, status, created_at')
          .gte('created_at', since)
          .limit(5000);
      final votesRes = await _client
          .from('votes')
          .select('id, created_at')
          .gte('created_at', since)
          .limit(8000);
      final anomaliesRes = await _client
          .from('revenue_anomalies')
          .select('amount, created_at')
          .gte('created_at', since)
          .limit(500);

      final alerts = (alertsRes as List?) ?? [];
      final flags = (flagsRes as List?) ?? [];
      final votes = (votesRes as List?) ?? [];
      final anomalies = (anomaliesRes as List?) ?? [];

      final pastIncidents = alerts.length + flags.length;
      final voteCount = votes.length;
      final fraudRate = voteCount > 0
          ? double.parse(((pastIncidents / voteCount) * 1000).toStringAsFixed(3))
          : 0.0;

      var sumAmt = 0.0;
      var amtCount = 0;
      for (final a in anomalies) {
        if (a is! Map) continue;
        final v = double.tryParse((a['amount'] ?? '0').toString()) ?? 0;
        sumAmt += v;
        amtCount++;
      }
      final averageLoss =
          amtCount > 0 ? double.parse((sumAmt / amtCount).toStringAsFixed(2)) : 0.0;

      int firstHalf = 0;
      int secondHalf = 0;
      final midDt = DateTime.tryParse(mid);
      for (final row in [...alerts, ...flags]) {
        if (row is! Map) continue;
        final t = DateTime.tryParse((row['created_at'] ?? '').toString());
        if (t == null || midDt == null) continue;
        if (t.isBefore(midDt)) {
          firstHalf++;
        } else {
          secondHalf++;
        }
      }
      var trendDirection = 'stable';
      if (secondHalf > (firstHalf * 1.15).round()) {
        trendDirection = 'increasing';
      } else if (firstHalf > 0 && secondHalf < (firstHalf * 0.85).round()) {
        trendDirection = 'decreasing';
      }

      var alertResolved = 0;
      for (final a in alerts) {
        if (a is Map && resolvedStatuses.contains(_norm(a['status']))) {
          alertResolved++;
        }
      }
      var flagResolved = 0;
      for (final f in flags) {
        if (f is Map && resolvedStatuses.contains(_norm(f['status']))) {
          flagResolved++;
        }
      }
      final alertOpen = (alerts.length - alertResolved).clamp(0, 1 << 30);
      final flagOpen = (flags.length - flagResolved).clamp(0, 1 << 30);

      return {
        'historicalData': {
          'pastIncidents': pastIncidents,
          'fraudRate': fraudRate,
          'averageLoss': averageLoss,
          'trendDirection': trendDirection,
          'voteSampleSize': voteCount,
          'windowDays': days,
          'source': 'supabase_signals',
        },
        'threatData': {
          'recentThreats': pastIncidents,
          'activeInvestigations': alertOpen + flagOpen,
          'resolvedCases': alertResolved + flagResolved,
          'fraudAlerts': alerts.length,
          'contentFlags': flags.length,
          'revenueAnomalies': anomalies.length,
        },
      };
    } catch (e, st) {
      debugPrint('AdvancedPerplexityFraudService.getFraudIntelligenceSignalsFromSupabase: $e\n$st');
      return {
        'historicalData': {
          'pastIncidents': 0,
          'fraudRate': 0.0,
          'averageLoss': 0.0,
          'trendDirection': 'stable',
          'voteSampleSize': 0,
          'windowDays': days,
          'source': 'supabase_signals_error',
        },
        'threatData': {
          'recentThreats': 0,
          'activeInvestigations': 0,
          'resolvedCases': 0,
          'fraudAlerts': 0,
          'contentFlags': 0,
          'revenueAnomalies': 0,
        },
        'errors': {'exception': e.toString()},
      };
    }
  }

  /// Daily series for `PerplexityService.forecastFraudTrends` (parity with Web `buildHistoricalWindowFromSupabase`).
  Future<List<Map<String, dynamic>>> buildDailyIncidentSeriesForForecast({
    int days = 60,
  }) async {
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toUtc()
        .toIso8601String();
    try {
      final alertsRes = await _client
          .from('fraud_alerts')
          .select('created_at')
          .gte('created_at', since);
      final flagsRes = await _client
          .from('content_flags')
          .select('created_at')
          .gte('created_at', since)
          .limit(10000);
      final votesRes = await _client
          .from('votes')
          .select('created_at')
          .gte('created_at', since)
          .limit(20000);

      final byDay = <String, Map<String, int>>{};
      void bump(String? iso, String field) {
        if (iso == null || iso.length < 10) return;
        final k = iso.substring(0, 10);
        byDay.putIfAbsent(k, () => {'incidents': 0, 'votes': 0});
        byDay[k]![field] = (byDay[k]![field] ?? 0) + 1;
      }

      for (final r in (alertsRes as List?) ?? []) {
        if (r is Map) bump(r['created_at']?.toString(), 'incidents');
      }
      for (final r in (flagsRes as List?) ?? []) {
        if (r is Map) bump(r['created_at']?.toString(), 'incidents');
      }
      for (final r in (votesRes as List?) ?? []) {
        if (r is Map) bump(r['created_at']?.toString(), 'votes');
      }

      final out = <Map<String, dynamic>>[];
      for (var i = days - 1; i >= 0; i--) {
        final d = DateTime.now().subtract(Duration(days: i));
        final k =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final b = byDay[k] ?? {'incidents': 0, 'votes': 0};
        out.add({
          'date': k,
          'incidents': b['incidents'] ?? 0,
          'votes': b['votes'] ?? 0,
          'source': 'supabase',
        });
      }
      return out;
    } catch (e, st) {
      debugPrint('buildDailyIncidentSeriesForForecast: $e\n$st');
      return [];
    }
  }
}
