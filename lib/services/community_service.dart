import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './vp_service.dart';

/// Service for managing community spaces and elections
class CommunityService {
  static CommunityService? _instance;
  static CommunityService get instance => _instance ??= CommunityService._();

  CommunityService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  VPService get _vpService => VPService.instance;

  /// Get all communities
  Future<List<Map<String, dynamic>>> getCommunities({
    String? topic,
    String? privacyLevel,
    bool? featured,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('communities').select();

      if (topic != null) {
        query = query.eq('topic', topic);
      }

      if (privacyLevel != null) {
        query = query.eq('privacy_level', privacyLevel);
      }

      if (featured != null) {
        query = query.eq('featured', featured);
      }

      final response = await query
          .eq('is_active', true)
          .order('member_count', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get communities error: $e');
      return [];
    }
  }

  /// Get community by ID
  Future<Map<String, dynamic>?> getCommunityById(String communityId) async {
    try {
      final response = await _client
          .from('communities')
          .select('*, creator:user_profiles!creator_id(*)')
          .eq('id', communityId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get community error: $e');
      return null;
    }
  }

  /// Create community
  Future<String?> createCommunity({
    required String name,
    required String topic,
    required String description,
    required String privacyLevel,
    bool electionApprovalRequired = false,
    String postingPermissions = 'all_members',
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('communities')
          .insert({
            'name': name,
            'topic': topic,
            'description': description,
            'creator_id': _auth.currentUser!.id,
            'privacy_level': privacyLevel,
            'election_approval_required': electionApprovalRequired,
            'posting_permissions': postingPermissions,
          })
          .select()
          .single();

      final communityId = response['id'];

      // Add creator as admin member
      await _client.from('community_members').insert({
        'community_id': communityId,
        'user_id': _auth.currentUser!.id,
        'role': 'admin',
      });

      // Initialize analytics
      await _client.from('community_analytics').insert({
        'community_id': communityId,
      });

      // Award VP for community creation
      await _vpService.awardSocialVP('community_create', communityId);

      return communityId;
    } catch (e) {
      debugPrint('Create community error: $e');
      return null;
    }
  }

  /// Join community
  Future<bool> joinCommunity(String communityId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Check if community is public
      final community = await getCommunityById(communityId);
      if (community == null) return false;

      if (community['privacy_level'] == 'public') {
        // Direct join for public communities
        await _client.from('community_members').insert({
          'community_id': communityId,
          'user_id': _auth.currentUser!.id,
          'role': 'member',
        });

        await _vpService.awardSocialVP('community_join', communityId);
        return true;
      } else {
        // Create join request for private/invite-only
        await _client.from('community_join_requests').insert({
          'community_id': communityId,
          'user_id': _auth.currentUser!.id,
          'status': 'pending',
        });
        return false; // Pending approval
      }
    } catch (e) {
      debugPrint('Join community error: $e');
      return false;
    }
  }

  /// Leave community
  Future<bool> leaveCommunity(String communityId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('community_members')
          .delete()
          .eq('community_id', communityId)
          .eq('user_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Leave community error: $e');
      return false;
    }
  }

  /// Get user's communities
  Future<List<Map<String, dynamic>>> getUserCommunities() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('community_members')
          .select('*, community:communities(*)')
          .eq('user_id', _auth.currentUser!.id)
          .order('joined_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user communities error: $e');
      return [];
    }
  }

  /// Get community elections
  Future<List<Map<String, dynamic>>> getCommunityElections(
    String communityId,
  ) async {
    try {
      final response = await _client
          .from('community_elections')
          .select('*, election:elections(*)')
          .eq('community_id', communityId)
          .eq('approval_status', 'approved')
          .order('posted_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get community elections error: $e');
      return [];
    }
  }

  /// Post election to community
  Future<bool> postElectionToCommunity({
    required String communityId,
    required String electionId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Check if user is a member
      final membership = await _client
          .from('community_members')
          .select()
          .eq('community_id', communityId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      if (membership == null) return false;

      // Get community settings
      final community = await getCommunityById(communityId);
      if (community == null) return false;

      final approvalRequired = community['election_approval_required'] ?? false;

      await _client.from('community_elections').insert({
        'community_id': communityId,
        'election_id': electionId,
        'posted_by': _auth.currentUser!.id,
        'approval_status': approvalRequired ? 'pending' : 'approved',
      });

      return true;
    } catch (e) {
      debugPrint('Post election to community error: $e');
      return false;
    }
  }

  /// Get community analytics
  Future<Map<String, dynamic>?> getCommunityAnalytics(
    String communityId,
  ) async {
    try {
      final response = await _client
          .from('community_analytics')
          .select()
          .eq('community_id', communityId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get community analytics error: $e');
      return null;
    }
  }

  /// Search communities
  Future<List<Map<String, dynamic>>> searchCommunities(String query) async {
    try {
      final response = await _client
          .from('communities')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .eq('is_active', true)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Search communities error: $e');
      return [];
    }
  }

  /// Update community member role
  Future<bool> updateMemberRole({
    required String communityId,
    required String userId,
    required String newRole,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Check if current user is admin
      final currentUserMembership = await _client
          .from('community_members')
          .select()
          .eq('community_id', communityId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      if (currentUserMembership == null ||
          currentUserMembership['role'] != 'admin') {
        return false;
      }

      await _client
          .from('community_members')
          .update({'role': newRole})
          .eq('community_id', communityId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('Update member role error: $e');
      return false;
    }
  }

  /// Ban community member
  Future<bool> banMember({
    required String communityId,
    required String userId,
    required String reason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('community_members')
          .update({
            'is_banned': true,
            'banned_at': DateTime.now().toIso8601String(),
            'banned_by': _auth.currentUser!.id,
            'ban_reason': reason,
          })
          .eq('community_id', communityId)
          .eq('user_id', userId);

      // Log moderation action
      await _client.from('community_moderation_logs').insert({
        'community_id': communityId,
        'moderator_id': _auth.currentUser!.id,
        'action_type': 'member_banned',
        'target_user_id': userId,
        'reason': reason,
      });

      return true;
    } catch (e) {
      debugPrint('Ban member error: $e');
      return false;
    }
  }
}
