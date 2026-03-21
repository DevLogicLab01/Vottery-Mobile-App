import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

/// Creator Community Hub - Strategy, partnerships, mentorship
class CreatorCommunityService {
  static CreatorCommunityService? _instance;
  static CreatorCommunityService get instance =>
      _instance ??= CreatorCommunityService._();

  CreatorCommunityService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Get strategy forum posts
  Future<List<Map<String, dynamic>>> getStrategyPosts({
    int limit = 20,
    String? topic,
  }) async {
    try {
      var query = _client
          .from('creator_community_posts')
          .select('*')
          .eq('post_type', 'strategy')
          .eq('is_active', true);

      if (topic != null && topic.isNotEmpty) {
        query = query.contains('tags', [topic]);
      }

      final res = await query.order('created_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Get strategy posts error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Get partnership opportunities
  Future<List<Map<String, dynamic>>> getPartnershipOpportunities({
    int limit = 10,
  }) async {
    try {
      final res = await _client
          .from('creator_community_posts')
          .select('*')
          .eq('post_type', 'partnership')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Get partnership opportunities error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Get mentorship threads
  Future<List<Map<String, dynamic>>> getMentorshipThreads({
    int limit = 10,
  }) async {
    try {
      final res = await _client
          .from('creator_community_posts')
          .select('*')
          .eq('post_type', 'mentorship')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Get mentorship threads error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Get a single post by ID
  Future<Map<String, dynamic>?> getPostById(String postId) async {
    try {
      final res = await _client
          .from('creator_community_posts')
          .select('*')
          .eq('id', postId)
          .eq('is_active', true)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('Get post by id error: $e');
      return null;
    }
  }

  /// Create a post (strategy, partnership, mentorship)
  Future<Map<String, dynamic>?> createPost({
    required String postType,
    required String title,
    required String body,
    List<String>? tags,
    String? authorId,
  }) async {
    try {
      final userId = authorId ?? SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final res = await _client.from('creator_community_posts').insert({
        'post_type': postType,
        'title': title,
        'body': body,
        'tags': tags ?? [],
        'author_id': userId,
        'is_active': true,
        'likes_count': 0,
      }).select().single();

      return Map<String, dynamic>.from(res);
    } catch (e) {
      debugPrint('Create post error: $e');
      return null;
    }
  }

}
