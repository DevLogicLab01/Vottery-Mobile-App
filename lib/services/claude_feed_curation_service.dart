import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './claude_service.dart';
import './feed_ranking_service.dart';

/// Feed Recommendation model with confidence score and reasoning
class FeedRecommendation {
  final Map<String, dynamic> feedItem;
  final double confidenceScore;
  final String reasoning;
  final String interestAlignment;
  final String socialProof;

  const FeedRecommendation({
    required this.feedItem,
    required this.confidenceScore,
    required this.reasoning,
    required this.interestAlignment,
    required this.socialProof,
  });

  Map<String, dynamic> toMap() => {
    'title': feedItem['title'] ?? feedItem['content'] ?? 'Content',
    'confidence_score': confidenceScore,
    'reasoning': reasoning,
    'interest_alignment': interestAlignment,
    'social_proof': socialProof,
    'feed_item': feedItem,
  };
}

/// Claude Feed Curation Service
/// Implements AI-powered feed personalization with user profile analysis,
/// Claude reasoning for ranking, real-time updates, and feedback collection
class ClaudeFeedCurationService {
  static ClaudeFeedCurationService? _instance;
  static ClaudeFeedCurationService get instance =>
      _instance ??= ClaudeFeedCurationService._();
  ClaudeFeedCurationService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ClaudeService _claude = ClaudeService.instance;
  final FeedRankingService _feedRanking = FeedRankingService.instance;

  // Stream controller for real-time recommendations
  final StreamController<List<FeedRecommendation>> _recommendationsController =
      StreamController<List<FeedRecommendation>>.broadcast();

  String? _currentUserId;
  List<FeedRecommendation> _cachedRecommendations = [];

  /// Get real-time stream of feed recommendations with confidence scores
  Stream<List<FeedRecommendation>> getRecommendationsStream({
    required String userId,
    String contentType = 'mixed',
  }) {
    _currentUserId = userId;
    // Trigger initial load
    _loadRecommendations(userId: userId, contentType: contentType);
    return _recommendationsController.stream;
  }

  /// Refresh recommendations (called on scroll events)
  Future<void> refreshRecommendations({String contentType = 'mixed'}) async {
    if (_currentUserId == null) return;
    await _loadRecommendations(
      userId: _currentUserId!,
      contentType: contentType,
    );
  }

  /// Load recommendations and emit to stream
  Future<void> _loadRecommendations({
    required String userId,
    String contentType = 'mixed',
  }) async {
    try {
      final userProfile = await _analyzeUserProfile(userId);
      final feedItems = await _getFeedItems(contentType, limit: 20);

      if (feedItems.isEmpty) {
        _recommendationsController.add(_getMockRecommendations());
        return;
      }

      final recommendations = <FeedRecommendation>[];
      for (final item in feedItems.take(10)) {
        final confidence = calculateConfidenceScore(
          userProfile: userProfile,
          feedItem: item,
        );
        final reasoning = _buildReasoning(userProfile, item, confidence);
        final interestAlignment = _getInterestAlignment(userProfile, item);
        final socialProof = _getSocialProof(item);

        recommendations.add(
          FeedRecommendation(
            feedItem: item,
            confidenceScore: confidence,
            reasoning: reasoning,
            interestAlignment: interestAlignment,
            socialProof: socialProof,
          ),
        );
      }

      // Sort by confidence score descending
      recommendations.sort(
        (a, b) => b.confidenceScore.compareTo(a.confidenceScore),
      );
      _cachedRecommendations = recommendations;
      _recommendationsController.add(recommendations);
    } catch (e) {
      debugPrint('Load recommendations error: $e');
      _recommendationsController.add(_getMockRecommendations());
    }
  }

  /// Calculate confidence score (0-100) based on user interests, post content, engagement signals
  double calculateConfidenceScore({
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> feedItem,
  }) {
    double score = 50.0; // Base score

    // Interest alignment (+30 max)
    final topCategories =
        userProfile['top_categories'] as Map<String, int>? ?? {};
    final itemCategory = feedItem['category'] as String? ?? '';
    if (topCategories.containsKey(itemCategory)) {
      final categoryCount = topCategories[itemCategory] ?? 0;
      final maxCount = topCategories.values.fold(1, (a, b) => a > b ? a : b);
      score += (categoryCount / maxCount) * 30;
    }

    // Engagement signals (+20 max)
    final voteCount =
        (feedItem['vote_count'] ??
                feedItem['like_count'] ??
                feedItem['view_count'] ??
                0)
            as int;
    if (voteCount > 1000) {
      score += 20;
    } else if (voteCount > 100)
      score += 12;
    else if (voteCount > 10)
      score += 6;

    // Recency bonus (+10 max)
    final createdAt = DateTime.tryParse(feedItem['created_at'] ?? '');
    if (createdAt != null) {
      final hoursAgo = DateTime.now().difference(createdAt).inHours;
      if (hoursAgo < 1) {
        score += 10;
      } else if (hoursAgo < 6)
        score += 7;
      else if (hoursAgo < 24)
        score += 4;
    }

    // Social proof from following (+10 max)
    final followingCount = userProfile['following_count'] as int? ?? 0;
    if (followingCount > 50) {
      score += 10;
    } else if (followingCount > 10)
      score += 5;

    return score.clamp(0.0, 100.0);
  }

