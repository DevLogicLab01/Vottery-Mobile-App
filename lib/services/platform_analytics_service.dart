import 'package:flutter/foundation.dart';

import '../framework/shared_constants.dart';
import 'supabase_service.dart';

/// Fetches platform-wide and personal analytics from Supabase (aligned with Web analyticsService).
class PlatformAnalyticsService {
  static PlatformAnalyticsService? _instance;
  static PlatformAnalyticsService get instance =>
      _instance ??= PlatformAnalyticsService._();

  PlatformAnalyticsService._();

  dynamic get _client => SupabaseService.instance.client;

  /// Time range: 24h, 7d, 30d
  DateTime _startDate(String timeRange) {
    final now = DateTime.now();
    switch (timeRange) {
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      default:
        return now.subtract(const Duration(hours: 24));
    }
  }

  /// Engagement: active users, posts, likes, comments, shares, engagement rate
  Future<Map<String, dynamic>> getEngagementMetrics({String timeRange = '24h'}) async {
    try {
      final start = _startDate(timeRange).toUtc().toIso8601String();
      final profiles = await _client.from('user_profiles').select('id, created_at').gte('created_at', start);
      final posts = await _client.from('posts').select('likes, comments, shares, created_at').gte('created_at', start);
      int totalLikes = 0, totalComments = 0, totalShares = 0;
      for (final p in posts as List) {
        totalLikes += (p['likes'] as num?)?.toInt() ?? 0;
        totalComments += (p['comments'] as num?)?.toInt() ?? 0;
        totalShares += (p['shares'] as num?)?.toInt() ?? 0;
      }
      final postCount = (posts as List).length;
      final engagementRate = postCount > 0
          ? ((totalLikes + totalComments + totalShares) / postCount)
          : 0.0;
      return {
        'activeUsers': (profiles as List).length,
        'totalPosts': postCount,
        'totalLikes': totalLikes,
        'totalComments': totalComments,
        'totalShares': totalShares,
        'engagementRate': engagementRate,
      };
    } catch (e) {
      debugPrint('getEngagementMetrics error: $e');
      return {};
    }
  }

  /// Election performance: total/active/completed elections, votes, participation
  Future<Map<String, dynamic>> getElectionPerformance({String timeRange = '24h'}) async {
    try {
      final start = _startDate(timeRange).toUtc().toIso8601String();
      final elections = await _client.from('elections').select('id, status, total_voters, created_at').gte('created_at', start);
      final votes = await _client.from('votes').select('id, election_id, created_at').gte('created_at', start);
      final list = elections as List;
      int active = 0, completed = 0, totalVoters = 0;
      for (final e in list) {
        if (e['status'] == 'active') active++;
        if (e['status'] == 'completed') completed++;
        totalVoters += (e['total_voters'] as num?)?.toInt() ?? 0;
      }
      final voteCount = (votes as List).length;
      final participationRate = totalVoters > 0 ? (voteCount / totalVoters) * 100 : 0.0;
      return {
        'totalElections': list.length,
        'activeElections': active,
        'completedElections': completed,
        'totalVotes': voteCount,
        'participationRate': participationRate,
      };
    } catch (e) {
      debugPrint('getElectionPerformance error: $e');
      return {};
    }
  }

  /// Revenue metrics (placeholder: user_wallets / payouts if available)
  Future<Map<String, dynamic>> getRevenueMetrics({String timeRange = '24h'}) async {
    try {
      final start = _startDate(timeRange).toUtc().toIso8601String();
      // Example: sum of payout amounts in period
      final payouts = await _client.from('user_wallets').select('balance, updated_at').gte('updated_at', start);
      double total = 0;
      for (final p in payouts as List) {
        total += (p['balance'] as num?)?.toDouble() ?? 0;
      }
      return {'totalRevenue': total, 'transactionCount': (payouts as List).length};
    } catch (e) {
      debugPrint('getRevenueMetrics error: $e');
      return {};
    }
  }

  /// Ad ROI metrics (sponsored_elections or advertiser_campaigns)
  Future<Map<String, dynamic>> getAdROIMetrics({String timeRange = '24h'}) async {
    try {
      final start = _startDate(timeRange).toUtc().toIso8601String();
      try {
        final rows = await _client.from('sponsored_elections').select('budget_spent, total_engagements').gte('created_at', start);
        double spend = 0;
        int engagements = 0;
        for (final r in rows as List) {
          spend += (r['budget_spent'] as num?)?.toDouble() ?? 0;
          engagements += (r['total_engagements'] as num?)?.toInt() ?? 0;
        }
        final roi = spend > 0 ? (engagements / spend) : 0.0;
        return {'totalSpend': spend, 'totalEngagements': engagements, 'roi': roi};
      } catch (_) {
        return {};
      }
    } catch (e) {
      debugPrint('getAdROIMetrics error: $e');
      return {};
    }
  }

  /// Personal: current user voting count, earnings, achievements (simplified)
  Future<Map<String, dynamic>> getPersonalAnalytics(String? userId) async {
    if (userId == null) return {};
    try {
      final votes = await _client.from('votes').select('id').eq('user_id', userId);
      final wallet = await _client.from('user_wallets').select('balance, total_earned').eq('user_id', userId).maybeSingle();
      int voteCount = (votes as List).length;
      double balance = 0, totalEarned = 0;
      if (wallet != null) {
        balance = (wallet['balance'] as num?)?.toDouble() ?? 0;
        totalEarned = (wallet['total_earned'] as num?)?.toDouble() ?? 0;
      }
      return {
        'votesCast': voteCount,
        'balance': balance,
        'totalEarned': totalEarned,
        'achievementsUnlocked': 0, // extend when badges table exists
      };
    } catch (e) {
      debugPrint('getPersonalAnalytics error: $e');
      return {};
    }
  }

  /// Activity feed for current user (activity_feed table)
  Future<List<Map<String, dynamic>>> getActivityFeed({
    String? activityType,
    String? timeRange,
    bool? isRead,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];
      var query = _client.from('activity_feed').select('*, actor:actor_id(id, name, username, avatar, verified)').eq('user_id', userId).order('created_at', ascending: false).range(offset, offset + limit - 1);
      if (activityType != null && activityType != 'all') {
        query = query.eq('activity_type', activityType);
      }
      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }
      if (timeRange != null && timeRange != 'all') {
        final start = _startDate(timeRange).toUtc().toIso8601String();
        query = query.gte('created_at', start);
      }
      final data = await query;
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('getActivityFeed error: $e');
      return [];
    }
  }

  /// Payment-related notifications (settlement, payout delay, payment failure).
  /// Same semantics as Web notificationService.getPaymentNotifications.
  Future<List<Map<String, dynamic>>> getPaymentNotifications({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final data = await _client
          .from('activity_feed')
          .select('id, user_id, activity_type, title, description, is_read, created_at')
          .eq('user_id', userId)
          .inFilter('activity_type', SharedConstants.paymentNotificationTypes)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('getPaymentNotifications error: $e');
      return [];
    }
  }
}
