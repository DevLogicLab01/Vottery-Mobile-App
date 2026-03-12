import 'dart:convert';
import 'package:dio/dio.dart';
import './supabase_service.dart';

/// OpenAI Carousel Content Ranking Service
/// Implements AI semantic personalization for carousel content ordering
class OpenAICarouselRankingService {
  static OpenAICarouselRankingService? _instance;
  static OpenAICarouselRankingService get instance =>
      _instance ??= OpenAICarouselRankingService._();

  OpenAICarouselRankingService._();

  final SupabaseService _supabase = SupabaseService.instance;
  late final Dio _dio;
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _embeddingModel = 'text-embedding-3-large';
  static const int _embeddingDimensions = 1536;

  void initialize() {
    if (_apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY environment variable not set');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
      ),
    );
  }

  // ============================================
  // USER BEHAVIOR COLLECTION
  // ============================================

  /// Aggregate user carousel interactions for personalization
  Future<Map<String, dynamic>> collectUserBehavior(String userId) async {
    try {
      // Get last 30 days of interactions
      final interactions = await _supabase.client
          .from('carousel_interactions')
          .select('*')
          .eq('user_id', userId)
          .gte(
            'interaction_timestamp',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          )
          .order('interaction_timestamp', ascending: false);

      if (interactions.isEmpty) {
        return _getDefaultBehavior();
      }

      // Calculate swipe patterns
      final swipeRight = interactions
          .where((i) => i['interaction_type'] == 'swipe_right')
          .length;
      final swipeLeft = interactions
          .where((i) => i['interaction_type'] == 'swipe_left')
          .length;
      final totalSwipes = swipeRight + swipeLeft;

      final swipeRightRate = totalSwipes > 0
          ? (swipeRight / totalSwipes * 100)
          : 50.0;
      final swipeLeftRate = totalSwipes > 0
          ? (swipeLeft / totalSwipes * 100)
          : 50.0;

      // Calculate engagement metrics
      final viewDurations = interactions
          .where((i) => i['view_duration_seconds'] != null)
          .map((i) => (i['view_duration_seconds'] as num).toDouble())
          .toList();
      final avgViewDuration = viewDurations.isNotEmpty
          ? viewDurations.reduce((a, b) => a + b) / viewDurations.length
          : 3.0;

      final conversions = interactions
          .where((i) => i['converted'] == true)
          .length;

      // Analyze category preferences
      final categoryMap = <String, int>{};
      for (var interaction in interactions) {
        final contentType = interaction['content_type'] as String?;
        if (contentType != null) {
          categoryMap[contentType] = (categoryMap[contentType] ?? 0) + 1;
        }
      }

      final topCategories = categoryMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'user_id': userId,
        'swipe_right_rate': swipeRightRate,
        'swipe_left_rate': swipeLeftRate,
        'avg_view_duration': avgViewDuration,
        'total_interactions': interactions.length,
        'conversion_count': conversions,
        'conversion_rate': interactions.isNotEmpty
            ? (conversions / interactions.length * 100)
            : 0.0,
        'top_categories': topCategories.take(5).map((e) => e.key).toList(),
        'category_affinity': Map.fromEntries(topCategories.take(5)),
      };
    } catch (e) {
      print('Error collecting user behavior: $e');
      return _getDefaultBehavior();
    }
  }

  Map<String, dynamic> _getDefaultBehavior() {
    return {
      'swipe_right_rate': 50.0,
      'swipe_left_rate': 50.0,
      'avg_view_duration': 3.0,
      'total_interactions': 0,
      'conversion_count': 0,
      'conversion_rate': 0.0,
      'top_categories': [],
      'category_affinity': {},
    };
  }

  // ============================================
  // CONTENT EMBEDDING GENERATION
  // ============================================

  /// Generate embeddings for carousel item
  Future<List<double>> generateContentEmbedding({
    required String itemId,
    required String itemType,
    required String title,
    String? description,
    String? creatorBio,
    String? category,
    List<String>? hashtags,
  }) async {
    try {
      // Construct weighted embedding text
      final embeddingText = _constructEmbeddingText(
        title: title,
        description: description,
        creatorBio: creatorBio,
        category: category,
        hashtags: hashtags,
      );

      // Call OpenAI Embeddings API
      final response = await _dio.post(
        '/embeddings',
        data: {
          'model': _embeddingModel,
          'input': embeddingText,
          'dimensions': _embeddingDimensions,
        },
      );

      final embedding = List<double>.from(
        response.data['data'][0]['embedding'],
      );

      // Store embedding in database
      await _supabase.client.from('carousel_item_embeddings').upsert({
        'item_id': itemId,
        'item_type': itemType,
        'embedding_vector': embedding,
        'content_text': embeddingText,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return embedding;
    } catch (e) {
      print('Error generating content embedding: $e');
      rethrow;
    }
  }

  String _constructEmbeddingText({
    required String title,
    String? description,
    String? creatorBio,
    String? category,
    List<String>? hashtags,
  }) {
    final parts = <String>[];

    // Title (weight: 3x)
    parts.add('$title $title $title');

    // Description (weight: 2x)
    if (description != null && description.isNotEmpty) {
      parts.add('$description $description');
    }

    // Category (weight: 2x)
    if (category != null && category.isNotEmpty) {
      parts.add('$category $category');
    }

    // Creator bio (weight: 1x)
    if (creatorBio != null && creatorBio.isNotEmpty) {
      parts.add(creatorBio);
    }

    // Hashtags (weight: 1x)
    if (hashtags != null && hashtags.isNotEmpty) {
      parts.add(hashtags.join(' '));
    }

    return parts.join(' ');
  }

  // ============================================
  // USER PREFERENCE MODELING
  // ============================================

  /// Compute user preference vector from engagement history
  Future<List<double>?> computeUserPreferenceVector(String userId) async {
    try {
      // Get items user engaged with positively
      final engagements = await _supabase.client
          .from('carousel_interactions')
          .select('item_id, item_type, interaction_type')
          .eq('user_id', userId)
          .inFilter('interaction_type', [
            'swipe_right',
            'tap',
            'like',
            'join',
            'vote',
            'purchase',
          ])
          .limit(100);

      if (engagements.isEmpty) {
        return null;
      }

      // Load embeddings for engaged items
      final itemIds = engagements.map((e) => e['item_id'] as String).toList();
      final embeddings = await _supabase.client
          .from('carousel_item_embeddings')
          .select('item_id, embedding_vector, item_type')
          .inFilter('item_id', itemIds);

      if (embeddings.isEmpty) {
        return null;
      }

      // Compute weighted average
      final weights = {
        'purchase': 1.0,
        'join': 0.9,
        'vote': 0.8,
        'like': 0.7,
        'tap': 0.5,
        'swipe_right': 0.3,
      };

      List<double> preferenceVector = List.filled(_embeddingDimensions, 0.0);
      double totalWeight = 0.0;

      for (var engagement in engagements) {
        final itemId = engagement['item_id'] as String;
        final interactionType = engagement['interaction_type'] as String;
        final weight = weights[interactionType] ?? 0.3;

        final embedding = embeddings.firstWhere(
          (e) => e['item_id'] == itemId,
          orElse: () => {},
        );

        if (embedding.isNotEmpty) {
          final vector = List<double>.from(
            embedding['embedding_vector'] as List,
          );
          for (int i = 0; i < _embeddingDimensions; i++) {
            preferenceVector[i] += vector[i] * weight;
          }
          totalWeight += weight;
        }
      }

      // Normalize
      if (totalWeight > 0) {
        preferenceVector = preferenceVector
            .map((v) => v / totalWeight)
            .toList();
      }

      // Store user preference vector
      await _supabase.client.from('user_preference_vectors').upsert({
        'user_id': userId,
        'preference_vector': preferenceVector,
        'interaction_count': engagements.length,
        'last_updated': DateTime.now().toIso8601String(),
      });

      return preferenceVector;
    } catch (e) {
      print('Error computing user preference vector: $e');
      return null;
    }
  }

  // ============================================
  // PERSONALIZED RANKING
  // ============================================

  /// Generate personalized carousel rankings using GPT-5
  Future<List<Map<String, dynamic>>> generatePersonalizedRanking({
    required String userId,
    required String carouselType,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // Check cache first
      final cached = await _getCachedRanking(userId, carouselType);
      if (cached != null) {
        return cached;
      }

      // Get user behavior
      final behavior = await collectUserBehavior(userId);

      // Construct GPT-5 prompt
      final prompt = _constructRankingPrompt(behavior, items);

      // Call GPT-5 Chat Completions API
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-5-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a content ranking expert for carousel feeds. Analyze user preferences and rank items by relevance. Return ONLY valid JSON array.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'reasoning_effort': 'medium',
          'max_completion_tokens': 2000,
        },
      );

      final responseText =
          response.data['choices'][0]['message']['content'] as String;

      // Parse JSON response
      final rankings = _parseRankingResponse(responseText, items);

      // Cache rankings
      await _cacheRanking(userId, carouselType, rankings);

      // Track analytics
      await _trackRankingAnalytics(
        userId: userId,
        carouselType: carouselType,
        itemsRanked: rankings.length,
        avgRelevance: rankings.isNotEmpty
            ? rankings
                      .map((r) => r['relevance_score'] as double)
                      .reduce((a, b) => a + b) /
                  rankings.length
            : 0.0,
      );

      return rankings;
    } catch (e) {
      print('Error generating personalized ranking: $e');
      // Fallback to chronological
      return items
          .asMap()
          .entries
          .map(
            (entry) => {
              ...entry.value,
              'position': entry.key + 1,
              'relevance_score': 0.5,
            },
          )
          .toList();
    }
  }

  String _constructRankingPrompt(
    Map<String, dynamic> behavior,
    List<Map<String, dynamic>> items,
  ) {
    final topCategories = behavior['top_categories'] as List;
    final avgTime = behavior['avg_view_duration'];
    final swipeRightRate = behavior['swipe_right_rate'];
    final swipeLeftRate = behavior['swipe_left_rate'];

    final itemsJson = items
        .map(
          (item) => {
            'id': item['id'],
            'title': item['title'],
            'category': item['category'] ?? item['content_type'],
            'engagement_metrics': {
              'views': item['views'] ?? 0,
              'likes': item['likes'] ?? 0,
              'shares': item['shares'] ?? 0,
            },
          },
        )
        .toList();

    return '''
Rank these carousel items for a user with the following preferences:

User Preferences:
- Top Categories: ${topCategories.join(', ')}
- Average Engagement Time: ${avgTime.toStringAsFixed(1)}s
- Swipe Patterns: ${swipeRightRate.toStringAsFixed(1)}% right, ${swipeLeftRate.toStringAsFixed(1)}% left

Items to Rank:
${jsonEncode(itemsJson)}

Return a JSON array with this exact structure:
[
  {
    "item_id": "uuid",
    "relevance_score": 0.95,
    "position": 1,
    "reasoning": "Brief explanation"
  }
]

Rank all ${items.length} items. Higher relevance_score (0-1) = better match. Position 1 = top ranked.
''';
  }

  List<Map<String, dynamic>> _parseRankingResponse(
    String responseText,
    List<Map<String, dynamic>> originalItems,
  ) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(
        r'\[\s*\{[\s\S]*\}\s*\]',
      ).firstMatch(responseText);
      if (jsonMatch == null) {
        throw Exception('No JSON array found in response');
      }

      final rankings = List<Map<String, dynamic>>.from(
        jsonDecode(jsonMatch.group(0)!) as List,
      );

      // Merge with original items
      final rankedItems = <Map<String, dynamic>>[];
      for (var ranking in rankings) {
        final itemId = ranking['item_id'] as String;
        final originalItem = originalItems.firstWhere(
          (item) => item['id'] == itemId,
          orElse: () => {},
        );

        if (originalItem.isNotEmpty) {
          rankedItems.add({
            ...originalItem,
            'relevance_score': ranking['relevance_score'] ?? 0.5,
            'position': ranking['position'] ?? rankedItems.length + 1,
            'ranking_reasoning': ranking['reasoning'] ?? '',
          });
        }
      }

      // Sort by position
      rankedItems.sort(
        (a, b) => (a['position'] as int).compareTo(b['position'] as int),
      );

      // Filter low relevance items
      return rankedItems
          .where((item) => (item['relevance_score'] as double) >= 0.3)
          .toList();
    } catch (e) {
      print('Error parsing ranking response: $e');
      return originalItems
          .asMap()
          .entries
          .map(
            (entry) => {
              ...entry.value,
              'position': entry.key + 1,
              'relevance_score': 0.5,
            },
          )
          .toList();
    }
  }

  // ============================================
  // CACHING
  // ============================================

  Future<List<Map<String, dynamic>>?> _getCachedRanking(
    String userId,
    String carouselType,
  ) async {
    try {
      final cached = await _supabase.client
          .from('carousel_ranking_cache')
          .select('ranked_items, expires_at')
          .eq('user_id', userId)
          .eq('carousel_type', carouselType)
          .maybeSingle();

      if (cached == null) return null;

      final expiresAt = DateTime.parse(cached['expires_at'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        return null;
      }

      return List<Map<String, dynamic>>.from(cached['ranked_items'] as List);
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheRanking(
    String userId,
    String carouselType,
    List<Map<String, dynamic>> rankings,
  ) async {
    try {
      await _supabase.client.from('carousel_ranking_cache').upsert({
        'user_id': userId,
        'carousel_type': carouselType,
        'ranked_items': rankings,
        'cached_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now()
            .add(const Duration(minutes: 15))
            .toIso8601String(),
      });
    } catch (e) {
      print('Error caching ranking: $e');
    }
  }

  Future<void> _trackRankingAnalytics({
    required String userId,
    required String carouselType,
    required int itemsRanked,
    required double avgRelevance,
  }) async {
    try {
      await _supabase.client.from('openai_ranking_analytics').insert({
        'user_id': userId,
        'carousel_type': carouselType,
        'items_ranked': itemsRanked,
        'avg_relevance_score': avgRelevance,
        'ranked_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error tracking ranking analytics: $e');
    }
  }
}
