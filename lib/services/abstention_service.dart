import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

/// Records and reports abstentions. Same API as Web abstentionService.
/// Source: 'viewed_no_vote' | 'explicit'
class AbstentionService {
  static AbstentionService? _instance;
  static AbstentionService get instance => _instance ??= AbstentionService._();

  AbstentionService._();

  dynamic get _client => SupabaseService.instance.client;

  /// Record abstention. source: 'viewed_no_vote' or 'explicit'
  Future<({bool ok, String? error})> recordAbstention(
    String electionId,
    String userId, {
    String source = 'viewed_no_vote',
    String? reason,
  }) async {
    try {
      await _client.from('vote_abstentions').upsert({
        'election_id': electionId,
        'user_id': userId,
        'source': source == 'explicit' ? 'explicit' : 'viewed_no_vote',
        'abstention_reason': reason,
      }, onConflict: 'election_id,user_id');
      return (ok: true, error: null);
    } catch (e) {
      debugPrint('AbstentionService.recordAbstention: $e');
      return (ok: false, error: e.toString());
    }
  }

  /// Check if user already abstained (avoid double-record on leave).
  Future<bool> hasAbstained(String electionId, String userId) async {
    try {
      final res = await _client
          .from('vote_abstentions')
          .select('id')
          .eq('election_id', electionId)
          .eq('user_id', userId)
          .maybeSingle();
      return res != null;
    } catch (e) {
      debugPrint('AbstentionService.hasAbstained: $e');
      return false;
    }
  }

  /// Report for one election (creator or admin).
  Future<Map<String, dynamic>> getReportForElection(String electionId) async {
    try {
      final data = await _client
          .from('vote_abstentions')
          .select('id, user_id, source, abstention_reason, created_at')
          .eq('election_id', electionId)
          .order('created_at', ascending: false);
      final list = List<Map<String, dynamic>>.from(data as List);
      final bySource = <String, int>{};
      for (final row in list) {
        final s = row['source'] as String? ?? 'viewed_no_vote';
        bySource[s] = (bySource[s] ?? 0) + 1;
      }
      return {
        'list': list,
        'total': list.length,
        'bySource': bySource,
      };
    } catch (e) {
      debugPrint('AbstentionService.getReportForElection: $e');
      return {'list': [], 'total': 0, 'bySource': <String, int>{}};
    }
  }

  /// Dashboard: time-series placeholder until analytics views exist in Supabase.
  Future<List<Map<String, dynamic>>> getAbstentionTrends({int days = 7}) async {
    return [];
  }

  /// Dashboard: elections with elevated abstention (placeholder).
  Future<List<Map<String, dynamic>>> getHighAbstentionElections() async {
    return [];
  }

  /// Dashboard: engagement vs abstention correlation (placeholder).
  Future<Map<String, dynamic>> getEngagementCorrelation() async {
    return {};
  }

  /// Dashboard: suggested copy/actions (placeholder until analytics RPC exists).
  Future<List<String>> getImprovementRecommendations(dynamic electionId) async {
    return [];
  }
}
