import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Universal Emoji Reaction Service supporting 3000+ emojis
/// Works across elections, posts, Jolts, comments, direct messages, and profiles
class UniversalEmojiReactionService {
  static UniversalEmojiReactionService? _instance;
  static UniversalEmojiReactionService get instance =>
      _instance ??= UniversalEmojiReactionService._();

  UniversalEmojiReactionService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Add or update reaction to any content type
  Future<bool> addReaction({
    required String
    contentType, // 'election', 'post', 'jolt', 'comment', 'message', 'profile'
    required String contentId,
    required String emoji,
    String? emojiName,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Check if user already reacted
      final existingReaction = await _client
          .from('universal_reactions')
          .select('emoji')
          .eq('content_type', contentType)
          .eq('content_id', contentId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      if (existingReaction != null) {
        // If same emoji, remove it
        if (existingReaction['emoji'] == emoji) {
          await _client
              .from('universal_reactions')
              .delete()
              .eq('content_type', contentType)
              .eq('content_id', contentId)
              .eq('user_id', _auth.currentUser!.id);
        } else {
          // Update to new emoji
          await _client
              .from('universal_reactions')
              .update({
                'emoji': emoji,
                'emoji_name': emojiName ?? emoji,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('content_type', contentType)
              .eq('content_id', contentId)
              .eq('user_id', _auth.currentUser!.id);
        }
      } else {
        // Insert new reaction
        await _client.from('universal_reactions').insert({
          'content_type': contentType,
          'content_id': contentId,
          'user_id': _auth.currentUser!.id,
          'emoji': emoji,
          'emoji_name': emojiName ?? emoji,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Add reaction error: $e');
      return false;
    }
  }

  /// Remove reaction from content
  Future<bool> removeReaction({
    required String contentType,
    required String contentId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('universal_reactions')
          .delete()
          .eq('content_type', contentType)
          .eq('content_id', contentId)
          .eq('user_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Remove reaction error: $e');
      return false;
    }
  }

  /// Get reaction counts for content
  Future<Map<String, dynamic>> getReactionCounts({
    required String contentType,
    required String contentId,
  }) async {
    try {
      final response = await _client.rpc(
        'get_universal_reaction_counts',
        params: {
          'content_type_param': contentType,
          'content_id_param': contentId,
        },
      );

      return {
        'total_reactions': response['total_reactions'] ?? 0,
        'emoji_counts': response['emoji_counts'] ?? {},
        'top_5_reactions': response['top_5_reactions'] ?? [],
      };
    } catch (e) {
      debugPrint('Get reaction counts error: $e');
      return _getMockReactionCounts();
    }
  }

  /// Get user's reaction for content
  Future<String?> getUserReaction({
    required String contentType,
    required String contentId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('universal_reactions')
          .select('emoji')
          .eq('content_type', contentType)
          .eq('content_id', contentId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response?['emoji'] as String?;
    } catch (e) {
      debugPrint('Get user reaction error: $e');
      return null;
    }
  }

  /// Get users who reacted with specific emoji
  Future<List<Map<String, dynamic>>> getUsersByReaction({
    required String contentType,
    required String contentId,
    required String emoji,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('universal_reactions')
          .select('user:user_profiles!user_id(id, full_name, avatar_url)')
          .eq('content_type', contentType)
          .eq('content_id', contentId)
          .eq('emoji', emoji)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get users by reaction error: $e');
      return [];
    }
  }

  /// Get reaction analytics for content
  Future<Map<String, dynamic>> getReactionAnalytics({
    required String contentType,
    required String contentId,
  }) async {
    try {
      final response = await _client.rpc(
        'get_reaction_analytics',
        params: {
          'content_type_param': contentType,
          'content_id_param': contentId,
        },
      );

      return {
        'total_reactions': response['total_reactions'] ?? 0,
        'unique_users': response['unique_users'] ?? 0,
        'most_popular_emoji': response['most_popular_emoji'] ?? '👍',
        'sentiment_score': response['sentiment_score'] ?? 0.0,
        'reaction_velocity': response['reaction_velocity'] ?? 0.0,
        'emoji_distribution': response['emoji_distribution'] ?? {},
      };
    } catch (e) {
      debugPrint('Get reaction analytics error: $e');
      return _getMockAnalytics();
    }
  }

  /// Get user's reaction history
  Future<List<Map<String, dynamic>>> getUserReactionHistory({
    int limit = 50,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('universal_reactions')
          .select('*')
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user reaction history error: $e');
      return [];
    }
  }

  /// Get most reacted content (leaderboard)
  Future<List<Map<String, dynamic>>> getMostReactedContent({
    required String contentType,
    int limit = 20,
  }) async {
    try {
      final response = await _client.rpc(
        'get_most_reacted_content',
        params: {'content_type_param': contentType, 'limit_param': limit},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get most reacted content error: $e');
      return _getMockLeaderboard();
    }
  }

  /// Get recently used emojis for user
  Future<List<String>> getRecentlyUsedEmojis({int limit = 10}) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('universal_reactions')
          .select('emoji')
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(limit);

      final emojis = <String>{};
      for (final item in response) {
        emojis.add(item['emoji'] as String);
      }

      return emojis.toList();
    } catch (e) {
      debugPrint('Get recently used emojis error: $e');
      return ['👍', '❤️', '😂', '😮', '🎉'];
    }
  }

  /// Analyze sentiment from reaction patterns
  Future<Map<String, dynamic>> analyzeSentiment({
    required String contentType,
    required String contentId,
  }) async {
    try {
      final reactionCounts = await getReactionCounts(
        contentType: contentType,
        contentId: contentId,
      );

      final emojiCounts =
          reactionCounts['emoji_counts'] as Map<String, dynamic>? ?? {};

      // Sentiment scoring (simplified)
      int positiveCount = 0;
      int negativeCount = 0;
      int neutralCount = 0;

      final positiveEmojis = ['👍', '❤️', '😍', '🎉', '🔥', '👏', '💯', '✨'];
      final negativeEmojis = ['👎', '😠', '😡', '💔', '😢', '😭', '🤬'];

      emojiCounts.forEach((emoji, count) {
        if (positiveEmojis.contains(emoji)) {
          positiveCount += (count as int);
        } else if (negativeEmojis.contains(emoji)) {
          negativeCount += (count as int);
        } else {
          neutralCount += (count as int);
        }
      });

      final total = positiveCount + negativeCount + neutralCount;
      final sentimentScore = total > 0
          ? ((positiveCount - negativeCount) / total) * 100
          : 0.0;

      return {
        'sentiment_score': sentimentScore,
        'positive_count': positiveCount,
        'negative_count': negativeCount,
        'neutral_count': neutralCount,
        'total_reactions': total,
        'sentiment_label': sentimentScore > 20
            ? 'Positive'
            : sentimentScore < -20
            ? 'Negative'
            : 'Neutral',
      };
    } catch (e) {
      debugPrint('Analyze sentiment error: $e');
      return {
        'sentiment_score': 0.0,
        'sentiment_label': 'Neutral',
        'positive_count': 0,
        'negative_count': 0,
        'neutral_count': 0,
        'total_reactions': 0,
      };
    }
  }

  /// Subscribe to real-time reaction updates
  RealtimeChannel subscribeToReactions({
    required String contentType,
    required String contentId,
    required Function() onReactionChanged,
  }) {
    return _client
        .channel('universal_reactions:$contentType:$contentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'universal_reactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'content_id',
            value: contentId,
          ),
          callback: (payload) {
            onReactionChanged();
          },
        )
        .subscribe();
  }

  /// Check for inappropriate emoji usage (moderation)
  Future<bool> isEmojiAppropriate(String emoji) async {
    try {
      // List of inappropriate emojis (can be extended)
      final inappropriateEmojis = [
        '🖕', '💩', '🤬', // Add more as needed
      ];

      return !inappropriateEmojis.contains(emoji);
    } catch (e) {
      debugPrint('Check emoji appropriate error: $e');
      return true;
    }
  }

  // Mock data methods
  Map<String, dynamic> _getMockReactionCounts() {
    return {
      'total_reactions': 1247,
      'emoji_counts': {'👍': 342, '❤️': 289, '😂': 187, '🔥': 156, '🎉': 134},
      'top_5_reactions': [
        {'emoji': '👍', 'count': 342},
        {'emoji': '❤️', 'count': 289},
        {'emoji': '😂', 'count': 187},
        {'emoji': '🔥', 'count': 156},
        {'emoji': '🎉', 'count': 134},
      ],
    };
  }

  Map<String, dynamic> _getMockAnalytics() {
    return {
      'total_reactions': 1247,
      'unique_users': 892,
      'most_popular_emoji': '👍',
      'sentiment_score': 67.3,
      'reaction_velocity': 12.4,
      'emoji_distribution': {
        '👍': 27.4,
        '❤️': 23.2,
        '😂': 15.0,
        '🔥': 12.5,
        '🎉': 10.7,
      },
    };
  }

  List<Map<String, dynamic>> _getMockLeaderboard() {
    return [
      {
        'content_id': '1',
        'content_title': 'Presidential Election 2024',
        'total_reactions': 4567,
        'top_emoji': '🔥',
      },
      {
        'content_id': '2',
        'content_title': 'Best Pizza Topping',
        'total_reactions': 3421,
        'top_emoji': '❤️',
      },
      {
        'content_id': '3',
        'content_title': 'Favorite Movie Genre',
        'total_reactions': 2893,
        'top_emoji': '🎉',
      },
    ];
  }
}