  String _buildReasoning(
    Map<String, dynamic> userProfile,
    Map<String, dynamic> item,
    double confidence,
  ) {
    final category = item['category'] as String? ?? 'general';
    final topCategories =
        userProfile['top_categories'] as Map<String, int>? ?? {};
    if (topCategories.containsKey(category)) {
      return 'Matches your interest in $category content';
    }
    if (confidence > 75) return 'Trending in your network';
    if (confidence > 60) return 'Popular with similar users';
    return 'Recommended based on your activity';
  }

  String _getInterestAlignment(
    Map<String, dynamic> userProfile,
    Map<String, dynamic> item,
  ) {
    final category = item['category'] as String? ?? 'general';
    final topCategories =
        userProfile['top_categories'] as Map<String, int>? ?? {};
    if (topCategories.containsKey(category)) {
      return 'Strong match: $category';
    }
    return 'General interest';
  }

  String _getSocialProof(Map<String, dynamic> item) {
    final count =
        (item['vote_count'] ?? item['like_count'] ?? item['view_count'] ?? 0)
            as int;
    if (count > 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K engagements';
    }
    if (count > 0) return '$count engagements';
    return 'New content';
  }

  List<FeedRecommendation> _getMockRecommendations() {
    return [
      FeedRecommendation(
        feedItem: {
          'title': 'Tech Policy Vote 2026',
          'category': 'technology',
          'vote_count': 1247,
        },
        confidenceScore: 92.0,
        reasoning: 'Matches your interest in technology',
        interestAlignment: 'Strong match: technology',
        socialProof: '1.2K engagements',
      ),
      FeedRecommendation(
        feedItem: {
          'title': 'Climate Action Initiative',
          'category': 'environment',
          'vote_count': 856,
        },
        confidenceScore: 78.0,
        reasoning: 'Trending in your network',
        interestAlignment: 'General interest',
        socialProof: '856 engagements',
      ),
      FeedRecommendation(
        feedItem: {
          'title': 'Community Budget Allocation',
          'category': 'finance',
          'vote_count': 423,
        },
        confidenceScore: 65.0,
        reasoning: 'Popular with similar users',
        interestAlignment: 'General interest',
        socialProof: '423 engagements',
      ),
      FeedRecommendation(
        feedItem: {
          'title': 'Local Education Reform',
          'category': 'education',
          'vote_count': 234,
        },
        confidenceScore: 55.0,
        reasoning: 'Recommended based on your activity',
        interestAlignment: 'General interest',
        socialProof: '234 engagements',
      ),
    ];
  }

  void dispose() {
    _recommendationsController.close();
  }

  /// Get personalized feed with Claude curation
  Future<List<Map<String, dynamic>>> getPersonalizedFeed({
    required String userId,
    required String contentType,
    int limit = 20,
  }) async {
    try {
      // Check cache first (15 minute TTL)
      final cached = await _getCachedRankings(userId, contentType);
      if (cached.isNotEmpty) {
        return cached;
      }

      // Analyze user profile
      final userProfile = await _analyzeUserProfile(userId);

      // Get feed items
      final feedItems = await _getFeedItems(contentType, limit: limit * 2);

      if (feedItems.isEmpty) {
        return [];
      }

      // Construct Claude prompt
      final prompt = _buildCurationPrompt(userProfile, feedItems);

      // Call Claude for ranking
      final claudeResponse = await _claude.callClaudeAPI(prompt);

      // Parse rankings
      final rankedItems = _parseClaudeRankings(claudeResponse, feedItems);

      // Store rankings in cache
      await _cacheRankings(userId, contentType, rankedItems);

      // Track curation analytics
      await _trackCurationAnalytics(userId, rankedItems);

      return rankedItems.take(limit).toList();
    } catch (e) {
      debugPrint('Get personalized feed error: $e');
      // Fallback to algorithmic ranking
      return await _feedRanking.getPersonalizedFeed(
        contentType: contentType,
        limit: limit,
      );
    }
  }

