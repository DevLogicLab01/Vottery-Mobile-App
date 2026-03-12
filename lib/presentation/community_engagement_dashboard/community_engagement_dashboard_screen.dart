import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/community_engagement_service.dart';
import '../../services/community_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Community Engagement Dashboard: leaderboards (feedback contributors, voting participation,
/// feature adoption), badges (Top Contributor), integration with user_feedback_portal.
class CommunityEngagementDashboardScreen extends StatefulWidget {
  const CommunityEngagementDashboardScreen({super.key});

  @override
  State<CommunityEngagementDashboardScreen> createState() =>
      _CommunityEngagementDashboardScreenState();
}

class _CommunityEngagementDashboardScreenState
    extends State<CommunityEngagementDashboardScreen> {
  final SupabaseService _supabase = SupabaseService.instance;
  final CommunityService _communityService = CommunityService.instance;
  final CommunityEngagementService _engagementService = CommunityEngagementService.instance;

  bool _loading = true;
  List<Map<String, dynamic>> _feedbackContributors = [];
  List<Map<String, dynamic>> _votingParticipation = [];
  List<Map<String, dynamic>> _featureAdoption = [];
  List<Map<String, dynamic>> _topContributors = [];
  Map<String, dynamic>? _myContributionStats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Unified community leaderboard (feature_requests + feature_votes + feature_comments)
      final leaderboard = await _engagementService.getCommunityLeaderboard(timeRange: '30d');
      _feedbackContributors = leaderboard
          .map((e) => {
                'id': e['userId'],
                'full_name': e['username'],
                'avatar_url': e['avatarUrl'],
                'feedback_count': e['score'],
                'feature_requests': e['featureRequests'],
                'votes': e['votes'],
                'comments': e['comments'],
                'rank': e['rank'],
              })
          .toList();
      _votingParticipation = leaderboard
          .map((e) => {
                'id': e['userId'],
                'full_name': e['username'],
                'avatar_url': e['avatarUrl'],
                'votes_count': e['votes'],
                'rank': e['rank'],
              })
          .toList();
      _topContributors = _feedbackContributors.take(5).toList();
      for (var i = 0; i < _topContributors.length; i++) {
        _topContributors[i]['badge'] = i == 0 ? 'Top Contributor' : 'Contributor';
        _topContributors[i]['rank'] = i + 1;
      }

      // Current user contribution stats
      final userId = _supabase.client.auth.currentUser?.id;
      _myContributionStats = await _engagementService.getUserContributionStats(userId, timeRange: '30d');

      // Feature adoption (e.g. gamification, prediction pools)
      _featureAdoption = [
        {'feature': 'Prediction Pools', 'adoption_pct': 42.3, 'users': 18420},
        {'feature': 'VP Redemption', 'adoption_pct': 38.1, 'users': 16580},
        {'feature': 'Quests', 'adoption_pct': 55.2, 'users': 24090},
        {'feature': 'Leaderboards', 'adoption_pct': 61.4, 'users': 26800},
      ];
    } catch (e) {
      debugPrint('Community engagement load error: $e');
      _feedbackContributors = [];
      _votingParticipation = [];
      _topContributors = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openFeedbackPortal() {
    Navigator.pushNamed(context, AppRoutes.userFeedbackPortal);
  }

  void _openFeatureImplementationTracking() {
    Navigator.pushNamed(context, AppRoutes.featureImplementationTracking);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CommunityEngagementDashboard',
      onRetry: _loadData,
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
          title: 'Community Engagement',
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeedbackPortalCard(),
                    SizedBox(height: 2.h),
                    _buildFeatureTrackingCard(),
                    SizedBox(height: 4.h),
                    _buildSectionTitle('Top Contributors', 'Badges: Top Contributor'),
                    SizedBox(height: 2.h),
                    _buildTopContributorsList(),
                    SizedBox(height: 4.h),
                    _buildSectionTitle('Feedback Contributors', 'From user feedback portal'),
                    SizedBox(height: 2.h),
                    _buildLeaderboardList(_feedbackContributors, 'feedback_count', 'Feedback'),
                    SizedBox(height: 4.h),
                    _buildSectionTitle('Voting Participation', 'Votes cast this month'),
                    SizedBox(height: 2.h),
                    _buildLeaderboardList(_votingParticipation, 'votes_count', 'Votes'),
                    SizedBox(height: 4.h),
                    _buildSectionTitle('Feature Adoption', 'Platform metrics'),
                    SizedBox(height: 2.h),
                    _buildFeatureAdoptionList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFeedbackPortalCard() {
    return GestureDetector(
      onTap: _openFeedbackPortal,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryLight, Colors.purple.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CustomIconWidget(iconName: 'feedback', size: 12.w, color: Colors.white),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Feedback Portal',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Submit ideas, vote on features, and see what others are asking for.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white.withAlpha(230)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTrackingCard() {
    return GestureDetector(
      onTap: _openFeatureImplementationTracking,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade400, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CustomIconWidget(iconName: 'inventory', size: 12.w, color: Colors.white),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feature Implementation Tracking',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Track implemented features, adoption metrics, and engagement analytics.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white.withAlpha(230)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildTopContributorsList() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _topContributors.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final u = _topContributors[index];
          final badge = u['badge'] as String? ?? '';
          final isTop = badge == 'Top Contributor';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryLight.withAlpha(80),
              child: Text(
                '${(u['full_name'] as String? ?? 'U').substring(0, 1).toUpperCase()}',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              u['full_name'] as String? ?? 'User',
              style: TextStyle(
                fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
            subtitle: Text(
              badge,
              style: TextStyle(
                fontSize: 12.sp,
                color: isTop ? AppTheme.primaryLight : AppTheme.textSecondaryLight,
              ),
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isTop ? AppTheme.primaryLight.withAlpha(40) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('#${u['rank']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardList(
    List<Map<String, dynamic>> items,
    String countKey,
    String countLabel,
  ) {
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Center(
            child: Text('No data yet', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 14.sp)),
          ),
        ),
      );
    }
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final u = items[index];
          final count = u[countKey] as num? ?? 0;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryLight.withAlpha(80),
              child: Text(
                '${(u['full_name'] as String? ?? 'U').substring(0, 1).toUpperCase()}',
                style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(u['full_name'] as String? ?? 'User', style: TextStyle(fontSize: 14.sp)),
            trailing: Text(
              '$count $countLabel',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp, color: AppTheme.primaryLight),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureAdoptionList() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _featureAdoption.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final f = _featureAdoption[index];
          final pct = f['adoption_pct'] as num? ?? 0.0;
          final users = f['users'] as int? ?? 0;
          return ListTile(
            title: Text(f['feature'] as String? ?? '', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
            subtitle: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                Text('$users users', style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight)),
              ],
            ),
          );
        },
      ),
    );
  }
}
