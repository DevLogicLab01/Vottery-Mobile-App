import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Service for managing presentation slides and deck files
class PresentationSlidesService {
  static PresentationSlidesService? _instance;
  static PresentationSlidesService get instance =>
      _instance ??= PresentationSlidesService._();

  PresentationSlidesService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Upload presentation deck file
  Future<Map<String, dynamic>?> uploadDeckFile({
    required String electionId,
    required String fileName,
    required List<int> fileBytes,
    required String fileType,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final filePath =
          'presentations/$electionId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _client.storage
          .from('presentation-decks')
          .uploadBinary(filePath, Uint8List.fromList(fileBytes));

      final fileUrl = _client.storage
          .from('presentation-decks')
          .getPublicUrl(filePath);

      final response = await _client
          .from('presentation_deck_files')
          .insert({
            'election_id': electionId,
            'created_by': _auth.currentUser!.id,
            'file_name': fileName,
            'file_url': fileUrl,
            'file_type': fileType,
            'file_size_bytes': fileBytes.length,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('Upload deck file error: $e');
      return null;
    }
  }

  /// Get presentation deck files for an election
  Future<List<Map<String, dynamic>>> getDeckFiles({
    required String electionId,
  }) async {
    try {
      final response = await _client
          .from('presentation_deck_files')
          .select('*, creator:user_profiles!created_by(full_name)')
          .eq('election_id', electionId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get deck files error: $e');
      return [];
    }
  }

  /// Get slides for an election
  Future<List<Map<String, dynamic>>> getSlides({
    required String electionId,
  }) async {
    try {
      final response = await _client
          .from('presentation_slides')
          .select('*, metadata:slide_metadata(*)')
          .eq('election_id', electionId)
          .order('slide_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get slides error: $e');
      return [];
    }
  }

  /// Create or update slide metadata
  Future<bool> updateSlideMetadata({
    required String slideId,
    String? speakerNotes,
    int? durationSeconds,
    bool? autoAdvance,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('slide_metadata').upsert({
        'slide_id': slideId,
        if (speakerNotes != null) 'speaker_notes': speakerNotes,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (autoAdvance != null) 'auto_advance': autoAdvance,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'slide_id');

      return true;
    } catch (e) {
      debugPrint('Update slide metadata error: $e');
      return false;
    }
  }

  /// Toggle slide bookmark
  Future<bool> toggleBookmark({required String slideId}) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final metadata = await _client
          .from('slide_metadata')
          .select('bookmarked_by')
          .eq('slide_id', slideId)
          .maybeSingle();

      List<String> bookmarkedBy = [];
      if (metadata != null && metadata['bookmarked_by'] != null) {
        bookmarkedBy = List<String>.from(metadata['bookmarked_by']);
      }

      final userId = _auth.currentUser!.id;
      if (bookmarkedBy.contains(userId)) {
        bookmarkedBy.remove(userId);
      } else {
        bookmarkedBy.add(userId);
      }

      await _client.from('slide_metadata').upsert({
        'slide_id': slideId,
        'bookmarked_by': bookmarkedBy,
      }, onConflict: 'slide_id');

      return true;
    } catch (e) {
      debugPrint('Toggle bookmark error: $e');
      return false;
    }
  }

  /// Vote on a slide
  Future<bool> voteOnSlide({
    required String slideId,
    required String voteOption,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('slide_votes').upsert({
        'slide_id': slideId,
        'user_id': _auth.currentUser!.id,
        'vote_option': voteOption,
      }, onConflict: 'slide_id,user_id');

      return true;
    } catch (e) {
      debugPrint('Vote on slide error: $e');
      return false;
    }
  }

  /// Track slide view
  Future<bool> trackSlideView({
    required String slideId,
    int timeSpentSeconds = 0,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final existing = await _client
          .from('slide_analytics')
          .select('id, view_count, time_spent_seconds')
          .eq('slide_id', slideId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('slide_analytics')
            .update({
              'view_count': (existing['view_count'] as int? ?? 0) + 1,
              'time_spent_seconds':
                  (existing['time_spent_seconds'] as int? ?? 0) +
                  timeSpentSeconds,
              'last_viewed_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        await _client.from('slide_analytics').insert({
          'slide_id': slideId,
          'user_id': _auth.currentUser!.id,
          'view_count': 1,
          'time_spent_seconds': timeSpentSeconds,
          'last_viewed_at': DateTime.now().toIso8601String(),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Track slide view error: $e');
      return false;
    }
  }

  /// Get slide analytics
  Future<Map<String, dynamic>?> getSlideAnalytics({
    required String slideId,
  }) async {
    try {
      final response = await _client
          .from('slide_analytics')
          .select('*')
          .eq('slide_id', slideId);

      if (response.isEmpty) return null;

      final analytics = List<Map<String, dynamic>>.from(response);
      final totalViews = analytics.fold<int>(
        0,
        (sum, item) => sum + (item['view_count'] as int? ?? 0),
      );
      final totalTimeSpent = analytics.fold<int>(
        0,
        (sum, item) => sum + (item['time_spent_seconds'] as int? ?? 0),
      );

      return {
        'total_views': totalViews,
        'total_time_spent_seconds': totalTimeSpent,
        'unique_viewers': analytics.length,
        'average_time_per_view': totalViews > 0
            ? (totalTimeSpent / totalViews).round()
            : 0,
      };
    } catch (e) {
      debugPrint('Get slide analytics error: $e');
      return null;
    }
  }
}
