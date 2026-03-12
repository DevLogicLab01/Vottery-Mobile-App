import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './vp_service.dart';

class JoltsService {
  static JoltsService? _instance;
  static JoltsService get instance => _instance ??= JoltsService._();

  JoltsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  VPService get _vpService => VPService.instance;

  /// Get published Jolts feed
  Future<List<Map<String, dynamic>>> getJoltsFeed({int limit = 20}) async {
    try {
      final response = await _client
          .from('jolts')
          .select('*, creator:user_profiles!creator_id(*)')
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get Jolts feed error: $e');
      return [];
    }
  }

  /// Create Jolt
  Future<String?> createJolt({
    required String title,
    String? description,
    required String videoUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    String? electionId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('jolts')
          .insert({
            'creator_id': _auth.currentUser!.id,
            'title': title,
            'description': description,
            'video_url': videoUrl,
            'thumbnail_url': thumbnailUrl,
            'duration_seconds': durationSeconds,
            'election_id': electionId,
            'status': 'published',
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Create Jolt error: $e');
      return null;
    }
  }

  /// Like Jolt
  Future<bool> likeJolt(String joltId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('jolt_interactions').insert({
        'jolt_id': joltId,
        'user_id': _auth.currentUser!.id,
        'interaction_type': 'like',
      });

      await _client.rpc(
        'increment',
        params: {
          'table_name': 'jolts',
          'row_id': joltId,
          'column_name': 'like_count',
        },
      );

      // Award VP for social interaction
      await _vpService.awardSocialVP('jolt_like', joltId);

      return true;
    } catch (e) {
      debugPrint('Like Jolt error: $e');
      return false;
    }
  }

  /// Comment on Jolt
  Future<bool> commentOnJolt({
    required String joltId,
    required String commentText,
    String? parentCommentId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('jolt_comments').insert({
        'jolt_id': joltId,
        'user_id': _auth.currentUser!.id,
        'comment_text': commentText,
        'parent_comment_id': parentCommentId,
      });

      await _client.rpc(
        'increment',
        params: {
          'table_name': 'jolts',
          'row_id': joltId,
          'column_name': 'comment_count',
        },
      );

      // Award VP for social interaction
      await _vpService.awardSocialVP('jolt_comment', joltId);

      return true;
    } catch (e) {
      debugPrint('Comment on Jolt error: $e');
      return false;
    }
  }

  /// Get Jolt comments
  Future<List<Map<String, dynamic>>> getJoltComments(String joltId) async {
    try {
      final response = await _client
          .from('jolt_comments')
          .select('*, user:user_profiles!user_id(*)')
          .eq('jolt_id', joltId)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get Jolt comments error: $e');
      return [];
    }
  }

  /// Increment view count
  Future<void> incrementViewCount(String joltId) async {
    try {
      await _client.rpc(
        'increment',
        params: {
          'table_name': 'jolts',
          'row_id': joltId,
          'column_name': 'view_count',
        },
      );
    } catch (e) {
      debugPrint('Increment view count error: $e');
    }
  }

  /// Share Jolt
  Future<bool> shareJolt(String joltId) async {
    try {
      await _client.rpc(
        'increment',
        params: {
          'table_name': 'jolts',
          'row_id': joltId,
          'column_name': 'share_count',
        },
      );

      // Award VP for social interaction
      await _vpService.awardSocialVP('jolt_share', joltId);

      return true;
    } catch (e) {
      debugPrint('Share Jolt error: $e');
      return false;
    }
  }

  /// Award Jolts VP (called from various Jolts actions)
  Future<bool> awardJoltsVP({
    required String joltId,
    required String earningType,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final response = await _client.rpc(
        'award_jolts_vp',
        params: {
          'p_user_id': _auth.currentUser!.id,
          'p_jolt_id': joltId,
          'p_earning_type': earningType,
        },
      );

      return response['success'] == true;
    } catch (e) {
      debugPrint('Award Jolts VP error: $e');
      return false;
    }
  }

  /// Track Jolt view and award VP
  Future<bool> trackJoltView(String joltId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Record view
      await _client.from('jolt_interactions').insert({
        'jolt_id': joltId,
        'user_id': _auth.currentUser!.id,
        'interaction_type': 'view',
      });

      // Award viewing VP (2 VP)
      await awardJoltsVP(joltId: joltId, earningType: 'viewing');

      return true;
    } catch (e) {
      debugPrint('Track Jolt view error: $e');
      return false;
    }
  }

  /// Get user's Jolts creator badges
  Future<List<Map<String, dynamic>>> getUserJoltsCreatorBadges() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('user_jolts_creator_badges')
          .select('*, jolts_creator_badges(*)')
          .eq('user_id', _auth.currentUser!.id);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get Jolts creator badges error: $e');
      return [];
    }
  }

  /// Get Jolts VP earnings summary
  Future<Map<String, dynamic>> getJoltsVPEarningsSummary() async {
    try {
      if (!_auth.isAuthenticated) return {};

      final response = await _client
          .from('jolts_vp_earnings')
          .select('earning_type, vp_amount')
          .eq('user_id', _auth.currentUser!.id);

      final earnings = List<Map<String, dynamic>>.from(response);

      int totalVP = 0;
      int creationVP = 0;
      int viewingVP = 0;
      int votingVP = 0;
      int sharingVP = 0;

      for (final earning in earnings) {
        final type = earning['earning_type'] as String;
        final vp = earning['vp_amount'] as int;
        totalVP += vp;

        switch (type) {
          case 'creation':
            creationVP += vp;
            break;
          case 'viewing':
            viewingVP += vp;
            break;
          case 'voting':
            votingVP += vp;
            break;
          case 'sharing':
            sharingVP += vp;
            break;
        }
      }

      return {
        'total_vp': totalVP,
        'creation_vp': creationVP,
        'viewing_vp': viewingVP,
        'voting_vp': votingVP,
        'sharing_vp': sharingVP,
      };
    } catch (e) {
      debugPrint('Get Jolts VP earnings summary error: $e');
      return {};
    }
  }
}
