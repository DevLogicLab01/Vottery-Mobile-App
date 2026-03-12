import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/supabase_service.dart';

class CommunityEngagementLeaderboardsTab extends StatefulWidget {
  const CommunityEngagementLeaderboardsTab({super.key});

  @override
  State<CommunityEngagementLeaderboardsTab> createState() =>
      _CommunityEngagementLeaderboardsTabState();
}

class _CommunityEngagementLeaderboardsTabState
    extends State<CommunityEngagementLeaderboardsTab>
    with SingleTickerProviderStateMixin {
  late TabController _innerTabController;
  final _client = SupabaseService.instance.client;

  List<Map<String, dynamic>> _feedbackLeaderboard = [];
  List<Map<String, dynamic>> _votingLeaderboard = [];
  List<Map<String, dynamic>> _adoptionLeaderboard = [];
  bool _isLoadingFeedback = true;
  bool _isLoadingVoting = true;
  bool _isLoadingAdoption = true;

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 3, vsync: this);
    _loadAllLeaderboards();
  }

  @override
  void dispose() {
    _innerTabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllLeaderboards() async {
    await Future.wait([
      _loadFeedbackContributions(),
      _loadVotingParticipation(),
      _loadFeatureAdoption(),
    ]);
  }

  Future<void> _loadFeedbackContributions() async {
    try {
      final response = await _client
          .from('feature_requests')
          .select('user_id, user_profiles(username, avatar_url)')
          .order('created_at', ascending: false)
          .limit(50);

      // Aggregate by user
      final Map<String, Map<String, dynamic>> aggregated = {};
      for (final row in response as List) {
        final userId = row['user_id'] as String? ?? '';
        if (userId.isEmpty) continue;
        final profile = row['user_profiles'] as Map?;
        if (!aggregated.containsKey(userId)) {
          aggregated[userId] = {
            'user_id': userId,
            'username': profile?['username'] ?? 'Anonymous',
            'avatar_url': profile?['avatar_url'],
            'submissions_count': 0,
          };
        }
        aggregated[userId]!['submissions_count'] =
            (aggregated[userId]!['submissions_count'] as int) + 1;
      }

      final sorted = aggregated.values.toList()
        ..sort(
          (a, b) => (b['submissions_count'] as int).compareTo(
            a['submissions_count'] as int,
          ),
        );

      if (mounted) {
        setState(() {
          _feedbackLeaderboard = sorted.take(50).toList();
          _isLoadingFeedback = false;
        });
      }
    } catch (e) {
      debugPrint('Feedback leaderboard error: $e');
      if (mounted) setState(() => _isLoadingFeedback = false);
    }
  }

  Future<void> _loadVotingParticipation() async {
    try {
      final response = await _client
          .from('feature_request_votes')
          .select(
            'voter_id, user_profiles!feature_request_votes_voter_id_fkey(username, avatar_url)',
          )
          .limit(200);

      final Map<String, Map<String, dynamic>> aggregated = {};
      for (final row in response as List) {
        final voterId = row['voter_id'] as String? ?? '';
        if (voterId.isEmpty) continue;
        final profile = row['user_profiles'] as Map?;
        if (!aggregated.containsKey(voterId)) {
          aggregated[voterId] = {
            'user_id': voterId,
            'username': profile?['username'] ?? 'Anonymous',
            'avatar_url': profile?['avatar_url'],
            'votes_cast': 0,
          };
        }
        aggregated[voterId]!['votes_cast'] =
            (aggregated[voterId]!['votes_cast'] as int) + 1;
      }

      final sorted = aggregated.values.toList()
        ..sort(
          (a, b) => (b['votes_cast'] as int).compareTo(a['votes_cast'] as int),
        );

      if (mounted) {
        setState(() {
          _votingLeaderboard = sorted.take(50).toList();
          _isLoadingVoting = false;
        });
      }
    } catch (e) {
      debugPrint('Voting leaderboard error: $e');
      if (mounted) setState(() => _isLoadingVoting = false);
    }
  }

  Future<void> _loadFeatureAdoption() async {
    try {
      final response = await _client
          .from('feature_usage_log')
          .select('user_id, feature_id, user_profiles(username, avatar_url)')
          .gte(
            'used_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          )
          .limit(500);

      final Map<String, Map<String, dynamic>> aggregated = {};
      for (final row in response as List) {
        final userId = row['user_id'] as String? ?? '';
        if (userId.isEmpty) continue;
        final profile = row['user_profiles'] as Map?;
        if (!aggregated.containsKey(userId)) {
          aggregated[userId] = {
            'user_id': userId,
            'username': profile?['username'] ?? 'Anonymous',
            'avatar_url': profile?['avatar_url'],
            'features_used': <String>{},
          };
        }
        final featureId = row['feature_id'] as String? ?? '';
        (aggregated[userId]!['features_used'] as Set<String>).add(featureId);
      }

      final sorted =
          aggregated.values
              .map(
                (e) => {
                  ...e,
                  'features_count': (e['features_used'] as Set<String>).length,
                },
              )
              .toList()
            ..sort(
              (a, b) => (b['features_count'] as int).compareTo(
                a['features_count'] as int,
              ),
            );

      if (mounted) {
        setState(() {
          _adoptionLeaderboard = sorted.take(50).toList();
          _isLoadingAdoption = false;
        });
      }
    } catch (e) {
      debugPrint('Adoption leaderboard error: $e');
      if (mounted) setState(() => _isLoadingAdoption = false);
    }
  }

  Widget _buildLeaderboardList({
    required List<Map<String, dynamic>> items,
    required bool isLoading,
    required String countKey,
    required String countLabel,
    required String badgeLabel,
    required int badgeThreshold,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No data available yet',
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAllLeaderboards,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final user = items[index];
          final rank = index + 1;
          final count = user[countKey] as int? ?? 0;
          final username = user['username'] as String? ?? 'Anonymous';
          final avatarUrl = user['avatar_url'] as String?;

          Color rankColor = Colors.grey;
          IconData? rankIcon;
          if (rank == 1) {
            rankColor = const Color(0xFFFFD700);
            rankIcon = Icons.workspace_premium;
          } else if (rank == 2) {
            rankColor = const Color(0xFFC0C0C0);
            rankIcon = Icons.workspace_premium;
          } else if (rank == 3) {
            rankColor = const Color(0xFFCD7F32);
            rankIcon = Icons.workspace_premium;
          }

          return Card(
            margin: EdgeInsets.only(bottom: 1.h),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(fontSize: 14),
                          )
                        : null,
                  ),
                  if (rank <= 3)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Tooltip(
                        message: rank == 1
                            ? 'Top Contributor'
                            : rank == 2
                            ? 'Silver'
                            : 'Bronze',
                        child: Icon(rankIcon, size: 14, color: rankColor),
                      ),
                    ),
                ],
              ),
              title: Row(
                children: [
                  Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      username,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (rank <= badgeThreshold)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                '$count $countLabel',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: TabBar(
            controller: _innerTabController,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(10.0),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Feedback'),
              Tab(text: 'Voting'),
              Tab(text: 'Adoption'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _innerTabController,
            children: [
              _buildLeaderboardList(
                items: _feedbackLeaderboard,
                isLoading: _isLoadingFeedback,
                countKey: 'submissions_count',
                countLabel: 'requests',
                badgeLabel: 'Top Contributor',
                badgeThreshold: 3,
              ),
              _buildLeaderboardList(
                items: _votingLeaderboard,
                isLoading: _isLoadingVoting,
                countKey: 'votes_cast',
                countLabel: 'votes',
                badgeLabel: 'Most Votes',
                badgeThreshold: 10,
              ),
              _buildLeaderboardList(
                items: _adoptionLeaderboard,
                isLoading: _isLoadingAdoption,
                countKey: 'features_count',
                countLabel: 'features used',
                badgeLabel: 'Feature Champion',
                badgeThreshold: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
