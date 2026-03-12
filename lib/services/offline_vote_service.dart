import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './voting_service.dart';

/// Service for offline vote caching, draft saving, and sync queue management
class OfflineVoteService {
  static OfflineVoteService? _instance;
  static OfflineVoteService get instance =>
      _instance ??= OfflineVoteService._();

  OfflineVoteService._();

  final VotingService _votingService = VotingService.instance;
  final Connectivity _connectivity = Connectivity();

  static const String _draftVotesKey = 'draft_votes';
  static const String _pendingVotesKey = 'pending_votes';
  static const String _lastSyncKey = 'last_sync_timestamp';

  /// Save vote draft locally
  Future<bool> saveDraft({
    required String electionId,
    required String electionTitle,
    String? selectedOptionId,
    List<String>? rankedChoices,
    List<String>? selectedOptions,
    Map<String, dynamic>? voteScores,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsJson = prefs.getString(_draftVotesKey) ?? '{}';
      final drafts = Map<String, dynamic>.from(json.decode(draftsJson));

      drafts[electionId] = {
        'election_id': electionId,
        'election_title': electionTitle,
        'selected_option_id': selectedOptionId,
        'ranked_choices': rankedChoices ?? [],
        'selected_options': selectedOptions ?? [],
        'vote_scores': voteScores ?? {},
        'saved_at': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_draftVotesKey, json.encode(drafts));
      debugPrint('Draft saved for election: $electionId');
      return true;
    } catch (e) {
      debugPrint('Save draft error: $e');
      return false;
    }
  }

  /// Get saved draft for specific election
  Future<Map<String, dynamic>?> getDraft(String electionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsJson = prefs.getString(_draftVotesKey) ?? '{}';
      final drafts = Map<String, dynamic>.from(json.decode(draftsJson));
      return drafts[electionId];
    } catch (e) {
      debugPrint('Get draft error: $e');
      return null;
    }
  }

  /// Get all saved drafts
  Future<List<Map<String, dynamic>>> getAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsJson = prefs.getString(_draftVotesKey) ?? '{}';
      final drafts = Map<String, dynamic>.from(json.decode(draftsJson));
      return drafts.values.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('Get all drafts error: $e');
      return [];
    }
  }

  /// Delete draft
  Future<bool> deleteDraft(String electionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsJson = prefs.getString(_draftVotesKey) ?? '{}';
      final drafts = Map<String, dynamic>.from(json.decode(draftsJson));
      drafts.remove(electionId);
      await prefs.setString(_draftVotesKey, json.encode(drafts));
      return true;
    } catch (e) {
      debugPrint('Delete draft error: $e');
      return false;
    }
  }

  /// Add vote to pending queue (for offline submission)
  Future<bool> addToPendingQueue({
    required String electionId,
    String? selectedOptionId,
    List<String>? rankedChoices,
    List<String>? selectedOptions,
    Map<String, dynamic>? voteScores,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getString(_pendingVotesKey) ?? '[]';
      final pending = List<Map<String, dynamic>>.from(json.decode(pendingJson));

      pending.add({
        'election_id': electionId,
        'selected_option_id': selectedOptionId,
        'ranked_choices': rankedChoices ?? [],
        'selected_options': selectedOptions ?? [],
        'vote_scores': voteScores ?? {},
        'queued_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });

      await prefs.setString(_pendingVotesKey, json.encode(pending));
      debugPrint('Vote added to pending queue: $electionId');

      // Delete draft after adding to queue
      await deleteDraft(electionId);

      return true;
    } catch (e) {
      debugPrint('Add to pending queue error: $e');
      return false;
    }
  }

  /// Get pending votes count
  Future<int> getPendingVotesCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getString(_pendingVotesKey) ?? '[]';
      final pending = List<dynamic>.from(json.decode(pendingJson));
      return pending.length;
    } catch (e) {
      debugPrint('Get pending count error: $e');
      return 0;
    }
  }

  /// Sync pending votes when connectivity returns
  Future<Map<String, dynamic>> syncPendingVotes() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return {
          'success': false,
          'message': 'No internet connection',
          'synced': 0,
          'failed': 0,
        };
      }

      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getString(_pendingVotesKey) ?? '[]';
      final pending = List<Map<String, dynamic>>.from(json.decode(pendingJson));

      if (pending.isEmpty) {
        return {
          'success': true,
          'message': 'No pending votes to sync',
          'synced': 0,
          'failed': 0,
        };
      }

      int synced = 0;
      int failed = 0;
      final List<Map<String, dynamic>> failedVotes = [];

      for (var vote in pending) {
        final success = await _votingService.castVote(
          electionId: vote['election_id'],
          selectedOptionId: vote['selected_option_id'],
          rankedChoices: List<String>.from(vote['ranked_choices'] ?? []),
          selectedOptions: List<String>.from(vote['selected_options'] ?? []),
          voteScores: Map<String, dynamic>.from(vote['vote_scores'] ?? {}),
        );

        if (success) {
          synced++;
        } else {
          failed++;
          vote['retry_count'] = (vote['retry_count'] ?? 0) + 1;
          if (vote['retry_count'] < 3) {
            failedVotes.add(vote);
          }
        }
      }

      // Update pending queue with only failed votes
      await prefs.setString(_pendingVotesKey, json.encode(failedVotes));

      // Update last sync timestamp
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      debugPrint('Sync completed: $synced synced, $failed failed');

      return {
        'success': true,
        'message': 'Sync completed',
        'synced': synced,
        'failed': failed,
      };
    } catch (e) {
      debugPrint('Sync pending votes error: $e');
      return {
        'success': false,
        'message': 'Sync error: $e',
        'synced': 0,
        'failed': 0,
      };
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastSyncKey);
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      debugPrint('Get last sync time error: $e');
      return null;
    }
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Check online status error: $e');
      return false;
    }
  }

  /// Listen to connectivity changes
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) {
      return !results.contains(ConnectivityResult.none);
    });
  }

  /// Clear all offline data
  Future<bool> clearAllOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftVotesKey);
      await prefs.remove(_pendingVotesKey);
      await prefs.remove(_lastSyncKey);
      return true;
    } catch (e) {
      debugPrint('Clear offline data error: $e');
      return false;
    }
  }
}
