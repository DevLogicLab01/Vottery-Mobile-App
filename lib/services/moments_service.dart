import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './vp_service.dart';

class MomentsService {
  static MomentsService? _instance;
  static MomentsService get instance => _instance ??= MomentsService._();

  MomentsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  VPService get _vpService => VPService.instance;

  /// Create moment (story)
  Future<String?> createMoment({
    required String mediaUrl,
    required String mediaType,
    String? thumbnailUrl,
    String? caption,
    int durationSeconds = 5,
    String? backgroundColor,
    Map<String, dynamic>? textOverlay,
    String? musicUrl,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final expiresAt = DateTime.now().add(const Duration(hours: 24));

      final response = await _client
          .from('moments')
          .insert({
            'creator_id': _auth.currentUser!.id,
            'media_url': mediaUrl,
            'media_type': mediaType,
            'thumbnail_url': thumbnailUrl,
            'caption': caption,
            'duration_seconds': durationSeconds,
            'background_color': backgroundColor,
            'text_overlay': textOverlay,
            'music_url': musicUrl,
            'expires_at': expiresAt.toIso8601String(),
            'status': 'active',
          })
          .select()
          .single();

      // Award VP for creating moment
      await _vpService.awardSocialVP('moment_create', response['id']);

      return response['id'] as String;
    } catch (e) {
      debugPrint('Create moment error: $e');
      return null;
    }
  }

  /// Get active moments from followed users
  Future<List<Map<String, dynamic>>> getFollowingMoments() async {
    try {
      if (!_auth.isAuthenticated) return [];

      // Get users current user follows
      final following = await _client
          .from('user_followers')
          .select('following_id')
          .eq('follower_id', _auth.currentUser!.id);

      final followingIds = following
          .map((f) => f['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

      // Get active moments from followed users
      final response = await _client
          .from('moments')
          .select('*, creator:user_profiles!creator_id(*)')
          .inFilter('creator_id', followingIds)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get following moments error: $e');
      return [];
    }
  }

  /// Get user's own moments
  Future<List<Map<String, dynamic>>> getMyMoments() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('moments')
          .select('*, creator:user_profiles!creator_id(*)')
          .eq('creator_id', _auth.currentUser!.id)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get my moments error: $e');
      return [];
    }
  }

  /// Get moments by user ID
  Future<List<Map<String, dynamic>>> getUserMoments(String userId) async {
    try {
      final response = await _client
          .from('moments')
          .select('*, creator:user_profiles!creator_id(*)')
          .eq('creator_id', userId)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user moments error: $e');
      return [];
    }
  }

  /// Record moment view
  Future<bool> recordView(String momentId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('moment_views').insert({
        'moment_id': momentId,
        'viewer_id': _auth.currentUser!.id,
      });

      // Increment view count
      await _client.rpc(
        'increment',
        params: {
          'table_name': 'moments',
          'row_id': momentId,
          'column_name': 'view_count',
        },
      );

      return true;
    } catch (e) {
      debugPrint('Record moment view error: $e');
      return false;
    }
  }

  /// React to moment
  Future<bool> reactToMoment({
    required String momentId,
    required String emoji,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('moment_interactions').insert({
        'moment_id': momentId,
        'user_id': _auth.currentUser!.id,
        'interaction_type': 'reaction',
        'emoji': emoji,
      });

      // Award VP for interaction
      await _vpService.awardSocialVP('moment_react', momentId);

      return true;
    } catch (e) {
      debugPrint('React to moment error: $e');
      return false;
    }
  }

  /// Get moment reactions
  Future<List<Map<String, dynamic>>> getMomentReactions(String momentId) async {
    try {
      final response = await _client
          .from('moment_interactions')
          .select('*, user:user_profiles!user_id(*)')
          .eq('moment_id', momentId)
          .eq('interaction_type', 'reaction')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get moment reactions error: $e');
      return [];
    }
  }

  /// Get moment viewers
  Future<List<Map<String, dynamic>>> getMomentViewers(String momentId) async {
    try {
      final response = await _client
          .from('moment_views')
          .select('*, viewer:user_profiles!viewer_id(*)')
          .eq('moment_id', momentId)
          .order('viewed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get moment viewers error: $e');
      return [];
    }
  }

  /// Delete moment
  Future<bool> deleteMoment(String momentId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('moments')
          .update({'status': 'archived'})
          .eq('id', momentId)
          .eq('creator_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Delete moment error: $e');
      return false;
    }
  }

  /// Get moment analytics (for creator)
  Future<Map<String, dynamic>?> getMomentAnalytics(String momentId) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final moment = await _client
          .from('moments')
          .select('*')
          .eq('id', momentId)
          .eq('creator_id', _auth.currentUser!.id)
          .single();

      final viewCount = await _client
          .from('moment_views')
          .select('id')
          .eq('moment_id', momentId);

      final reactionCount = await _client
          .from('moment_interactions')
          .select('id')
          .eq('moment_id', momentId)
          .eq('interaction_type', 'reaction');

      return {
        'moment': moment,
        'view_count': viewCount.length,
        'reaction_count': reactionCount.length,
      };
    } catch (e) {
      debugPrint('Get moment analytics error: $e');
      return null;
    }
  }

  /// Check if user has active moments
  Future<bool> hasActiveMoments(String userId) async {
    try {
      final response = await _client
          .from('moments')
          .select('id')
          .eq('creator_id', userId)
          .eq('status', 'active')
          .gt('expires_at', DateTime.now().toIso8601String());

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Check active moments error: $e');
      return false;
    }
  }
}
