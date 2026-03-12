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

  /// Create sponsored election
  Future<String?> createSponsoredElection({
    required String electionId,
    required String campaignId,
    required String sponsoredType,
    required double totalBudget,
    required double costPerParticipant,
    required int targetParticipants,
    Map<String, dynamic>? zoneSpecificBudget,
    bool doubleXpEnabled = true,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final response = await _client
          .from('sponsored_elections')
          .insert({
            'election_id': electionId,
            'brand_partnership_id': campaignId,
            'brand_id': _auth.currentUser!.id,
            'sponsored_type': sponsoredType,
            'status': 'draft',
            'total_budget': totalBudget,
            'cost_per_participant': costPerParticipant,
            'target_participants': targetParticipants,
            'zone_specific_budget': zoneSpecificBudget ?? {},
            'double_xp_enabled': doubleXpEnabled,
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
    required String pauseReason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('sponsored_elections')
          .update({
            'status': 'paused',
            'paused_at': DateTime.now().toIso8601String(),
            'paused_by': _auth.currentUser!.id,
            'pause_reason': pauseReason,
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
          .select('zone_specific_participants, zone_targeting, engagement_metrics')
          .eq('id', sponsoredElectionId)
          .maybeSingle();

      if (response == null) return {};

      return {
        'zone_participants': response['zone_specific_participants'] ?? response['zone_targeting'] ?? {},
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
