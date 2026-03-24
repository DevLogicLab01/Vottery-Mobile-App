import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../framework/shared_constants.dart';
import './openai_embeddings_service.dart';

/// Feed Ranking Service
/// Real-time personalized feed ranking with collaborative filtering and OpenAI embeddings
class FeedRankingService {
  static FeedRankingService? _instance;
  static FeedRankingService get instance =>
      _instance ??= FeedRankingService._();
  FeedRankingService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final OpenAIEmbeddingsService _embeddings = OpenAIEmbeddingsService.instance;

  // Engagement signal weights
  static const Map<String, int> _signalWeights = {
    'view': 1,
    'reaction': 3,
    'comment': 5,
    'share': 7,
    'vote_participation': 10,
    'quest_completion': 8,
  };

  // Ranking score weights
  static const double _semanticWeight = 0.3;
  static const double _collaborativeWeight = 0.3;
  static const double _recencyWeight = 0.2;
  static const double _popularityWeight = 0.1;
  static const double _diversityPenalty = 0.1;

  /// Track engagement signal
  Future<void> trackEngagement({
    required String contentId,
    required String contentType,
    required String signalType,
    int? viewDurationSeconds,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final signalWeight = _signalWeights[signalType] ?? 1;

      await _supabase.from('engagement_signals').insert({
        'user_id': userId,
        'content_id': contentId,
        'content_type': contentType,
        'signal_type': signalType,
        'signal_weight': signalWeight,
        'view_duration_seconds': viewDurationSeconds,
      });

      // Update collaborative filtering matrix
      await _updateCollaborativeFilteringMatrix(
        userId: userId,
        contentId: contentId,
        contentType: contentType,
        signalWeight: signalWeight,
      );
    } catch (e) {
      debugPrint('Track engagement error: $e');
    }
  }

