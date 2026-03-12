import 'dart:async';

import 'package:flutter/material.dart';

import './supabase_service.dart';

class LeaderboardUser {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int rank;
  final int primaryCount;
  final int secondaryCount;

  LeaderboardUser({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.rank,
    required this.primaryCount,
    this.secondaryCount = 0,
  });

  factory LeaderboardUser.fromMap(Map<String, dynamic> map, int rank) {
    return LeaderboardUser(
      userId: map['user_id']?.toString() ?? '',
      username: map['username']?.toString() ?? 'Anonymous',
      avatarUrl: map['avatar_url']?.toString(),
      rank: rank,
      primaryCount: (map['primary_count'] as num?)?.toInt() ?? 0,
      secondaryCount: (map['secondary_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CommunityEngagementService {
  static final CommunityEngagementService instance =
      CommunityEngagementService._internal();
  CommunityEngagementService._internal();

  final _client = SupabaseService.instance.client;

  // Cache storage
  List<LeaderboardUser>? _feedbackContributionsCache;
  List<LeaderboardUser>? _votingParticipationCache;
  List<LeaderboardUser>? _featureAdoptionCache;
  DateTime? _feedbackCacheExpiry;
  DateTime? _votingCacheExpiry;
  DateTime? _adoptionCacheExpiry;

  Future<List<LeaderboardUser>> getFeedbackContributionsLeaderboard() async {
    if (_feedbackContributionsCache != null &&
        _feedbackCacheExpiry != null &&
        DateTime.now().isBefore(_feedbackCacheExpiry!)) {
      return _feedbackContributionsCache!;
    }

    try {
      final response = await _client
          .from('feature_requests')
          .select('user_id, user_profiles!inner(username, avatar_url)')
          .order('created_at', ascending: false)
          .limit(50);

      // Group by user_id and count
      final Map<String, Map<String, dynamic>> userMap = {};
      for (final item in response as List) {
        final userId = item['user_id']?.toString() ?? '';
        if (userId.isEmpty) continue;
        final profile = item['user_profiles'] as Map<String, dynamic>?;
        if (!userMap.containsKey(userId)) {
          userMap[userId] = {
            'user_id': userId,
            'username': profile?['username'] ?? 'Anonymous',
            'avatar_url': profile?['avatar_url'],
            'primary_count': 0,
            'secondary_count': 0,
          };
        }
        userMap[userId]!['primary_count'] =
            (userMap[userId]!['primary_count'] as int) + 1;
      }

      final sorted = userMap.values.toList()
        ..sort(
          (a, b) =>
              (b['primary_count'] as int).compareTo(a['primary_count'] as int),
        );

      final result = sorted
          .take(50)
          .toList()
          .asMap()
          .entries
          .map((e) => LeaderboardUser.fromMap(e.value, e.key + 1))
          .toList();

      _feedbackContributionsCache = result;
      _feedbackCacheExpiry = DateTime.now().add(const Duration(minutes: 10));
      return result;
    } catch (e) {
      debugPrint('getFeedbackContributionsLeaderboard error: $e');
      return _getMockFeedbackLeaderboard();
    }
  }

  /// Unified community leaderboard: feedback contributions + votes + comments (sync with Web feedbackService.getCommunityLeaderboard)
  Future<List<Map<String, dynamic>>> getCommunityLeaderboard({String timeRange = '30d'}) async {
    try {
      final now = DateTime.now();
      DateTime start;
      if (timeRange == '7d') {
        start = now.subtract(const Duration(days: 7));
      } else if (timeRange == '90d') {
        start = now.subtract(const Duration(days: 90));
      } else {
        start = now.subtract(const Duration(days: 30));
      }
      final startIso = start.toUtc().toIso8601String();

      final requestsRes = await _client.from('feature_requests').select('user_id').gte('created_at', startIso);
      final votesRes = await _client.from('feature_votes').select('user_id').gte('created_at', startIso);
      final commentsRes = await _client.from('feature_comments').select('user_id').gte('created_at', startIso);

      final requests = requestsRes as List;
      final votes = votesRes as List;
      final comments = commentsRes as List;

      final Map<String, Map<String, dynamic>> scores = {};
      void add(String? userId, String key, [int amount = 1]) {
        if (userId == null || userId.isEmpty) return;
        scores.putIfAbsent(userId, () => {'userId': userId, 'featureRequests': 0, 'votes': 0, 'comments': 0, 'score': 0});
        scores[userId]![key] = (scores[userId]![key] as int) + amount;
      }
      for (final r in requests) {
        add(r['user_id']?.toString(), 'featureRequests');
      }
      for (final v in votes) {
        add(v['user_id']?.toString(), 'votes');
      }
      for (final c in comments) {
        add(c['user_id']?.toString(), 'comments');
      }

      for (final row in scores.values) {
        row['score'] = (row['featureRequests'] as int) * 3 + (row['votes'] as int) * 1 + (row['comments'] as int) * 2;
      }

      final leaderboard = scores.values.toList()
        ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      final top = leaderboard.take(50).toList();
      final userIds = top.map((e) => e['userId'] as String).where((e) => e.isNotEmpty).toList();
      if (userIds.isEmpty) return [];

      final profilesRes = await _client.from('user_profiles').select('id, username, avatar_url').inFilter('id', userIds);
      final profiles = (profilesRes as List).cast<Map<String, dynamic>>();
      final profileMap = {for (final p in profiles) p['id']?.toString() ?? '': p};

      return top.asMap().entries.map((e) {
        final i = e.key;
        final row = e.value;
        final uid = row['userId']?.toString() ?? '';
        final p = profileMap[uid];
        return {
          'rank': i + 1,
          'userId': uid,
          'username': p?['username'] ?? 'Anonymous',
          'avatarUrl': p?['avatar_url'],
          'featureRequests': row['featureRequests'] ?? 0,
          'votes': row['votes'] ?? 0,
          'comments': row['comments'] ?? 0,
          'score': row['score'] ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('getCommunityLeaderboard error: $e');
      return [];
    }
  }

  /// User contribution stats for the current user (sync with Web feedbackService.getUserContributionStats)
  Future<Map<String, dynamic>?> getUserContributionStats(String? userId, {String timeRange = '30d'}) async {
    if (userId == null || userId.isEmpty) return null;
    try {
      final now = DateTime.now();
      DateTime start;
      if (timeRange == '7d') {
        start = now.subtract(const Duration(days: 7));
      } else if (timeRange == '90d') {
        start = now.subtract(const Duration(days: 90));
      } else {
        start = now.subtract(const Duration(days: 30));
      }
      final startIso = start.toUtc().toIso8601String();

      final requestsRes = await _client.from('feature_requests').select('id').eq('user_id', userId).gte('created_at', startIso);
      final votesRes = await _client.from('feature_votes').select('id').eq('user_id', userId).gte('created_at', startIso);
      final commentsRes = await _client.from('feature_comments').select('id').eq('user_id', userId).gte('created_at', startIso);

      final frCount = (requestsRes as List).length;
      final vCount = (votesRes as List).length;
      final cCount = (commentsRes as List).length;

      return {
        'featureRequestsSubmitted': frCount,
        'votesCast': vCount,
        'commentsAdded': cCount,
        'contributionScore': frCount * 3 + vCount * 1 + cCount * 2,
        'timeRange': timeRange,
      };
    } catch (e) {
      debugPrint('getUserContributionStats error: $e');
      return null;
    }
  }

  Future<List<LeaderboardUser>> getVotingParticipationLeaderboard() async {
    if (_votingParticipationCache != null &&
        _votingCacheExpiry != null &&
        DateTime.now().isBefore(_votingCacheExpiry!)) {
      return _votingParticipationCache!;
    }

    try {
      final response = await _client
          .from('feature_votes')
          .select('user_id, user_profiles!inner(username, avatar_url)')
          .limit(500);

      final Map<String, Map<String, dynamic>> userMap = {};
      for (final item in response as List) {
        final userId = item['user_id']?.toString() ?? '';
        if (userId.isEmpty) continue;
        final profile = item['user_profiles'] as Map<String, dynamic>?;
        if (!userMap.containsKey(userId)) {
          userMap[userId] = {
            'user_id': userId,
            'username': profile?['username'] ?? 'Anonymous',
            'avatar_url': profile?['avatar_url'],
            'primary_count': 0,
            'secondary_count': 0,
          };
        }
        userMap[userId]!['primary_count'] =
            (userMap[userId]!['primary_count'] as int) + 1;
      }

      final sorted = userMap.values.toList()
        ..sort(
          (a, b) =>
              (b['primary_count'] as int).compareTo(a['primary_count'] as int),
        );

      final result = sorted
          .take(50)
          .toList()
          .asMap()
          .entries
          .map((e) => LeaderboardUser.fromMap(e.value, e.key + 1))
          .toList();

      _votingParticipationCache = result;
      _votingCacheExpiry = DateTime.now().add(const Duration(minutes: 10));
      return result;
    } catch (e) {
      debugPrint('getVotingParticipationLeaderboard error: $e');
      return _getMockVotingLeaderboard();
    }
  }

  Future<List<LeaderboardUser>> getFeatureAdoptionLeaderboard() async {
    if (_featureAdoptionCache != null &&
        _adoptionCacheExpiry != null &&
        DateTime.now().isBefore(_adoptionCacheExpiry!)) {
      return _featureAdoptionCache!;
    }

    try {
      final thirtyDaysAgo = DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String();
      final response = await _client
          .from('feature_usage_log')
          .select(
            'user_id, feature_id, user_profiles!inner(username, avatar_url)',
          )
          .gte('used_at', thirtyDaysAgo)
          .limit(500);

      final Map<String, Map<String, dynamic>> userMap = {};
      final Map<String, Set<String>> userFeatures = {};
      for (final item in response as List) {
        final userId = item['user_id']?.toString() ?? '';
        final featureId = item['feature_id']?.toString() ?? '';
        if (userId.isEmpty) continue;
        final profile = item['user_profiles'] as Map<String, dynamic>?;
        if (!userMap.containsKey(userId)) {
          userMap[userId] = {
            'user_id': userId,
            'username': profile?['username'] ?? 'Anonymous',
            'avatar_url': profile?['avatar_url'],
            'primary_count': 0,
            'secondary_count': 0,
          };
          userFeatures[userId] = {};
        }
        userFeatures[userId]!.add(featureId);
        userMap[userId]!['primary_count'] = userFeatures[userId]!.length;
      }

      final sorted = userMap.values.toList()
        ..sort(
          (a, b) =>
              (b['primary_count'] as int).compareTo(a['primary_count'] as int),
        );

      final result = sorted
          .take(50)
          .toList()
          .asMap()
          .entries
          .map((e) => LeaderboardUser.fromMap(e.value, e.key + 1))
          .toList();

      _featureAdoptionCache = result;
      _adoptionCacheExpiry = DateTime.now().add(const Duration(minutes: 10));
      return result;
    } catch (e) {
      debugPrint('getFeatureAdoptionLeaderboard error: $e');
      return _getMockAdoptionLeaderboard();
    }
  }

  List<LeaderboardUser> _getMockFeedbackLeaderboard() {
    return List.generate(
      10,
      (i) => LeaderboardUser(
        userId: 'user_$i',
        username: [
          'Alice',
          'Bob',
          'Carol',
          'Dave',
          'Eve',
          'Frank',
          'Grace',
          'Hank',
          'Iris',
          'Jack',
        ][i],
        rank: i + 1,
        primaryCount: 50 - i * 4,
        secondaryCount: 200 - i * 15,
      ),
    );
  }

  List<LeaderboardUser> _getMockVotingLeaderboard() {
    return List.generate(
      10,
      (i) => LeaderboardUser(
        userId: 'user_$i',
        username: [
          'Liam',
          'Mia',
          'Noah',
          'Olivia',
          'Paul',
          'Quinn',
          'Rose',
          'Sam',
          'Tina',
          'Uma',
        ][i],
        rank: i + 1,
        primaryCount: 120 - i * 10,
      ),
    );
  }

  List<LeaderboardUser> _getMockAdoptionLeaderboard() {
    return List.generate(
      10,
      (i) => LeaderboardUser(
        userId: 'user_$i',
        username: [
          'Victor',
          'Wendy',
          'Xena',
          'Yara',
          'Zack',
          'Amy',
          'Ben',
          'Cleo',
          'Dan',
          'Ella',
        ][i],
        rank: i + 1,
        primaryCount: 25 - i * 2,
      ),
    );
  }
}
