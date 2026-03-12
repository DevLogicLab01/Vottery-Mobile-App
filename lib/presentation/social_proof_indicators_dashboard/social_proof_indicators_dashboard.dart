import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/social_service.dart';
import '../../services/voting_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/friend_avatar_stack_widget.dart';
import './widgets/participation_percentage_widget.dart';
import './widgets/social_influence_score_widget.dart';
import './widgets/trending_elections_widget.dart';
import './widgets/vote_count_badge_widget.dart';

class SocialProofIndicatorsDashboard extends StatefulWidget {
  const SocialProofIndicatorsDashboard({super.key});

  @override
  State<SocialProofIndicatorsDashboard> createState() =>
      _SocialProofIndicatorsDashboardState();
}

class _SocialProofIndicatorsDashboardState
    extends State<SocialProofIndicatorsDashboard> {
  final SocialService _socialService = SocialService.instance;
  final VotingService _votingService = VotingService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _electionsWithSocialProof = [];
  Map<String, dynamic> _socialStats = {};

  @override
  void initState() {
    super.initState();
    _loadSocialProofData();
  }

  Future<void> _loadSocialProofData() async {
    setState(() => _isLoading = true);

    try {
      final elections = await _votingService.getElections(limit: 20);

      final enrichedElections = <Map<String, dynamic>>[];

      final totalFriends = await _getTotalFriends();

      for (final election in elections) {
        final friendsWhoVoted = await _getFriendsWhoVoted(election['id']);
        final participationPercentage = totalFriends > 0
            ? (friendsWhoVoted.length / totalFriends * 100)
            : 0.0;

        enrichedElections.add({
          ...election,
          'friends_who_voted': friendsWhoVoted,
          'participation_percentage': participationPercentage,
          'social_influence_score': _calculateInfluenceScore(
            friendsWhoVoted.length,
            participationPercentage,
          ),
        });
      }

      enrichedElections.sort(
        (a, b) => (b['social_influence_score'] as double).compareTo(
          a['social_influence_score'] as double,
        ),
      );

      setState(() {
        _electionsWithSocialProof = enrichedElections;
        _socialStats = {
          'total_friends': totalFriends,
          'active_friends': _getActiveFriendsCount(enrichedElections),
          'avg_participation': _getAverageParticipation(enrichedElections),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _getFriendsWhoVoted(
    String electionId,
  ) async {
    return [
      {
        'id': '1',
        'name': 'Sarah Johnson',
        'avatar': 'https://i.pravatar.cc/150?img=1',
      },
      {
        'id': '2',
        'name': 'Mike Chen',
        'avatar': 'https://i.pravatar.cc/150?img=2',
      },
      {
        'id': '3',
        'name': 'Emma Davis',
        'avatar': 'https://i.pravatar.cc/150?img=3',
      },
      {
        'id': '4',
        'name': 'Alex Kumar',
        'avatar': 'https://i.pravatar.cc/150?img=4',
      },
      {
        'id': '5',
        'name': 'Lisa Park',
        'avatar': 'https://i.pravatar.cc/150?img=5',
      },
    ];
  }

  Future<int> _getTotalFriends() async {
    return 15;
  }

  double _calculateInfluenceScore(int friendsCount, double percentage) {
    return (friendsCount * 0.6) + (percentage * 0.4);
  }

  int _getActiveFriendsCount(List<Map<String, dynamic>> elections) {
    final uniqueFriends = <String>{};
    for (final election in elections) {
      final friends =
          election['friends_who_voted'] as List<Map<String, dynamic>>;
      for (final friend in friends) {
        uniqueFriends.add(friend['id'] as String);
      }
    }
    return uniqueFriends.length;
  }

  double _getAverageParticipation(List<Map<String, dynamic>> elections) {
    if (elections.isEmpty) return 0.0;
    final total = elections.fold<double>(
      0.0,
      (sum, e) => sum + (e['participation_percentage'] as double),
    );
    return total / elections.length;
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'SocialProofIndicatorsDashboard',
      onRetry: _loadSocialProofData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Social Proof Indicators',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadSocialProofData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildStatsHeader(),
                    SizedBox(height: 2.h),
                    TrendingElectionsWidget(
                      elections: _electionsWithSocialProof.take(5).toList(),
                    ),
                    SizedBox(height: 2.h),
                    _buildElectionsList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Friends',
                  '${_socialStats['total_friends'] ?? 0}',
                  AppTheme.primaryLight,
                  Icons.people,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  'Active Friends',
                  '${_socialStats['active_friends'] ?? 0}',
                  AppTheme.accentLight,
                  Icons.how_to_vote,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildStatCard(
            'Average Participation',
            '${(_socialStats['avg_participation'] ?? 0.0).toStringAsFixed(1)}%',
            AppTheme.secondaryLight,
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 6.w, color: color),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionsList() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elections with Friend Activity',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ..._electionsWithSocialProof.map(
            (election) => _buildElectionCard(election),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionCard(Map<String, dynamic> election) {
    final friendsWhoVoted =
        election['friends_who_voted'] as List<Map<String, dynamic>>;
    final participationPercentage =
        election['participation_percentage'] as double;
    final influenceScore = election['social_influence_score'] as double;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            election['title'] as String? ?? 'Election',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              FriendAvatarStackWidget(friends: friendsWhoVoted, maxVisible: 5),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VoteCountBadgeWidget(count: friendsWhoVoted.length),
                    SizedBox(height: 0.5.h),
                    ParticipationPercentageWidget(
                      percentage: participationPercentage,
                    ),
                  ],
                ),
              ),
              SocialInfluenceScoreWidget(score: influenceScore),
            ],
          ),
        ],
      ),
    );
  }
}
