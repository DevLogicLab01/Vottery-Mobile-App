import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class SponsoredElectionsService {
  static SponsoredElectionsService? _instance;
  static SponsoredElectionsService get instance =>
      _instance ??= SponsoredElectionsService._();

  SponsoredElectionsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  static const List<String> _zoneIds = [
    '1', '2', '3', '4', '5', '6', '7', '8',
  ];
  static const List<String> _zoneNames = [
    'US & Canada',
    'Western Europe',
    'Eastern Europe & Russia',
    'Africa',
    'Latin America & Caribbean',
    'Middle East, Asia, Eurasia, Melanesia, Micronesia, Polynesia',
    'Australasia (AU, NZ, Taiwan, South Korea, Japan, Singapore)',
    'China, Macau & Hong Kong',
  ];

  List<Map<String, dynamic>> _ensureZoneBreakdown(List<Map<String, dynamic>> list) {
    return list.map((c) {
      final map = Map<String, dynamic>.from(c);
      if (!map.containsKey('zone_breakdown') || map['zone_breakdown'] == null) {
        final zoneSpecific = map['zone_specific_budget'] as Map<String, dynamic>? ?? map['zone_targeting'] as Map<String, dynamic>? ?? map['zone_specific_participants'] as Map<String, dynamic>?;
        final zoneBreakdown = <String, dynamic>{};
        for (var i = 0; i < _zoneIds.length; i++) {
          final key = _zoneIds[i];
          zoneBreakdown[key] = zoneSpecific?[key] ?? 0;
        }
        map['zone_breakdown'] = zoneBreakdown;
      }
      return map;
    }).toList();
  }

  /// Get active sponsored elections
  Future<List<Map<String, dynamic>>> getActiveSponsoredElections() async {
    try {
      final response = await _client
          .from('sponsored_elections')
          .select('''
            *,
            election:elections(*),
            campaign:brand_partnerships(*),
            brand:user_profiles!sponsored_elections_brand_id_fkey(
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return _ensureZoneBreakdown(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Get active sponsored elections error: $e');
      return [];
    }
  }

  /// Get sponsored elections by brand
  Future<List<Map<String, dynamic>>> getBrandSponsoredElections({
    required String brandId,
  }) async {
    try {
      final response = await _client
          .from('sponsored_elections')
          .select('''
            *,
            election:elections(*),
            campaign:brand_partnerships(*)
          ''')
          .eq('brand_id', brandId)
          .order('created_at', ascending: false);

      return _ensureZoneBreakdown(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Get brand sponsored elections error: $e');
      return [];
    }
  }

  /// Create sponsored election — column names aligned with Web `sponsoredElectionsService.js`
  /// and `public.sponsored_elections` (`budget_total`, `cost_per_vote`, `ad_format_type`, …).
  Future<String?> createSponsoredElection({
    required String electionId,
    required String adFormatType,
    required double budgetTotal,
    required double costPerVote,
    double rewardMultiplier = 2.0,
    List<String> targetAudienceTags = const [],
    List<String> zoneTargeting = const [],
    double? auctionBidAmount,
    int frequencyCap = 3,
    String? conversionPixelUrl,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final response = await _client
          .from('sponsored_elections')
          .insert({
            'election_id': electionId,
            'brand_id': _auth.currentUser!.id,
            'ad_format_type': adFormatType,
            'budget_total': budgetTotal,
            'cost_per_vote': costPerVote,
            'reward_multiplier': rewardMultiplier,
            'target_audience_tags': targetAudienceTags,
            'zone_targeting': zoneTargeting,
            if (auctionBidAmount != null) 'auction_bid_amount': auctionBidAmount,
            'frequency_cap': frequencyCap,
            if (conversionPixelUrl != null)
              'conversion_pixel_url': conversionPixelUrl,
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Create sponsored election error: $e');
      return null;
    }
  }

  /// Pause sponsored election
  Future<bool> pauseSponsoredElection({
    required String sponsoredElectionId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('sponsored_elections')
          .update({
            // Schema-aligned: `public.sponsored_elections` has `status` + timestamps only
            // (Web: `toggleSponsoredElectionStatus` / `updateSponsoredElection`).
            'status': 'paused',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sponsoredElectionId);

      return true;
    } catch (e) {
      debugPrint('Pause sponsored election error: $e');
      return false;
    }
  }

  /// Resume sponsored election
  Future<bool> resumeSponsoredElection({
    required String sponsoredElectionId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('sponsored_elections')
          .update({
            'status': 'active',
            'paused_at': null,
            'paused_by': null,
            'pause_reason': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sponsoredElectionId);

      return true;
    } catch (e) {
      debugPrint('Resume sponsored election error: $e');
      return false;
    }
  }

  /// Update sponsored election
  Future<bool> updateSponsoredElection({
    required String sponsoredElectionId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('sponsored_elections')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', sponsoredElectionId);

      return true;
    } catch (e) {
      debugPrint('Update sponsored election error: $e');
      return false;
    }
  }

  /// Get engagement metrics by zone
  Future<Map<String, dynamic>> getEngagementMetricsByZone({
    required String sponsoredElectionId,
  }) async {
    try {
      final response = await _client
          .from('sponsored_elections')
          .select()
          .eq('id', sponsoredElectionId)
          .maybeSingle();

      if (response == null) return {};

      return {
        'zone_participants': response['zone_specific_participants'] ??
            response['zone_targeting'] ??
            {},
        'engagement_metrics': response['engagement_metrics'] ?? {},
      };
    } catch (e) {
      debugPrint('Get engagement metrics by zone error: $e');
      return {};
    }
  }

  /// Get real-time sponsored election stream
  Stream<List<Map<String, dynamic>>> getSponsoredElectionsStream({
    String? brandId,
  }) {
    try {
      var query = _client
          .from('sponsored_elections')
          .stream(primaryKey: ['id']);

      if (brandId != null) {
        query = query.eq('brand_id', brandId) as SupabaseStreamFilterBuilder;
      }

      return query
          .order('created_at', ascending: false)
          .map((data) => List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Get sponsored elections stream error: $e');
      return Stream.value([]);
    }
  }

  /// CPE pricing zones — Web parity: `sponsoredElectionsService.getCPEPricingZones`.
  Future<List<Map<String, dynamic>>> getCPEPricingZones() async {
    try {
      final response = await _client
          .from('cpe_pricing_zones')
          .select('*')
          .order('purchasing_power_index', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Get CPE pricing zones error: $e');
      return [];
    }
  }

  /// Aggregates by ad format — Web parity: `getAdFormatStatistics`.
  Future<Map<String, Map<String, dynamic>>> getAdFormatStatistics() async {
    const keys = ['MARKET_RESEARCH', 'HYPE_PREDICTION', 'CSR'];
    Map<String, Map<String, dynamic>> empty() => {
          for (final k in keys)
            k: {
              'campaigns': 0,
              'engagements': 0,
              'impressions': 0,
              'revenue': 0.0,
            },
        };
    try {
      final response = await _client.from('sponsored_elections').select(
            'ad_format_type, total_engagements, total_impressions, generated_revenue',
          );
      final stats = empty();
      for (final row in response as List) {
        final format = row['ad_format_type'] as String?;
        if (format == null || !stats.containsKey(format)) continue;
        final s = stats[format]!;
        s['campaigns'] = (s['campaigns'] as int) + 1;
        s['engagements'] =
            (s['engagements'] as int) + ((row['total_engagements'] ?? 0) as num).toInt();
        s['impressions'] =
            (s['impressions'] as int) + ((row['total_impressions'] ?? 0) as num).toInt();
        s['revenue'] = (s['revenue'] as double) +
            ((row['generated_revenue'] ?? 0) as num).toDouble();
      }
      return stats;
    } catch (e) {
      debugPrint('Get ad format statistics error: $e');
      return empty();
    }
  }

  /// Revenue rollup for a brand in a date window — Web parity: `getRevenueAnalytics`.
  Future<Map<String, dynamic>> getRevenueAnalytics({
    required String brandId,
    required String startDateIso,
    required String endDateIso,
  }) async {
    try {
      final data = await _client
          .from('sponsored_elections')
          .select('*, election:elections(title, category)')
          .eq('brand_id', brandId)
          .gte('created_at', startDateIso)
          .lte('created_at', endDateIso);

      final rows = List<Map<String, dynamic>>.from(data as List);
      final analytics = <String, dynamic>{
        'totalCampaigns': rows.length,
        'totalSpent': 0.0,
        'totalRevenue': 0.0,
        'totalEngagements': 0,
        'totalImpressions': 0,
        'averageCPE': '0',
        'averageEngagementRate': '0',
        'byFormat': {
          'MARKET_RESEARCH': {'count': 0, 'revenue': 0.0, 'engagements': 0},
          'HYPE_PREDICTION': {'count': 0, 'revenue': 0.0, 'engagements': 0},
          'CSR': {'count': 0, 'revenue': 0.0, 'engagements': 0},
        },
      };

      for (final campaign in rows) {
        analytics['totalSpent'] =
            (analytics['totalSpent'] as double) +
                ((campaign['budget_spent'] ?? 0) as num).toDouble();
        analytics['totalRevenue'] =
            (analytics['totalRevenue'] as double) +
                ((campaign['generated_revenue'] ?? 0) as num).toDouble();
        analytics['totalEngagements'] =
            (analytics['totalEngagements'] as int) +
                ((campaign['total_engagements'] ?? 0) as num).toInt();
        analytics['totalImpressions'] =
            (analytics['totalImpressions'] as int) +
                ((campaign['total_impressions'] ?? 0) as num).toInt();

        final format = campaign['ad_format_type'] as String?;
        final byFormat = analytics['byFormat'] as Map<String, dynamic>;
        if (format != null && byFormat.containsKey(format)) {
          final bf = Map<String, dynamic>.from(byFormat[format] as Map);
          bf['count'] = (bf['count'] as int) + 1;
          bf['revenue'] =
              (bf['revenue'] as double) +
                  ((campaign['generated_revenue'] ?? 0) as num).toDouble();
          bf['engagements'] =
              (bf['engagements'] as int) +
                  ((campaign['total_engagements'] ?? 0) as num).toInt();
          byFormat[format] = bf;
        }
      }

      final te = analytics['totalEngagements'] as int;
      final ti = analytics['totalImpressions'] as int;
      final ts = analytics['totalSpent'] as double;
      analytics['averageCPE'] =
          te > 0 ? (ts / te).toStringAsFixed(2) : '0';
      analytics['averageEngagementRate'] =
          ti > 0 ? ((te / ti) * 100).toStringAsFixed(2) : '0';

      return analytics;
    } catch (e) {
      debugPrint('Get revenue analytics error: $e');
      return {
        'totalCampaigns': 0,
        'totalSpent': 0.0,
        'totalRevenue': 0.0,
        'totalEngagements': 0,
        'totalImpressions': 0,
        'averageCPE': '0',
        'averageEngagementRate': '0',
        'byFormat': {},
      };
    }
  }

  /// Calculate ROI
  Future<double> calculateROI({required String sponsoredElectionId}) async {
    try {
      final response = await _client
          .from('sponsored_elections')
          .select('spent_budget, budget_spent')
          .eq('id', sponsoredElectionId)
          .maybeSingle();

      if (response == null) return 0.0;

      final spentBudget = (response['spent_budget'] ?? response['budget_spent'] ?? 0.0) as num;

      // Get revenue generated from campaign analytics
      final analyticsResponse = await _client
          .from('campaign_analytics')
          .select('revenue_generated')
          .eq('sponsored_election_id', sponsoredElectionId)
          .maybeSingle();

      final revenueGenerated =
          (analyticsResponse?['revenue_generated'] ?? 0.0) as num;

      if (spentBudget == 0) return 0.0;

      final roi =
          ((revenueGenerated.toDouble() - spentBudget.toDouble()) /
              spentBudget.toDouble()) *
          100;

      return roi;
    } catch (e) {
      debugPrint('Calculate ROI error: $e');
      return 0.0;
    }
  }
}
