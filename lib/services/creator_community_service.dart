import 'package:flutter/foundation.dart';

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
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);

      if (topic != null && topic.isNotEmpty) {
        query = query.ilike('tags', '%$topic%');
      }

      final res = await query;
      return List<Map<String, dynamic>>.from(res ?? []);
    } catch (e) {
      debugPrint('Get strategy posts error: $e');
      return _getMockStrategyPosts();
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
      return List<Map<String, dynamic>>.from(res ?? []);
    } catch (e) {
      debugPrint('Get partnership opportunities error: $e');
      return _getMockPartnerships();
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
      return List<Map<String, dynamic>>.from(res ?? []);
    } catch (e) {
      debugPrint('Get mentorship threads error: $e');
      return _getMockMentorship();
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
      return res as Map<String, dynamic>?;
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

      return res as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Create post error: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> _getMockStrategyPosts() {
    return [
      {
        'id': '1',
        'title': 'Carousel best practices for higher engagement',
        'body': 'Focus on first 3 seconds...',
        'tags': ['carousel', 'engagement', 'tips'],
        'likes_count': 42,
        'author': {'username': 'CreatorPro'},
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '2',
        'title': 'How to structure a voting carousel',
        'body': 'Clear options, strong visuals...',
        'tags': ['voting', 'carousel', 'structure'],
        'likes_count': 28,
        'author': {'username': 'VoteMaster'},
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': '3',
        'title': 'Timing your carousel drops',
        'body': 'Peak hours matter...',
        'tags': ['timing', 'strategy'],
        'likes_count': 15,
        'author': {'username': 'TimingGuru'},
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];
  }

  List<Map<String, dynamic>> _getMockPartnerships() {
    return [
      {
        'id': 'p1',
        'title': 'Looking for brand collab - 50K followers',
        'body': 'Fashion niche, open to product placement...',
        'likes_count': 12,
        'author': {'username': 'FashionCreator'},
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'p2',
        'title': 'Tech brand partnership opportunity',
        'body': 'Gadget reviews, 100K+ reach...',
        'likes_count': 8,
        'author': {'username': 'TechReviewer'},
        'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      },
    ];
  }

  List<Map<String, dynamic>> _getMockMentorship() {
    return [
      {
        'id': 'm1',
        'title': 'Mentoring new creators - DM me',
        'body': '2 years experience, happy to help...',
        'likes_count': 24,
        'author': {'username': 'MentorMike'},
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'm2',
        'title': 'Carousel monetization Q&A',
        'body': 'Ask me anything about creator earnings...',
        'likes_count': 18,
        'author': {'username': 'EarningsExpert'},
        'created_at': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      },
    ];
  }
}
