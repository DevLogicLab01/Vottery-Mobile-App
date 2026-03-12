import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './claude_service.dart';

class BrandDashboardService {
  static BrandDashboardService? _instance;
  static BrandDashboardService get instance =>
      _instance ??= BrandDashboardService._();

  BrandDashboardService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  ClaudeService get _claude => ClaudeService.instance;

  /// Get campaign overview metrics
  Future<Map<String, dynamic>> getCampaignOverview({
    required String brandAccountId,
  }) async {
    try {
      // Get all sponsored elections for brand
      final campaigns = await _client
          .from('sponsored_elections')
          .select('*, ad_vote_tracking(*)')
          .eq('brand_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      double totalSpent = 0.0;
      double budgetRemaining = 0.0;
      int totalVotes = 0;
      int totalImpressions = 0;
      double totalEngagement = 0.0;

      for (final campaign in campaigns) {
        totalSpent += (campaign['spent_budget'] ?? 0.0) as num;
        final totalBudget = (campaign['total_budget'] ?? 0.0) as num;
        budgetRemaining += (totalBudget - totalSpent);
        totalVotes += (campaign['total_votes'] ?? 0) as int;
        totalImpressions += (campaign['total_impressions'] ?? 0) as int;
        totalEngagement += (campaign['engagement_rate'] ?? 0.0) as num;
      }

      final avgCPE = totalVotes > 0 ? totalSpent / totalVotes : 0.0;
      final avgEngagementRate = campaigns.isNotEmpty
          ? totalEngagement / campaigns.length
          : 0.0;

      // Calculate ROI lift (mock calculation)
      final roiLiftPercentage = avgEngagementRate > 5.0 ? 25.0 : 10.0;

      return {
        'total_spent': totalSpent,
        'budget_remaining': budgetRemaining,
        'votes_generated': totalVotes,
        'average_cpe': avgCPE,
        'roi_lift_percentage': roiLiftPercentage,
        'total_campaigns': campaigns.length,
        'active_campaigns': campaigns
            .where((c) => c['status'] == 'active')
            .length,
        'total_impressions': totalImpressions,
        'average_engagement_rate': avgEngagementRate,
      };
    } catch (e) {
      debugPrint('Get campaign overview error: $e');
      return {};
    }
  }

  /// Get real-time pulse chart data
  Future<List<Map<String, dynamic>>> getRealTimePulseData({
    required String sponsoredElectionId,
    required String timeframe, // 'hourly' or 'daily'
  }) async {
    try {
      final now = DateTime.now();
      final startDate = timeframe == 'hourly'
          ? now.subtract(Duration(hours: 24))
          : now.subtract(Duration(days: 30));

      final votes = await _client
          .from('ad_vote_tracking')
          .select('voted_at, cost_charged')
          .eq('sponsored_election_id', sponsoredElectionId)
          .gte('voted_at', startDate.toIso8601String())
          .order('voted_at', ascending: true);

      // Group by time period
      final Map<String, Map<String, dynamic>> grouped = {};

      for (final vote in votes) {
        final votedAt = DateTime.parse(vote['voted_at'] as String);
        final key = timeframe == 'hourly'
            ? '${votedAt.year}-${votedAt.month}-${votedAt.day}-${votedAt.hour}'
            : '${votedAt.year}-${votedAt.month}-${votedAt.day}';

        if (!grouped.containsKey(key)) {
          grouped[key] = {
            'timestamp': votedAt.toIso8601String(),
            'votes': 0,
            'cost': 0.0,
          };
        }

        grouped[key]!['votes'] = (grouped[key]!['votes'] as int) + 1;
        grouped[key]!['cost'] =
            (grouped[key]!['cost'] as double) + (vote['cost_charged'] as num);
      }

      final result = grouped.values.toList();

      // Detect viral spikes (3x average)
      if (result.isNotEmpty) {
        final avgVotes =
            result.map((r) => r['votes'] as int).reduce((a, b) => a + b) /
            result.length;
        for (final item in result) {
          item['is_viral_spike'] = (item['votes'] as int) >= (avgVotes * 3);
        }
      }

      return result;
    } catch (e) {
      debugPrint('Get real-time pulse data error: $e');
      return [];
    }
  }

  /// Get voter sentiment analysis
  Future<Map<String, dynamic>> getVoterSentiment({
    required String sponsoredElectionId,
  }) async {
    try {
      // Get vote distribution
      final votes = await _client
          .from('ad_vote_tracking')
          .select('vote_id')
          .eq('sponsored_election_id', sponsoredElectionId);

      // Get election options and vote counts
      final election = await _client
          .from('sponsored_elections')
          .select('election:elections(options)')
          .eq('id', sponsoredElectionId)
          .single();

      // Mock sentiment distribution
      final totalVotes = votes.length;
      final distribution = {
        'option_a': (totalVotes * 0.6).round(),
        'option_b': (totalVotes * 0.4).round(),
      };

      // Get demographics
      final demographics = await _getVoterDemographics(sponsoredElectionId);

      return {
        'vote_distribution': distribution,
        'total_votes': totalVotes,
        'demographics': demographics,
        'sentiment_score': 0.75, // Mock positive sentiment
      };
    } catch (e) {
      debugPrint('Get voter sentiment error: $e');
      return {};
    }
  }

  /// Get voter demographics
  Future<Map<String, dynamic>> _getVoterDemographics(
    String sponsoredElectionId,
  ) async {
    try {
      final votes = await _client
          .from('ad_vote_tracking')
          .select('user_id, user_profiles!inner(*)')
          .eq('sponsored_election_id', sponsoredElectionId);

      // Mock demographics analysis
      return {
        'age_groups': {
          '18-24': (votes.length * 0.3).round(),
          '25-34': (votes.length * 0.4).round(),
          '35-44': (votes.length * 0.2).round(),
          '45+': (votes.length * 0.1).round(),
        },
        'gender': {
          'male': (votes.length * 0.55).round(),
          'female': (votes.length * 0.45).round(),
        },
        'locations': {
          'US': (votes.length * 0.6).round(),
          'UK': (votes.length * 0.2).round(),
          'Other': (votes.length * 0.2).round(),
        },
      };
    } catch (e) {
      debugPrint('Get voter demographics error: $e');
      return {};
    }
  }

  /// Get audience DNA insights
  Future<Map<String, dynamic>> getAudienceDNA({
    required String sponsoredElectionId,
  }) async {
    try {
      final votes = await _client
          .from('ad_vote_tracking')
          .select('user_id, user_profiles!inner(*)')
          .eq('sponsored_election_id', sponsoredElectionId);

      // Mock audience insights
      return {
        'voter_levels': {
          'novice': (votes.length * 0.2).round(),
          'intermediate': (votes.length * 0.5).round(),
          'expert': (votes.length * 0.3).round(),
        },
        'badge_holdings': {
          'film_critic': (votes.length * 0.4).round(),
          'tech_guru': (votes.length * 0.3).round(),
          'sports_fan': (votes.length * 0.3).round(),
        },
        'interest_categories': {
          'entertainment': (votes.length * 0.5).round(),
          'technology': (votes.length * 0.3).round(),
          'sports': (votes.length * 0.2).round(),
        },
        'engagement_quality': 'high', // Mock quality score
      };
    } catch (e) {
      debugPrint('Get audience DNA error: $e');
      return {};
    }
  }

  /// Get Claude AI optimization recommendations
  Future<List<Map<String, dynamic>>> getOptimizationRecommendations({
    required String sponsoredElectionId,
  }) async {
    try {
      // Get campaign performance data
      final campaign = await _client
          .from('sponsored_elections')
          .select('*, ad_vote_tracking(*)')
          .eq('id', sponsoredElectionId)
          .single();

      // Get pulse data for analysis
      final pulseData = await getRealTimePulseData(
        sponsoredElectionId: sponsoredElectionId,
        timeframe: 'hourly',
      );

      // Mock Claude recommendations based on data
      final recommendations = <Map<String, dynamic>>[];

      // Peak engagement window
      if (pulseData.isNotEmpty) {
        recommendations.add({
          'type': 'peak_engagement',
          'title': 'Optimal Posting Time',
          'description':
              'Your ads perform 40% better Friday 8-10pm with Film Critic badge holders',
          'impact': 'high',
          'action': 'Schedule campaigns during peak hours',
        });
      }

      // Budget optimization
      final engagementRate = (campaign['engagement_rate'] ?? 0.0) as num;
      if (engagementRate < 5.0) {
        recommendations.add({
          'type': 'budget_optimization',
          'title': 'Shift Budget to High-Performers',
          'description':
              'Reallocate 30% of budget to audience segments with 2x engagement',
          'impact': 'medium',
          'action': 'Adjust targeting parameters',
        });
      }

      // Audience expansion
      recommendations.add({
        'type': 'audience_expansion',
        'title': 'Expand to Similar Audiences',
        'description':
            'Tech enthusiasts show 25% higher engagement - consider expanding',
        'impact': 'medium',
        'action': 'Add tech interest category to targeting',
      });

      return recommendations;
    } catch (e) {
      debugPrint('Get optimization recommendations error: $e');
      return [];
    }
  }

  /// Pause campaign
  Future<bool> pauseCampaign({
    required String sponsoredElectionId,
    required String reason,
  }) async {
    try {
      await _client
          .from('sponsored_elections')
          .update({
            'status': 'paused',
            'paused_at': DateTime.now().toIso8601String(),
            'paused_by': _auth.currentUser!.id,
            'pause_reason': reason,
          })
          .eq('id', sponsoredElectionId);

      return true;
    } catch (e) {
      debugPrint('Pause campaign error: $e');
      return false;
    }
  }

  /// Resume campaign
  Future<bool> resumeCampaign({required String sponsoredElectionId}) async {
    try {
      await _client
          .from('sponsored_elections')
          .update({
            'status': 'active',
            'paused_at': null,
            'paused_by': null,
            'pause_reason': null,
          })
          .eq('id', sponsoredElectionId);

      return true;
    } catch (e) {
      debugPrint('Resume campaign error: $e');
      return false;
    }
  }

  /// Track ad vote with 2x XP reward
  Future<bool> trackAdVote({
    required String sponsoredElectionId,
    required String voteId,
    required double costCharged,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Get reward multiplier from sponsored election
      final campaign = await _client
          .from('sponsored_elections')
          .select('reward_multiplier')
          .eq('id', sponsoredElectionId)
          .single();

      final rewardMultiplier = (campaign['reward_multiplier'] ?? 2.0) as num;
      final baseXP = 10;
      final xpAwarded = (baseXP * rewardMultiplier).round();

      // Track vote
      await _client.from('ad_vote_tracking').insert({
        'sponsored_election_id': sponsoredElectionId,
        'user_id': _auth.currentUser!.id,
        'vote_id': voteId,
        'cost_charged': costCharged,
        'xp_awarded': xpAwarded,
        'vote_status': 'charged',
      });

      // Award XP to user
      await _client.from('xp_log').insert({
        'user_id': _auth.currentUser!.id,
        'action_type': 'VOTE_SPONSORED_ELECTION',
        'xp_earned': xpAwarded,
        'reference_id': sponsoredElectionId,
      });

      return true;
    } catch (e) {
      debugPrint('Track ad vote error: $e');
      return false;
    }
  }
}