  /// Analyze user profile
  Future<Map<String, dynamic>> _analyzeUserProfile(String userId) async {
    try {
      // Aggregate user interactions
      final votes = await _supabase
          .from('votes')
          .select('election_id, elections(category, title)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final posts = await _supabase
          .from('social_posts')
          .select('content_type, category')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      final comments = await _supabase
          .from('post_comments')
          .select('post_id, posts(content_type, category)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(30);

      // Carousel interactions
      final carouselInteractions = await _supabase
          .from('engagement_signals')
          .select(
            'content_id, content_type, signal_type, view_duration_seconds',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      // Content preferences
      final topCategories = _extractTopCategories(votes, posts);
      final contentTypes = _extractContentTypes(carouselInteractions);
      final engagementPatterns = _analyzeEngagementPatterns(
        carouselInteractions,
      );

      // Social graph
      final following = await _supabase
          .from('user_follows')
          .select('following_id')
          .eq('follower_id', userId);

      return {
        'user_id': userId,
        'voting_history': votes.length,
        'top_categories': topCategories,
        'content_preferences': contentTypes,
        'engagement_patterns': engagementPatterns,
        'following_count': following.length,
        'recent_interactions': carouselInteractions.take(10).toList(),
      };
    } catch (e) {
      debugPrint('Analyze user profile error: $e');
      return {};
    }
  }

  /// Extract top categories
  Map<String, int> _extractTopCategories(
    List<dynamic> votes,
    List<dynamic> posts,
  ) {
    final categories = <String, int>{};

    for (final vote in votes) {
      final election = vote['elections'];
      if (election != null) {
        final category = election['category'] as String?;
        if (category != null) {
          categories[category] = (categories[category] ?? 0) + 1;
        }
      }
    }

    for (final post in posts) {
      final category = post['category'] as String?;
      if (category != null) {
        categories[category] = (categories[category] ?? 0) + 1;
      }
    }

    return categories;
  }

  /// Extract content types
  Map<String, double> _extractContentTypes(List<dynamic> interactions) {
    final types = <String, int>{};
    for (final interaction in interactions) {
      final contentType = interaction['content_type'] as String?;
      if (contentType != null) {
        types[contentType] = (types[contentType] ?? 0) + 1;
      }
    }

    final total = types.values.fold(0, (sum, count) => sum + count);
    return types.map((k, v) => MapEntry(k, v / total));
  }

  /// Analyze engagement patterns
  Map<String, dynamic> _analyzeEngagementPatterns(List<dynamic> interactions) {
    if (interactions.isEmpty) return {};

    final avgViewDuration =
        interactions
            .map((i) => i['view_duration_seconds'] as int? ?? 0)
            .reduce((a, b) => a + b) /
        interactions.length;

    final signalTypes = <String, int>{};
    for (final interaction in interactions) {
      final signalType = interaction['signal_type'] as String?;
      if (signalType != null) {
        signalTypes[signalType] = (signalTypes[signalType] ?? 0) + 1;
      }
    }

    return {
      'avg_view_duration': avgViewDuration,
      'signal_distribution': signalTypes,
      'frequency': interactions.length,
    };
  }

  /// Get feed items
  Future<List<Map<String, dynamic>>> _getFeedItems(
    String contentType, {
    int limit = 40,
  }) async {
    try {
      List<dynamic> items;

      switch (contentType) {
        case 'elections':
          items = await _supabase
              .from('elections')
              .select('id, title, category, created_at, vote_count')
              .eq('status', 'active')
              .order('created_at', ascending: false)
              .limit(limit);
          break;
        case 'jolts':
          items = await _supabase
              .from('jolts')
              .select('id, title, category, created_at, view_count')
              .order('created_at', ascending: false)
              .limit(limit);
          break;
        case 'moments':
          items = await _supabase
              .from('moments')
              .select('id, title, category, created_at, view_count')
              .order('created_at', ascending: false)
              .limit(limit);
          break;
        case 'posts':
          items = await _supabase
              .from('social_posts')
              .select('id, content, category, created_at, like_count')
              .order('created_at', ascending: false)
              .limit(limit);
          break;
        default:
          items = [];
      }

      return List<Map<String, dynamic>>.from(items);
    } catch (e) {
      debugPrint('Get feed items error: $e');
      return [];
    }
  }

  /// Build Claude curation prompt
  String _buildCurationPrompt(
    Map<String, dynamic> userProfile,
    List<Map<String, dynamic>> feedItems,
  ) {
    final topCategories = userProfile['top_categories'] as Map<String, int>?;
    final contentPreferences =
        userProfile['content_preferences'] as Map<String, double>?;
    final engagementPatterns =
        userProfile['engagement_patterns'] as Map<String, dynamic>?;

    final itemsJson = feedItems
        .map(
          (item) => {
            'id': item['id'],
            'title': item['title'] ?? item['content'] ?? '',
            'category': item['category'] ?? 'general',
            'created_at': item['created_at'],
            'engagement':
                item['vote_count'] ??
                item['view_count'] ??
                item['like_count'] ??
                0,
          },
        )
        .toList();

    return '''
Analyze this user's content preferences for feed personalization.

User Profile:
- Voting history: ${userProfile['voting_history']} votes
- Top categories: ${jsonEncode(topCategories)}
- Content preferences: ${jsonEncode(contentPreferences)}
- Engagement patterns: ${jsonEncode(engagementPatterns)}
- Following: ${userProfile['following_count']} users

Rank these feed items for maximum relevance:
${jsonEncode(itemsJson)}

For each item provide:
- Relevance score (0-100)
- Positioning in feed (rank 1-20)
- Reasoning (brief explanation)
- Viral probability (0-1)
- Expected engagement time (seconds)

Return JSON array:
[
  {
    "content_id": "...",
    "relevance_score": 0-100,
    "feed_position": 1-20,
    "reasoning": "...",
    "viral_probability": 0-1,
    "expected_engagement": 0
  }
]
''';
  }

  /// Parse Claude rankings
  List<Map<String, dynamic>> _parseClaudeRankings(
    String claudeResponse,
    List<Map<String, dynamic>> feedItems,
  ) {
    try {
      final rankings = jsonDecode(claudeResponse) as List;

      final rankedItems = <Map<String, dynamic>>[];

      for (final ranking in rankings) {
        final contentId = ranking['content_id'];
        final item = feedItems.firstWhere(
          (i) => i['id'] == contentId,
          orElse: () => <String, dynamic>{},
        );

        if (item.isNotEmpty) {
          rankedItems.add({
            ...item,
            'relevance_score': ranking['relevance_score'] ?? 50,
            'feed_position': ranking['feed_position'] ?? 999,
            'reasoning': ranking['reasoning'] ?? '',
            'viral_probability': ranking['viral_probability'] ?? 0.0,
            'expected_engagement': ranking['expected_engagement'] ?? 0,
          });
        }
      }

      // Sort by feed position
      rankedItems.sort(
        (a, b) => a['feed_position'].compareTo(b['feed_position']),
      );

      return rankedItems;
    } catch (e) {
      debugPrint('Parse Claude rankings error: $e');
      return feedItems;
    }
  }

  /// Get cached rankings
  Future<List<Map<String, dynamic>>> _getCachedRankings(
    String userId,
    String contentType,
  ) async {
    try {
      final response = await _supabase
          .from('feed_ranking_cache')
          .select()
          .eq('user_id', userId)
          .eq('content_type', contentType)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (response != null) {
        final rankedItems = jsonDecode(response['ranked_feed_items'] as String);
        return List<Map<String, dynamic>>.from(rankedItems);
      }

      return [];
    } catch (e) {
      debugPrint('Get cached rankings error: $e');
      return [];
    }
  }

  /// Cache rankings
  Future<void> _cacheRankings(
    String userId,
    String contentType,
    List<Map<String, dynamic>> rankedItems,
  ) async {
    try {
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));

      await _supabase.from('feed_ranking_cache').upsert({
        'user_id': userId,
        'content_type': contentType,
        'ranked_feed_items': jsonEncode(rankedItems),
        'cached_at': DateTime.now().toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Cache rankings error: $e');
    }
  }

  /// Track curation analytics
  Future<void> _trackCurationAnalytics(
    String userId,
    List<Map<String, dynamic>> rankedItems,
  ) async {
    try {
      final avgRelevance =
          rankedItems
              .map((i) => i['relevance_score'] as int)
              .reduce((a, b) => a + b) /
          rankedItems.length;

      await _supabase.from('claude_curation_analytics').insert({
        'user_id': userId,
        'prediction_accuracy': 0.0, // Updated based on actual engagement
        'engagement_lift': 0.0, // Calculated vs chronological
        'ranking_cost_tokens': 2000, // Estimated
        'ranking_latency_ms': 1500,
        'ranked_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Track curation analytics error: $e');
    }
  }

  /// Track user feedback
  Future<void> trackFeedback({
    required String userId,
    required String contentId,
    required String contentType,
    required String action,
    String? reason,
  }) async {
    try {
      final preferenceScore = action == 'liked'
          ? 100
          : action == 'dismissed'
          ? -100
          : 0;

      await _supabase.from('user_content_preferences').upsert({
        'user_id': userId,
        'content_type': contentType,
        'content_id': contentId,
        'action': action,
        'reason': reason,
        'preference_score': preferenceScore,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Track feedback error: $e');
    }
  }
}
