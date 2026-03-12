import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './vp_service.dart';

class SocialService {
  static SocialService? _instance;
  static SocialService get instance => _instance ??= SocialService._();

  SocialService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  VPService get _vpService => VPService.instance;

  /// Get social feed with pagination for infinite scroll
  Future<Map<String, dynamic>> getSocialFeedPaginated({
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'data': [], 'hasMore': false, 'nextOffset': null};
      }

      final response = await _client
          .from('social_posts')
          .select('*, creator:user_profiles!creator_id(*)')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final list = List<Map<String, dynamic>>.from(response);
      final hasMore = list.length >= limit;

      return {
        'data': list,
        'hasMore': hasMore,
        'nextOffset': hasMore ? offset + limit : null,
      };
    } catch (e) {
      debugPrint('Get social feed paginated error: $e');
      return {'data': [], 'hasMore': false, 'nextOffset': null};
    }
  }

  /// Get social feed (backward compat)
  Future<List<Map<String, dynamic>>> getSocialFeed({int limit = 50}) async {
    final result = await getSocialFeedPaginated(offset: 0, limit: limit);
    return List<Map<String, dynamic>>.from(result['data'] ?? []);
  }

  /// Send friend request
  Future<bool> sendFriendRequest(String userId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('friend_requests').insert({
        'requester_id': _auth.currentUser!.id,
        'recipient_id': userId,
        'status': 'pending',
      });

      await _vpService.awardSocialVP('friend_request', userId);

      return true;
    } catch (e) {
      debugPrint('Send friend request error: $e');
      return false;
    }
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('friend_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      final request = await _client
          .from('friend_requests')
          .select('requester_id, recipient_id')
          .eq('id', requestId)
          .single();

      await _client.from('friendships').insert({
        'user_id': request['requester_id'],
        'friend_id': request['recipient_id'],
      });

      await _client.from('friendships').insert({
        'user_id': request['recipient_id'],
        'friend_id': request['requester_id'],
      });

      await _vpService.awardSocialVP('accept_friend', request['requester_id']);

      return true;
    } catch (e) {
      debugPrint('Accept friend request error: $e');
      return false;
    }
  }

  /// Reject friend request
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('friend_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId);

      return true;
    } catch (e) {
      debugPrint('Reject friend request error: $e');
      return false;
    }
  }

  /// Remove friend
  Future<bool> removeFriend(String friendId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final currentUserId = _auth.currentUser!.id;

      await _client
          .from('friendships')
          .delete()
          .eq('user_id', currentUserId)
          .eq('friend_id', friendId);

      await _client
          .from('friendships')
          .delete()
          .eq('user_id', friendId)
          .eq('friend_id', currentUserId);

      return true;
    } catch (e) {
      debugPrint('Remove friend error: $e');
      return false;
    }
  }

  /// Check if users are friends
  Future<bool> isFriend(String userId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final response = await _client
          .from('friendships')
          .select('id')
          .eq('user_id', _auth.currentUser!.id)
          .eq('friend_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Check friend status error: $e');
      return false;
    }
  }

  /// Get friends list
  Future<List<Map<String, dynamic>>> getFriends() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('friendships')
          .select('*, friend:user_profiles!friend_id(*)')
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(
        response.map((item) => item['friend'] as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('Get friends error: $e');
      return [];
    }
  }

  /// Get pending friend requests
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('friend_requests')
          .select('*, requester:user_profiles!requester_id(*)')
          .eq('recipient_id', _auth.currentUser!.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get pending requests error: $e');
      return [];
    }
  }

  /// Get sent friend requests
  Future<List<Map<String, dynamic>>> getSentRequests() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('friend_requests')
          .select('*, recipient:user_profiles!recipient_id(*)')
          .eq('requester_id', _auth.currentUser!.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get sent requests error: $e');
      return [];
    }
  }

  /// Get mutual friends
  Future<List<Map<String, dynamic>>> getMutualFriends(String userId) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final currentUserId = _auth.currentUser!.id;

      final myFriends = await _client
          .from('friendships')
          .select('friend_id')
          .eq('user_id', currentUserId);

      final theirFriends = await _client
          .from('friendships')
          .select('friend_id')
          .eq('user_id', userId);

      final myFriendIds = myFriends.map((e) => e['friend_id']).toSet();
      final theirFriendIds = theirFriends.map((e) => e['friend_id']).toSet();

      final mutualIds = myFriendIds.intersection(theirFriendIds).toList();

      if (mutualIds.isEmpty) return [];

      final mutuals = await _client
          .from('user_profiles')
          .select('*')
          .inFilter('id', mutualIds);

      return List<Map<String, dynamic>>.from(mutuals);
    } catch (e) {
      debugPrint('Get mutual friends error: $e');
      return [];
    }
  }

  /// Get friend count
  Future<int> getFriendCount(String userId) async {
    try {
      final response = await _client
          .from('friendships')
          .select('id')
          .eq('user_id', userId);

      return response.length;
    } catch (e) {
      debugPrint('Get friend count error: $e');
      return 0;
    }
  }
}
