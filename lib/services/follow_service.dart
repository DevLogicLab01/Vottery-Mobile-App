import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './vp_service.dart';

class FollowService {
  static FollowService? _instance;
  static FollowService get instance => _instance ??= FollowService._();

  FollowService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  VPService get _vpService => VPService.instance;

  /// Follow user
  Future<bool> followUser(String userId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('user_followers').insert({
        'follower_id': _auth.currentUser!.id,
        'following_id': userId,
      });

      // Award VP for social interaction
      await _vpService.awardSocialVP('follow_user', userId);

      return true;
    } catch (e) {
      debugPrint('Follow user error: $e');
      return false;
    }
  }

  /// Unfollow user
  Future<bool> unfollowUser(String userId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('user_followers')
          .delete()
          .eq('follower_id', _auth.currentUser!.id)
          .eq('following_id', userId);

      return true;
    } catch (e) {
      debugPrint('Unfollow user error: $e');
      return false;
    }
  }

  /// Check if following user
  Future<bool> isFollowing(String userId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final response = await _client
          .from('user_followers')
          .select('id')
          .eq('follower_id', _auth.currentUser!.id)
          .eq('following_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Check following error: $e');
      return false;
    }
  }

  /// Get followers list
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final response = await _client
          .from('user_followers')
          .select('*, follower:user_profiles!follower_id(*)')
          .eq('following_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get followers error: $e');
      return [];
    }
  }

  /// Get following list
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final response = await _client
          .from('user_followers')
          .select('*, following:user_profiles!following_id(*)')
          .eq('follower_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get following error: $e');
      return [];
    }
  }

  /// Get follower count
  Future<int> getFollowerCount(String userId) async {
    try {
      final response = await _client
          .from('user_followers')
          .select('id')
          .eq('following_id', userId);

      return response.length;
    } catch (e) {
      debugPrint('Get follower count error: $e');
      return 0;
    }
  }

  /// Get following count
  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _client
          .from('user_followers')
          .select('id')
          .eq('follower_id', userId);

      return response.length;
    } catch (e) {
      debugPrint('Get following count error: $e');
      return 0;
    }
  }

  /// Get suggested users to follow
  Future<List<Map<String, dynamic>>> getSuggestedUsers({int limit = 10}) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final currentUserId = _auth.currentUser!.id;

      final following = await _client
          .from('user_followers')
          .select('following_id')
          .eq('follower_id', currentUserId);

      final followingIds = following.map((e) => e['following_id']).toList();
      followingIds.add(currentUserId);

      final suggestions = await _client
          .from('user_profiles')
          .select('*')
          .not('id', 'in', '(${followingIds.join(',')})')
          .limit(limit);

      return List<Map<String, dynamic>>.from(suggestions);
    } catch (e) {
      debugPrint('Get suggested users error: $e');
      return [];
    }
  }

  /// Get mutual followers
  Future<List<Map<String, dynamic>>> getMutualFollowers(String userId) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final currentUserId = _auth.currentUser!.id;

      final myFollowing = await _client
          .from('user_followers')
          .select('following_id')
          .eq('follower_id', currentUserId);

      final theirFollowers = await _client
          .from('user_followers')
          .select('follower_id')
          .eq('following_id', userId);

      final myFollowingIds = myFollowing.map((e) => e['following_id']).toSet();
      final theirFollowerIds = theirFollowers
          .map((e) => e['follower_id'])
          .toSet();

      final mutualIds = myFollowingIds.intersection(theirFollowerIds).toList();

      if (mutualIds.isEmpty) return [];

      final mutuals = await _client
          .from('user_profiles')
          .select('*')
          .inFilter('id', mutualIds);

      return List<Map<String, dynamic>>.from(mutuals);
    } catch (e) {
      debugPrint('Get mutual followers error: $e');
      return [];
    }
  }
}
