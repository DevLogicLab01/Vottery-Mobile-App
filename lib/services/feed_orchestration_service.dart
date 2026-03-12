import '../services/supabase_service.dart';
import '../services/openai_service.dart';
import 'dart:async';

class FeedOrchestrationService {
  final _supabase = SupabaseService.instance.client;
  final _openaiService = OpenAIService.instance;

  /// Calculate multi-factor content score
  Future<Map<String, dynamic>> calculateContentScore({
    required String contentId,
    required String contentType,
    required String userId,
  }) async {
    try {
      // Base engagement score from historical metrics
      final engagementData = await _supabase
          .from('carousel_interactions')
          .select('interaction_type')
          .eq('content_id', contentId)
          .limit(100);

      final totalInteractions = engagementData.length;
      final positiveInteractions = engagementData
          .where(
            (i) =>
                ['swipe_right', 'tap', 'hold'].contains(i['interaction_type']),
          )
          .length;
      final baseEngagementScore = totalInteractions > 0
          ? (positiveInteractions / totalInteractions * 100)
          : 50.0;

      // Recency score (time decay)
      final recencyScore =
          100.0; // Simplified - would calculate based on creation time

      // Social proof score
      final socialProofScore =
          50.0; // Simplified - would calculate from followers/engagement

      // Personalization score (from OpenAI ranking cache if available)
      final personalizationScore = 60.0; // Simplified

      // Diversity penalty
      final diversityPenalty = 0.0; // Simplified - would check recent content

      // Calculate weighted final score
      final finalScore =
          (baseEngagementScore * 0.25) +
          (recencyScore * 0.20) +
          (socialProofScore * 0.15) +
          (personalizationScore * 0.30) +
          diversityPenalty;

      // Determine carousel assignment
      final assignedCarousel = _assignToCarousel(contentType, finalScore);

      // Save score to database
      await _supabase.from('content_orchestration_scores').insert({
        'content_id': contentId,
        'content_type': contentType,
        'base_engagement_score': baseEngagementScore,
        'recency_score': recencyScore,
        'social_proof_score': socialProofScore,
        'personalization_score': personalizationScore,
        'diversity_penalty': diversityPenalty,
        'final_score': finalScore,
        'assigned_carousel': assignedCarousel,
        'expires_at': DateTime.now()
            .add(const Duration(minutes: 10))
            .toIso8601String(),
      });

      return {
        'final_score': finalScore,
        'assigned_carousel': assignedCarousel,
        'components': {
          'base_engagement': baseEngagementScore,
          'recency': recencyScore,
          'social_proof': socialProofScore,
          'personalization': personalizationScore,
        },
      };
    } catch (e) {
      throw Exception('Failed to calculate content score: $e');
    }
  }

  /// Assign content to appropriate carousel type
  String _assignToCarousel(String contentType, double score) {
    // Rule-based assignment
    if (['jolt', 'moment', 'spotlight'].contains(contentType)) {
      return 'horizontal';
    } else if (['group', 'election', 'service'].contains(contentType)) {
      return 'vertical';
    } else if (['topic', 'earner', 'champion'].contains(contentType)) {
      return 'gradient';
    }

    // Fallback based on score
    if (score >= 80) return 'horizontal';
    if (score >= 60) return 'vertical';
    return 'gradient';
  }

  /// Get feed sequence for user (Rhythm of 3 pattern)
  Future<Map<String, dynamic>> getFeedSequence(String userId) async {
    try {
      // Get or create user's feed state
      final stateData = await _supabase
          .from('feed_sequence_state')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (stateData == null) {
        // Create initial state
        await _supabase.from('feed_sequence_state').insert({
          'user_id': userId,
          'current_sequence_position': 0,
          'carousel_rotation_queue': ['horizontal', 'vertical', 'gradient'],
        });

        return {
          'position': 0,
          'next_carousel': 'horizontal',
          'posts_until_carousel': 2,
        };
      }

      final position = stateData['current_sequence_position'] ?? 0;
      final queue = List<String>.from(
        stateData['carousel_rotation_queue'] ??
            ['horizontal', 'vertical', 'gradient'],
      );

      // Rhythm of 3: 2-3 posts, then carousel
      final postsUntilCarousel = 3 - (position % 3);
      final nextCarousel = queue[0];

      return {
        'position': position,
        'next_carousel': nextCarousel,
        'posts_until_carousel': postsUntilCarousel,
        'rotation_queue': queue,
      };
    } catch (e) {
      throw Exception('Failed to get feed sequence: $e');
    }
  }

  /// Update feed sequence after content insertion
  Future<void> updateFeedSequence(
    String userId,
    String insertedCarouselType,
  ) async {
    try {
      final stateData = await _supabase
          .from('feed_sequence_state')
          .select()
          .eq('user_id', userId)
          .single();

      final currentPosition = stateData['current_sequence_position'] ?? 0;
      final queue = List<String>.from(
        stateData['carousel_rotation_queue'] ??
            ['horizontal', 'vertical', 'gradient'],
      );

      // Rotate queue
      queue.removeAt(0);
      queue.add(insertedCarouselType);

      await _supabase
          .from('feed_sequence_state')
          .update({
            'current_sequence_position': currentPosition + 1,
            'last_carousel_type': insertedCarouselType,
            'carousel_rotation_queue': queue,
            'last_updated': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update feed sequence: $e');
    }
  }

  /// Get orchestration performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      final metrics = await _supabase
          .from('orchestration_performance_metrics')
          .select()
          .order('time_period', ascending: false)
          .limit(1)
          .maybeSingle();

      if (metrics == null) {
        return {
          'avg_final_score': 0.0,
          'total_impressions': 0,
          'total_engagements': 0,
          'engagement_rate': 0.0,
          'revenue_generated': 0.0,
        };
      }

      return metrics;
    } catch (e) {
      throw Exception('Failed to get performance metrics: $e');
    }
  }

  /// Real-time content distribution
  Stream<Map<String, dynamic>> watchContentDistribution() {
    return _supabase
        .from('content_orchestration_scores')
        .stream(primaryKey: ['score_id'])
        .order('scored_at', ascending: false)
        .map(
          (data) => {
            'total_scored': data.length,
            'avg_score': data.isEmpty
                ? 0.0
                : data
                          .map((e) => e['final_score'] ?? 0)
                          .reduce((a, b) => a + b) /
                      data.length,
            'by_carousel': _groupByCarousel(data),
          },
        );
  }

  Map<String, int> _groupByCarousel(List<Map<String, dynamic>> data) {
    final grouped = <String, int>{};
    for (final item in data) {
      final carousel = item['assigned_carousel'] ?? 'unknown';
      grouped[carousel] = (grouped[carousel] ?? 0) + 1;
    }
    return grouped;
  }
}