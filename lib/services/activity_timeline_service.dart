import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class ActivityTimelineService {
  static ActivityTimelineService? _instance;
  static ActivityTimelineService get instance =>
      _instance ??= ActivityTimelineService._();

  ActivityTimelineService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get user activity timeline
  Future<List<Map<String, dynamic>>> getUserActivityTimeline({
    int limit = 50,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('user_activity_timeline')
          .select('''
            *,
            actor:user_profiles!user_activity_timeline_actor_id_fkey(
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user activity timeline error: $e');
      return [];
    }
  }

  /// Get activity timeline by type
  Future<List<Map<String, dynamic>>> getActivityByType({
    required String activityType,
    int limit = 50,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('user_activity_timeline')
          .select('''
            *,
            actor:user_profiles!user_activity_timeline_actor_id_fkey(
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('user_id', _auth.currentUser!.id)
          .eq('activity_type', activityType)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get activity by type error: $e');
      return [];
    }
  }

  /// Get friend voting activities
  Future<List<Map<String, dynamic>>> getFriendVotingActivities() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('user_activity_timeline')
          .select('''
            *,
            actor:user_profiles!user_activity_timeline_actor_id_fkey(
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('user_id', _auth.currentUser!.id)
          .eq('activity_type', 'friend_voted')
          .order('created_at', ascending: false)
          .limit(30);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get friend voting activities error: $e');
      return [];
    }
  }

  /// Get achievement activities
  Future<List<Map<String, dynamic>>> getAchievementActivities() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('user_activity_timeline')
          .select('''
            *,
            actor:user_profiles!user_activity_timeline_actor_id_fkey(
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('user_id', _auth.currentUser!.id)
          .eq('activity_type', 'achievement_unlocked')
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get achievement activities error: $e');
      return [];
    }
  }

  /// Get social interaction activities
  Future<List<Map<String, dynamic>>> getSocialInteractionActivities() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('user_activity_timeline')
          .select('''
            *,
            actor:user_profiles!user_activity_timeline_actor_id_fkey(
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('user_id', _auth.currentUser!.id)
          .inFilter('activity_type', [
            'post_liked',
            'post_commented',
            'post_shared',
          ])
          .order('created_at', ascending: false)
          .limit(30);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get social interaction activities error: $e');
      return [];
    }
  }

  /// Mark activity as read
  Future<bool> markActivityAsRead(String activityId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('user_activity_timeline')
          .update({'is_read': true})
          .eq('id', activityId);

      return true;
    } catch (e) {
      debugPrint('Mark activity as read error: $e');
      return false;
    }
  }

  /// Mark all activities as read
  Future<bool> markAllActivitiesAsRead() async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('user_activity_timeline')
          .update({'is_read': true})
          .eq('user_id', _auth.currentUser!.id)
          .eq('is_read', false);

      return true;
    } catch (e) {
      debugPrint('Mark all activities as read error: $e');
      return false;
    }
  }

  /// Get unread activity count
  Future<int> getUnreadActivityCount() async {
    try {
      if (!_auth.isAuthenticated) return 0;

      final response = await _client
          .from('user_activity_timeline')
          .select('id')
          .eq('user_id', _auth.currentUser!.id)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      debugPrint('Get unread activity count error: $e');
      return 0;
    }
  }

  /// Get activity timeline stream
  Stream<List<Map<String, dynamic>>> getActivityTimelineStream() {
    try {
      if (!_auth.isAuthenticated) return Stream.value([]);

      return _client
          .from('user_activity_timeline')
          .stream(primaryKey: ['id'])
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(50)
          .map((data) => List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Get activity timeline stream error: $e');
      return Stream.value([]);
    }
  }

  /// Create activity entry (for system use)
  Future<bool> createActivityEntry({
    required String userId,
    String? actorId,
    required String activityType,
    required String activityTitle,
    String? activityDescription,
    String? referenceId,
    String? referenceType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.rpc(
        'create_activity_timeline_entry',
        params: {
          'p_user_id': userId,
          'p_actor_id': actorId,
          'p_activity_type': activityType,
          'p_activity_title': activityTitle,
          'p_activity_description': activityDescription ?? '',
          'p_reference_id': referenceId,
          'p_reference_type': referenceType ?? '',
          'p_metadata': metadata ?? {},
        },
      );

      return true;
    } catch (e) {
      debugPrint('Create activity entry error: $e');
      return false;
    }
  }
}