  /// Update collaborative filtering matrix
  Future<void> _updateCollaborativeFilteringMatrix({
    required String userId,
    required String contentId,
    required String contentType,
    required int signalWeight,
  }) async {
    try {
      final existing = await _supabase
          .from('collaborative_filtering_matrix')
          .select('interaction_score')
          .eq('user_id', userId)
          .eq('content_id', contentId)
          .eq('content_type', contentType)
          .maybeSingle();

      if (existing != null) {
        final newScore = existing['interaction_score'] + signalWeight;
        await _supabase
            .from('collaborative_filtering_matrix')
            .update({
              'interaction_score': newScore,
              'last_interaction': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('content_id', contentId)
            .eq('content_type', contentType);
      } else {
        await _supabase.from('collaborative_filtering_matrix').insert({
          'user_id': userId,
          'content_id': contentId,
          'content_type': contentType,
          'interaction_score': signalWeight.toDouble(),
        });
      }
    } catch (e) {
      debugPrint('Update CF matrix error: $e');
    }
  }

  /// Calculate personalized ranking for content
  Future<List<Map<String, dynamic>>> getPersonalizedFeed({
    required String contentType,
    int limit = 50,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Check for cached rankings (30-second expiry)
      final cachedRankings = await _supabase
          .from('personalized_rankings')
          .select()
          .eq('user_id', userId)
          .eq('content_type', contentType)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('final_ranking_score', ascending: false)
          .limit(limit);

      if (cachedRankings.isNotEmpty) {
        return cachedRankings;
      }

      // Generate new rankings
      final rankings = await _generatePersonalizedRankings(
        userId: userId,
        contentType: contentType,
        limit: limit,
      );

      return rankings;
    } catch (e) {
      debugPrint('Get personalized feed error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _generatePersonalizedRankings({
    required String userId,
    required String contentType,
    required int limit,
  }) async {
    try {
      // Get all content of specified type
      final allContent = await _getContentByType(contentType);
      if (allContent.isEmpty) return [];

      final sponsoredElectionIds = <String>{};
      try {
        final raw = await _supabase
            .from('sponsored_elections')
            .select('election_id')
            .eq('status', 'active');
        for (final row in raw as List) {
          final id = (row as Map)['election_id']?.toString();
          if (id != null && id.isNotEmpty) sponsoredElectionIds.add(id);
        }
      } catch (e) {
        debugPrint('FeedRankingService sponsored election ids: $e');
      }

      final rankings = <Map<String, dynamic>>[];

      for (final content in allContent) {
        final contentId = content['id'];

        // Calculate semantic similarity score
        final semanticScore = await _calculateSemanticSimilarity(
          userId: userId,
          contentId: contentId,
          contentType: contentType,
        );

        // Calculate collaborative filtering score
        final collaborativeScore = await _calculateCollaborativeScore(
          userId: userId,
          contentId: contentId,
          contentType: contentType,
        );

        // Calculate recency boost
        final recencyBoost = _calculateRecencyBoost(content['created_at']);

        // Calculate popularity boost
        final popularityBoost = await _calculatePopularityBoost(
          contentId: contentId,
          contentType: contentType,
        );

        // Calculate diversity penalty
        final diversityPenalty = _calculateDiversityPenalty(
          rankings: rankings,
          currentCategory: content['category'] ?? '',
        );

        // Calculate final ranking score (sponsored elections: same 2.0× as Web Gemini service)
        var finalScore =
            ((semanticScore * _semanticWeight) +
            (collaborativeScore * _collaborativeWeight) +
            (recencyBoost * _recencyWeight) +
            (popularityBoost * _popularityWeight) -
            (diversityPenalty * _diversityPenalty));
        if (contentType == 'election' &&
            sponsoredElectionIds.contains(contentId.toString())) {
          finalScore *= SharedConstants.sponsoredElectionRankingWeightMultiplier;
        }

        final rankingExplanation = {
          'semantic_similarity': semanticScore,
          'collaborative_filtering': collaborativeScore,
          'recency_boost': recencyBoost,
          'popularity_boost': popularityBoost,
          'diversity_penalty': diversityPenalty,
          'reason_tags': _generateReasonTags(
            semanticScore: semanticScore,
            collaborativeScore: collaborativeScore,
            popularityBoost: popularityBoost,
          ),
        };

        rankings.add({
          'content_id': contentId,
          'content_type': contentType,
          'semantic_similarity_score': semanticScore,
          'collaborative_filtering_score': collaborativeScore,
          'recency_boost': recencyBoost,
          'popularity_boost': popularityBoost,
          'diversity_penalty': diversityPenalty,
          'final_ranking_score': finalScore,
          'ranking_explanation': rankingExplanation,
          ...content,
        });
      }

      // Sort by final score
      rankings.sort(
        (a, b) => b['final_ranking_score'].compareTo(a['final_ranking_score']),
      );

      // Store rankings in Supabase
      await _storeRankings(
        userId: userId,
        rankings: rankings.take(limit).toList(),
      );

      return rankings.take(limit).toList();
    } catch (e) {
      debugPrint('Generate personalized rankings error: $e');
      return [];
    }
  }

  Future<double> _calculateSemanticSimilarity({
    required String userId,
    required String contentId,
    required String contentType,
  }) async {
    try {
      // Get user's taste profile
      final tasteProfile = await _supabase
          .from('user_taste_profiles')
          .select('engagement_history')
          .eq('user_id', userId)
          .maybeSingle();

      if (tasteProfile == null) return 0.0;

      // Get content embedding
      final contentEmbedding = await _supabase
          .from('content_embeddings')
          .select('embedding_vector')
          .eq('content_id', contentId)
          .eq('content_type', contentType)
          .maybeSingle();

      if (contentEmbedding == null) return 0.0;

      // Calculate average similarity with user's engagement history
      final engagementHistory = List<Map<String, dynamic>>.from(
        tasteProfile['engagement_history'] ?? [],
      );
      if (engagementHistory.isEmpty) return 0.0;

      double totalSimilarity = 0.0;
      int count = 0;

      for (final engagement in engagementHistory.take(10)) {
        final historicalEmbedding = await _supabase
            .from('content_embeddings')
            .select('embedding_vector')
            .eq('content_id', engagement['content_id'])
            .maybeSingle();

        if (historicalEmbedding != null) {
          final similarity = _embeddings.calculateSimilarity(
            List<double>.from(contentEmbedding['embedding_vector']),
            List<double>.from(historicalEmbedding['embedding_vector']),
          );
          totalSimilarity += similarity;
          count++;
        }
      }

      return count > 0 ? totalSimilarity / count : 0.0;
    } catch (e) {
      debugPrint('Calculate semantic similarity error: $e');
      return 0.0;
    }
  }

  Future<double> _calculateCollaborativeScore({
    required String userId,
    required String contentId,
    required String contentType,
  }) async {
    try {
      // Get similar users
      final similarUsers = await _supabase
          .from('similar_users')
          .select('similar_user_id, similarity_score')
          .eq('user_id', userId)
          .order('similarity_score', ascending: false)
          .limit(10);

      if (similarUsers.isEmpty) return 0.0;

      double totalScore = 0.0;
      int count = 0;

      for (final similarUser in similarUsers) {
        final interaction = await _supabase
            .from('collaborative_filtering_matrix')
            .select('interaction_score')
            .eq('user_id', similarUser['similar_user_id'])
            .eq('content_id', contentId)
            .eq('content_type', contentType)
            .maybeSingle();

        if (interaction != null) {
          totalScore +=
              interaction['interaction_score'] *
              similarUser['similarity_score'];
          count++;
        }
      }

      return count > 0 ? totalScore / count : 0.0;
    } catch (e) {
      debugPrint('Calculate collaborative score error: $e');
      return 0.0;
    }
  }

  double _calculateRecencyBoost(String? createdAt) {
    if (createdAt == null) return 0.0;

    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      final hoursSinceCreation = now.difference(created).inHours;

      // Exponential decay: newer content gets higher boost
      return exp(-hoursSinceCreation / 24.0);
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _calculatePopularityBoost({
    required String contentId,
    required String contentType,
  }) async {
    try {
      final engagementCount = await _supabase
          .from('engagement_signals')
          .select('id')
          .eq('content_id', contentId)
          .eq('content_type', contentType)
          .count();

      final count = engagementCount.count;

      // Logarithmic scaling
      return count > 0 ? log(count + 1) / 10.0 : 0.0;
    } catch (e) {
      debugPrint('Calculate popularity boost error: $e');
      return 0.0;
    }
  }

  double _calculateDiversityPenalty({
    required List<Map<String, dynamic>> rankings,
    required String currentCategory,
  }) {
    if (rankings.isEmpty || currentCategory.isEmpty) return 0.0;

    // Count how many items from same category in top 10
    final recentRankings = rankings.take(10);
    final sameCategoryCount = recentRankings
        .where((r) => r['category'] == currentCategory)
        .length;

    // Penalize if too many from same category
    return sameCategoryCount > 3 ? (sameCategoryCount - 3) * 0.1 : 0.0;
  }

  List<String> _generateReasonTags({
    required double semanticScore,
    required double collaborativeScore,
    required double popularityBoost,
  }) {
    final tags = <String>[];

    if (semanticScore > 0.7) {
      tags.add('similar_to_your_interests');
    }
    if (collaborativeScore > 0.6) {
      tags.add('popular_with_similar_users');
    }
    if (popularityBoost > 0.5) {
      tags.add('trending_in_your_zone');
    }

    return tags;
  }

  Future<void> _storeRankings({
    required String userId,
    required List<Map<String, dynamic>> rankings,
  }) async {
    try {
      final expiresAt = DateTime.now().add(const Duration(seconds: 30));

      for (final ranking in rankings) {
        await _supabase.from('personalized_rankings').upsert({
          'user_id': userId,
          'content_id': ranking['content_id'],
          'content_type': ranking['content_type'],
          'semantic_similarity_score': ranking['semantic_similarity_score'],
          'collaborative_filtering_score':
              ranking['collaborative_filtering_score'],
          'recency_boost': ranking['recency_boost'],
          'popularity_boost': ranking['popularity_boost'],
          'diversity_penalty': ranking['diversity_penalty'],
          'final_ranking_score': ranking['final_ranking_score'],
          'ranking_explanation': ranking['ranking_explanation'],
          'expires_at': expiresAt.toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Store rankings error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getContentByType(
    String contentType,
  ) async {
    try {
      switch (contentType) {
        case 'election':
          return await _supabase
              .from('elections')
              .select()
              .eq('status', 'active');
        case 'post':
          return await _supabase.from('social_posts').select();
        case 'jolt':
          return await _supabase.from('jolts').select();
        default:
          return [];
      }
    } catch (e) {
      debugPrint('Get content by type error: $e');
      return [];
    }
  }

  /// Find and store similar users based on voting patterns
  Future<void> updateSimilarUsers() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get user's interaction matrix
      final userInteractions = await _supabase
          .from('collaborative_filtering_matrix')
          .select()
          .eq('user_id', userId);

      if (userInteractions.isEmpty) return;

      // Get all other users
      final allUsers = await _supabase
          .from('user_profiles')
          .select('id')
          .neq('id', userId);

      for (final otherUser in allUsers) {
        final otherUserId = otherUser['id'];

        // Get other user's interactions
        final otherInteractions = await _supabase
            .from('collaborative_filtering_matrix')
            .select()
            .eq('user_id', otherUserId);

        // Calculate similarity (Jaccard similarity)
        final similarity = _calculateUserSimilarity(
          userInteractions,
          otherInteractions,
        );

        if (similarity > 0.3) {
          await _supabase.from('similar_users').upsert({
            'user_id': userId,
            'similar_user_id': otherUserId,
            'similarity_score': similarity,
          });
        }
      }
    } catch (e) {
      debugPrint('Update similar users error: $e');
    }
  }

  double _calculateUserSimilarity(
    List<Map<String, dynamic>> user1Interactions,
    List<Map<String, dynamic>> user2Interactions,
  ) {
    final user1ContentIds = user1Interactions
        .map((i) => i['content_id'])
        .toSet();
    final user2ContentIds = user2Interactions
        .map((i) => i['content_id'])
        .toSet();

    final intersection = user1ContentIds.intersection(user2ContentIds).length;
    final union = user1ContentIds.union(user2ContentIds).length;

    return union > 0 ? intersection / union : 0.0;
  }
}
