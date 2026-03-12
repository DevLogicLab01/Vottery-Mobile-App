import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

class CreatorAcademyService {
  static CreatorAcademyService? _instance;
  static CreatorAcademyService get instance =>
      _instance ??= CreatorAcademyService._();

  CreatorAcademyService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get all academy tiers
  Future<List<Map<String, dynamic>>> getAcademyTiers() async {
    try {
      final response = await _client
          .from('creator_academy_tiers')
          .select('*')
          .order('tier_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get academy tiers error: $e');
      return [];
    }
  }

  /// Get modules for a specific tier
  Future<List<Map<String, dynamic>>> getModulesByTier(String tierLevel) async {
    try {
      final response = await _client
          .from('creator_academy_modules')
          .select('*')
          .eq('tier_level', tierLevel)
          .order('module_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get modules by tier error: $e');
      return [];
    }
  }

  /// Get video tutorials for a module
  Future<List<Map<String, dynamic>>> getVideoTutorials(String moduleId) async {
    try {
      final response = await _client
          .from('creator_academy_video_tutorials')
          .select('*')
          .eq('module_id', moduleId)
          .order('video_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get video tutorials error: $e');
      return [];
    }
  }

  /// Get quiz for a module
  Future<Map<String, dynamic>?> getModuleQuiz(String moduleId) async {
    try {
      final response = await _client
          .from('creator_academy_quizzes')
          .select('*')
          .eq('module_id', moduleId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Get module quiz error: $e');
      return null;
    }
  }

  /// Get quiz questions
  Future<List<Map<String, dynamic>>> getQuizQuestions(String quizId) async {
    try {
      final response = await _client
          .from('creator_academy_quiz_questions')
          .select('*')
          .eq('quiz_id', quizId)
          .order('question_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get quiz questions error: $e');
      return [];
    }
  }

  /// Get creator progress
  Future<Map<String, dynamic>?> getCreatorProgress() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('creator_progress')
          .select('*')
          .eq('creator_id', _auth.currentUser!.id)
          .maybeSingle();

      if (response == null) {
        await _client.from('creator_progress').insert({
          'creator_id': _auth.currentUser!.id,
          'current_tier': 'beginner',
          'total_xp': 0,
        });

        return {
          'creator_id': _auth.currentUser!.id,
          'current_tier': 'beginner',
          'total_xp': 0,
          'modules_completed': 0,
          'quizzes_passed': 0,
          'videos_watched': 0,
          'completion_percentage': 0,
        };
      }

      return response;
    } catch (e) {
      debugPrint('Get creator progress error: $e');
      return null;
    }
  }

  /// Get module progress for creator
  Future<List<Map<String, dynamic>>> getModuleProgress() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('creator_module_progress')
          .select('*')
          .eq('creator_id', _auth.currentUser!.id);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get module progress error: $e');
      return [];
    }
  }

  /// Mark module as completed
  Future<bool> completeModule(String moduleId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('creator_module_progress').upsert({
        'creator_id': _auth.currentUser!.id,
        'module_id': moduleId,
        'is_completed': true,
        'completion_date': DateTime.now().toIso8601String(),
      });

      await _client.rpc(
        'award_creator_xp',
        params: {'p_creator_id': _auth.currentUser!.id, 'p_xp_amount': 100},
      );

      return true;
    } catch (e) {
      debugPrint('Complete module error: $e');
      return false;
    }
  }

  /// Submit quiz attempt
  Future<Map<String, dynamic>?> submitQuizAttempt({
    required String quizId,
    required int scorePercentage,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final status = scorePercentage >= 80 ? 'passed' : 'failed';

      final response = await _client
          .from('creator_quiz_attempts')
          .insert({
            'creator_id': _auth.currentUser!.id,
            'quiz_id': quizId,
            'score_percentage': scorePercentage,
            'status': status,
            'answers': answers,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      if (status == 'passed') {
        await _client.rpc(
          'award_creator_xp',
          params: {'p_creator_id': _auth.currentUser!.id, 'p_xp_amount': 150},
        );
      }

      return response;
    } catch (e) {
      debugPrint('Submit quiz attempt error: $e');
      return null;
    }
  }

  /// Update video progress
  Future<bool> updateVideoProgress({
    required String videoId,
    required int watchTimeSeconds,
    required bool isCompleted,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('creator_video_progress').upsert({
        'creator_id': _auth.currentUser!.id,
        'video_id': videoId,
        'watch_time_seconds': watchTimeSeconds,
        'is_completed': isCompleted,
        'last_watched_at': DateTime.now().toIso8601String(),
      });

      if (isCompleted) {
        await _client.rpc(
          'award_creator_xp',
          params: {'p_creator_id': _auth.currentUser!.id, 'p_xp_amount': 50},
        );
      }

      return true;
    } catch (e) {
      debugPrint('Update video progress error: $e');
      return false;
    }
  }

  /// Get academy achievements
  Future<List<Map<String, dynamic>>> getAcademyAchievements() async {
    try {
      final response = await _client
          .from('creator_academy_achievements')
          .select('*')
          .order('xp_reward', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get academy achievements error: $e');
      return [];
    }
  }

  /// Get unlocked achievements for creator
  Future<List<Map<String, dynamic>>> getUnlockedAchievements() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('creator_unlocked_achievements')
          .select('*, creator_academy_achievements(*)')
          .eq('creator_id', _auth.currentUser!.id)
          .order('unlocked_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get unlocked achievements error: $e');
      return [];
    }
  }

  /// Get creator certifications
  Future<List<Map<String, dynamic>>> getCreatorCertifications() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('creator_certifications')
          .select('*')
          .eq('creator_id', _auth.currentUser!.id)
          .order('issued_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get creator certifications error: $e');
      return [];
    }
  }

  /// Get quiz attempts for a quiz
  Future<List<Map<String, dynamic>>> getQuizAttempts(String quizId) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('creator_quiz_attempts')
          .select('*')
          .eq('creator_id', _auth.currentUser!.id)
          .eq('quiz_id', quizId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get quiz attempts error: $e');
      return [];
    }
  }
}
