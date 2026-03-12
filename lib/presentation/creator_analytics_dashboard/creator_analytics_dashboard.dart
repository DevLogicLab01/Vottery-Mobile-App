import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/creator_monetization_service.dart';
import '../../services/gamification_service.dart';
import '../../services/leaderboard_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/audience_insights_card_widget.dart';
import './widgets/content_performance_card_widget.dart';
import './widgets/creator_progression_widget.dart';
import './widgets/engagement_heatmap_widget.dart';
import './widgets/revenue_analytics_card_widget.dart';
import './widgets/claude_coaching_hub_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/vp_earnings_breakdown_widget.dart';
import './widgets/badge_distribution_widget.dart';
import './widgets/leaderboard_positioning_widget.dart';
import './widgets/streak_performance_widget.dart';

/// Creator Analytics Dashboard providing comprehensive performance insights
/// and revenue tracking for content creators within the creator economy ecosystem.
/// Accessible from Creator Studio with real-time earnings counter and creator tier status.
class CreatorAnalyticsDashboard extends StatefulWidget {
  const CreatorAnalyticsDashboard({super.key});

  @override
  State<CreatorAnalyticsDashboard> createState() =>
      _CreatorAnalyticsDashboardState();
}

class _CreatorAnalyticsDashboardState extends State<CreatorAnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _earnings = {};
  Map<String, dynamic> _revenueBreakdown = {};
  List<Map<String, dynamic>> _contentPerformance = [];
  Map<String, dynamic> _creatorTier = {};
  // New gamification data
  Map<String, dynamic> _vpData = {};
  List<Map<String, dynamic>> _badges = [];
  Map<String, dynamic> _leaderboardData = {};
  Map<String, dynamic> _streakData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
    ); // Changed from 5 to 6
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final monetizationService = CreatorMonetizationService.instance;
      final gamificationService = GamificationService.instance;
      final leaderboardService = LeaderboardService.instance;

      final results = await Future.wait([
        monetizationService.getCreatorEarnings(),
        monetizationService.getRevenueBreakdown(),
        monetizationService.getContentPerformance(),
        monetizationService.getCreatorTier(),
        // New gamification data
        _loadVPBreakdown(),
        gamificationService.getUserAchievements(),
        _loadLeaderboardData(),
        _loadStreakData(),
      ]);

      setState(() {
        _earnings = results[0] as Map<String, dynamic>;
        _revenueBreakdown = results[1] as Map<String, dynamic>;
        _contentPerformance = results[2] as List<Map<String, dynamic>>;
        _creatorTier = results[3] as Map<String, dynamic>;
        _vpData = results[4] as Map<String, dynamic>;
        _badges = results[5] as List<Map<String, dynamic>>;
        _leaderboardData = results[6] as Map<String, dynamic>;
        _streakData = results[7] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load analytics data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _loadVPBreakdown() async {
    // Mock VP breakdown by source
    return {
      'elections_vp': 450,
      'ads_vp': 320,
      'jolts_vp': 180,
      'predictions_vp': 150,
      'social_vp': 100,
      'daily_earnings': [
        {'day': 'Mon', 'vp': 120},
        {'day': 'Tue', 'vp': 150},
        {'day': 'Wed', 'vp': 180},
        {'day': 'Thu', 'vp': 200},
        {'day': 'Fri', 'vp': 170},
        {'day': 'Sat', 'vp': 140},
        {'day': 'Sun', 'vp': 160},
      ],
    };
  }

  Future<Map<String, dynamic>> _loadLeaderboardData() async {
    return {
      'global_rank': 127,
      'global_rank_change': 15,
      'global_percentile': 15.0,
      'regional_rank': 45,
      'regional_rank_change': 5,
      'region': 'North America',
      'friends_rank': 3,
      'friends_rank_change': 1,
      'total_friends': 25,
    };
  }

  Future<Map<String, dynamic>> _loadStreakData() async {
    return {
      'voting_streak': 7,
      'voting_longest': 23,
      'voting_multiplier': 1.5,
      'feed_streak': 5,
      'feed_longest': 15,
      'feed_multiplier': 1.3,
      'ad_streak': 3,
      'ad_longest': 10,
      'ad_multiplier': 1.2,
      'jolts_streak': 4,
      'jolts_longest': 12,
      'jolts_multiplier': 1.4,
    };
  }

  Future<void> _refreshData() async {
    await _loadAnalyticsData();
  }

  Future<void> _exportReport() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: const Text(
          'Creator report will be generated and sent to your email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report generation started'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CreatorAnalyticsDashboard',
      onRetry: _refreshData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Creator Analytics',
          actions: [
            IconButton(icon: Icon(Icons.refresh), onPressed: _refreshData),
            IconButton(
              icon: Icon(Icons.file_download),
              onPressed: _exportReport,
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppTheme.primaryLight,
                    unselectedLabelColor: AppTheme.textSecondaryLight,
                    indicatorColor: AppTheme.primaryLight,
                    tabs: [
                      Tab(text: 'Overview'),
                      Tab(text: 'Revenue'),
                      Tab(text: 'Content'),
                      Tab(text: 'Audience'),
                      Tab(text: 'Gamification'), // New tab
                      Tab(text: 'Coaching'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildRevenueTab(),
                        _buildContentTab(),
                        _buildAudienceTab(),
                        _buildGamificationTab(), // New tab content
                        _buildCoachingTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          SkeletonCard(height: 15.h),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(child: SkeletonCard(height: 12.h)),
              SizedBox(width: 3.w),
              Expanded(child: SkeletonCard(height: 12.h)),
            ],
          ),
          SizedBox(height: 2.h),
          SkeletonCard(height: 25.h),
          SizedBox(height: 2.h),
          SkeletonList(itemCount: 3),
        ],
      ),
    );
  }

  Widget _buildGamificationTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gamification Metrics',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Track your VP earnings, badges, leaderboard position, and streaks',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 3.h),
            VPEarningsBreakdownWidget(vpData: _vpData),
            SizedBox(height: 3.h),
            BadgeDistributionWidget(badges: _badges),
            SizedBox(height: 3.h),
            LeaderboardPositioningWidget(leaderboardData: _leaderboardData),
            SizedBox(height: 3.h),
            StreakPerformanceWidget(streakData: _streakData),
            SizedBox(height: 3.h),
            _buildGamificationSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildGamificationSummary() {
    final totalBadges = _badges.length;
    final vpRankPercentile = _leaderboardData['global_percentile'] ?? 0.0;
    final achievementScore = totalBadges * 100 + (_vpData['elections_vp'] ?? 0);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withAlpha(26),
            AppTheme.secondaryLight.withAlpha(26),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gamification Summary',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard(
                'Total Badges',
                '$totalBadges/25',
                Icons.stars,
                AppTheme.accentLight,
              ),
              _buildSummaryCard(
                'VP Rank',
                'Top ${vpRankPercentile.toStringAsFixed(0)}%',
                Icons.trending_up,
                AppTheme.secondaryLight,
              ),
              _buildSummaryCard(
                'Achievement Score',
                '$achievementScore',
                Icons.emoji_events,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24.sp),
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: AppTheme.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEarningsHeader(ThemeData theme) {
    final totalEarnings = _earnings['total_earnings'] ?? 0.0;
    final thisMonth = _earnings['this_month'] ?? 0.0;
    final tierName = _creatorTier['tier_name'] ?? 'Starter';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Earnings',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '\$${totalEarnings.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.vibrantYellow,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 4.w),
                    SizedBox(width: 1.w),
                    Text(
                      tierName,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'This Month',
                  '\$${thisMonth.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.white,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  'Available',
                  '\$${(_earnings['available_balance'] ?? 0.0).toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 5.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.vibrantYellow,
        labelColor: AppTheme.vibrantYellow,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Revenue'),
          Tab(text: 'Performance'),
          Tab(text: 'Audience'),
          Tab(text: 'Engagement'),
          Tab(text: 'Progression'),
        ],
      ),
    );
  }

  Widget _buildRevenueAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClaudeCoachingHubWidget(
            earnings: _earnings,
            revenueBreakdown: _revenueBreakdown,
            creatorTier: _creatorTier,
          ),
          SizedBox(height: 3.h),
          RevenueAnalyticsCardWidget(
            earnings: _earnings,
            revenueBreakdown: _revenueBreakdown,
          ),
        ],
      ),
    );
  }

  Widget _buildContentPerformanceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentPerformanceCardWidget(contentPerformance: _contentPerformance),
        ],
      ),
    );
  }

  Widget _buildAudienceInsightsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [AudienceInsightsCardWidget()],
      ),
    );
  }

  Widget _buildEngagementHeatmapTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [EngagementHeatmapWidget()],
      ),
    );
  }

  Widget _buildCreatorProgressionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [CreatorProgressionWidget(creatorTier: _creatorTier)],
      ),
    );
  }

  // Add missing tab builder methods
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEarningsHeader(Theme.of(context)),
          SizedBox(height: 3.h),
          RevenueAnalyticsCardWidget(
            earnings: _earnings,
            revenueBreakdown: _revenueBreakdown,
          ),
          SizedBox(height: 3.h),
          ContentPerformanceCardWidget(contentPerformance: _contentPerformance),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    return _buildRevenueAnalyticsTab();
  }

  Widget _buildContentTab() {
    return _buildContentPerformanceTab();
  }

  Widget _buildAudienceTab() {
    return _buildAudienceInsightsTab();
  }

  Widget _buildCoachingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClaudeCoachingHubWidget(
            earnings: _earnings,
            revenueBreakdown: _revenueBreakdown,
            creatorTier: _creatorTier,
          ),
        ],
      ),
    );
  }
}
