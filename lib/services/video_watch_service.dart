import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Video Watch Time Enforcement Service
class VideoWatchService {
  static VideoWatchService? _instance;
  static VideoWatchService get instance => _instance ??= VideoWatchService._();

  VideoWatchService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Update video watch progress
  Future<bool> updateWatchProgress({
    required String electionId,
    required int videoIndex,
    required int watchDurationSeconds,
    required int totalVideoDurationSeconds,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final userId = _auth.currentUser!.id;
      final watchPercentage =
          (watchDurationSeconds / totalVideoDurationSeconds * 100).clamp(
            0,
            100,
          );

      // Get election video requirements
      final election = await _client
          .from('elections')
          .select(
            'video_min_watch_seconds, video_min_watch_percentage, video_watch_enforcement_type',
          )
          .eq('id', electionId)
          .single();

      final minWatchSeconds = election['video_min_watch_seconds'] as int? ?? 0;
      final minWatchPercentage =
          election['video_min_watch_percentage'] as int? ?? 0;
      final enforcementType =
          election['video_watch_enforcement_type'] as String? ?? 'seconds';

      // Determine if requirement met
      bool completedRequirement = false;
      if (enforcementType == 'seconds') {
        completedRequirement = watchDurationSeconds >= minWatchSeconds;
      } else {
        completedRequirement = watchPercentage >= minWatchPercentage;
      }

      // Upsert watch progress
      await _client.from('voter_video_watch_progress').upsert({
        'election_id': electionId,
        'voter_id': userId,
        'video_index': videoIndex,
        'watch_duration_seconds': watchDurationSeconds,
        'total_video_duration_seconds': totalVideoDurationSeconds,
        'watch_percentage': watchPercentage,
        'completed_requirement': completedRequirement,
        'last_watched_at': DateTime.now().toIso8601String(),
      });

      // Update analytics
      await _client.rpc(
        'update_video_analytics',
        params: {'p_election_id': electionId, 'p_video_index': videoIndex},
      );

      return true;
    } catch (e) {
      debugPrint('Update watch progress error: $e');
      return false;
    }
  }

  /// Get video watch progress for voter
  Future<Map<String, dynamic>?> getWatchProgress({
    required String electionId,
    required int videoIndex,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final userId = _auth.currentUser!.id;

      final response = await _client
          .from('voter_video_watch_progress')
          .select()
          .eq('election_id', electionId)
          .eq('voter_id', userId)
          .eq('video_index', videoIndex)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get watch progress error: $e');
      return null;
    }
  }

  /// Check if all videos watched
  Future<bool> hasCompletedAllVideos(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final userId = _auth.currentUser!.id;

      // Get election video URLs
      final election = await _client
          .from('elections')
          .select('video_urls')
          .eq('id', electionId)
          .single();

      final videoUrls = List<String>.from(election['video_urls'] ?? []);
      if (videoUrls.isEmpty) return true;

      // Check progress for each video
      for (int i = 0; i < videoUrls.length; i++) {
        final progress = await getWatchProgress(
          electionId: electionId,
          videoIndex: i,
        );

        if (progress == null || progress['completed_requirement'] != true) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Check all videos completed error: $e');
      return false;
    }
  }

  /// Get video watch analytics for creator
  Future<List<Map<String, dynamic>>> getVideoAnalytics(
    String electionId,
  ) async {
    try {
      final response = await _client
          .from('video_watch_analytics')
          .select()
          .eq('election_id', electionId)
          .order('video_index', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get video analytics error: $e');
      return [];
    }
  }

  /// Calculate remaining watch time
  Map<String, dynamic> calculateRemainingTime({
    required int currentWatchSeconds,
    required int totalDurationSeconds,
    required int minWatchSeconds,
    required int minWatchPercentage,
    required String enforcementType,
  }) {
    if (enforcementType == 'seconds') {
      final remainingSeconds = (minWatchSeconds - currentWatchSeconds).clamp(
        0,
        minWatchSeconds,
      );
      return {
        'remaining_seconds': remainingSeconds,
        'is_completed': currentWatchSeconds >= minWatchSeconds,
        'progress_percentage': (currentWatchSeconds / minWatchSeconds * 100)
            .clamp(0, 100),
      };
    } else {
      final currentPercentage =
          (currentWatchSeconds / totalDurationSeconds * 100).clamp(0, 100);
      final remainingPercentage = (minWatchPercentage - currentPercentage)
          .clamp(0, minWatchPercentage);
      return {
        'remaining_percentage': remainingPercentage,
        'is_completed': currentPercentage >= minWatchPercentage,
        'progress_percentage': (currentPercentage / minWatchPercentage * 100)
            .clamp(0, 100),
      };
    }
  }
}
