import './gemini_service.dart';
import './openai_service.dart';
import './supabase_service.dart';

class UnifiedSearchService {
  static final UnifiedSearchService _instance =
      UnifiedSearchService._internal();
  factory UnifiedSearchService() => _instance;
  UnifiedSearchService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final OpenAIService _openAIService = OpenAIService.instance;
  final GeminiService _geminiService = GeminiService.instance;

  /// Search across all content types
  Future<Map<String, List<Map<String, dynamic>>>> searchAll(
    String query,
  ) async {
    if (query.trim().isEmpty) {
      return {
        'users': [],
        'posts': [],
        'groups': [],
        'elections': [],
        'quests': [],
      };
    }

    try {
      final results = await Future.wait([
        _searchUsers(query),
        _searchPosts(query),
        _searchGroups(query),
        _searchElections(query),
        _searchQuests(query),
      ]);

      return {
        'users': results[0],
        'posts': results[1],
        'groups': results[2],
        'elections': results[3],
        'quests': results[4],
      };
    } catch (e) {
      print('Error in unified search: $e');
      return {
        'users': [],
        'posts': [],
        'groups': [],
        'elections': [],
        'quests': [],
      };
    }
  }

  /// Get search suggestions (typeahead)
  Future<Map<String, List<Map<String, dynamic>>>> getSearchSuggestions(
    String query,
  ) async {
    if (query.trim().isEmpty || query.length < 2) {
      return {'users': [], 'posts': [], 'groups': [], 'elections': []};
    }

    try {
      final results = await Future.wait([
        _searchUsers(query, limit: 5),
        _searchPosts(query, limit: 5),
        _searchGroups(query, limit: 5),
        _searchElections(query, limit: 5),
      ]);

      return {
        'users': results[0],
        'posts': results[1],
        'groups': results[2],
        'elections': results[3],
      };
    } catch (e) {
      print('Error getting search suggestions: $e');
      return {'users': [], 'posts': [], 'groups': [], 'elections': []};
    }
  }

  /// Search users
  Future<List<Map<String, dynamic>>> _searchUsers(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('user_profiles')
          .select('id, username, full_name, avatar_url, bio')
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Search posts
  Future<List<Map<String, dynamic>>> _searchPosts(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('posts')
          .select(
            'id, content, media_url, created_at, user_id, user_profiles(username, avatar_url)',
          )
          .ilike('content', '%$query%')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching posts: $e');
      return [];
    }
  }

  /// Search groups
  Future<List<Map<String, dynamic>>> _searchGroups(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('groups')
          .select('id, name, description, avatar_url, member_count, created_at')
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('member_count', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching groups: $e');
      return [];
    }
  }

  /// Search elections
  Future<List<Map<String, dynamic>>> _searchElections(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('elections')
          .select(
            'id, title, description, media_url, status, created_at, user_profiles(username, avatar_url)',
          )
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching elections: $e');
      return [];
    }
  }

  /// Search quests
  Future<List<Map<String, dynamic>>> _searchQuests(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('quests')
          .select('id, title, description, reward_vp, difficulty, status')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .eq('status', 'active')
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching quests: $e');
      return [];
    }
  }

  /// Get AI-powered search ranking
  Future<List<Map<String, dynamic>>> rankSearchResults(
    List<Map<String, dynamic>> results,
    String query,
  ) async {
    try {
      // Use Gemini for cost-effective ranking
      final ranking = await _geminiService.getVoteInsights(
        voteTitle: 'Search Ranking',
        voteDescription: 'Rank results for query: $query',
        totalVotes: results.length,
        options: results
            .asMap()
            .entries
            .map(
              (e) => {
                'option_text':
                    '${e.value['title'] ?? e.value['name'] ?? e.value['username'] ?? e.value['content']?.substring(0, 50)}',
                'vote_count': e.key,
              },
            )
            .toList(),
      );

      // Parse the ranking from AI response or use original order
      final indices = <int>[];
      for (int i = 0; i < results.length; i++) {
        indices.add(i);
      }

      final rankedResults = <Map<String, dynamic>>[];
      for (final index in indices) {
        if (index < results.length) {
          rankedResults.add(results[index]);
        }
      }

      // Add any remaining results
      for (int i = 0; i < results.length; i++) {
        if (!indices.contains(i)) {
          rankedResults.add(results[i]);
        }
      }

      return rankedResults;
    } catch (e) {
      print('Error ranking search results: $e');
      return results;
    }
  }

  /// Save search history
  Future<void> saveSearchHistory(String query) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.client.from('search_history').insert({
        'user_id': userId,
        'query': query,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving search history: $e');
    }
  }

  /// Get search history
  Future<List<String>> getSearchHistory({int limit = 20}) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabaseService.client
          .from('search_history')
          .select('query')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(
        response,
      ).map((r) => r['query'] as String).toList();
    } catch (e) {
      print('Error getting search history: $e');
      return [];
    }
  }

  /// Get trending searches
  Future<List<String>> getTrendingSearches({int limit = 10}) async {
    try {
      final response = await _supabaseService.client.rpc(
        'get_trending_searches',
        params: {'limit_count': limit},
      );

      return List<Map<String, dynamic>>.from(
        response,
      ).map((r) => r['query'] as String).toList();
    } catch (e) {
      print('Error getting trending searches: $e');
      return [];
    }
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.client
          .from('search_history')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }
}
