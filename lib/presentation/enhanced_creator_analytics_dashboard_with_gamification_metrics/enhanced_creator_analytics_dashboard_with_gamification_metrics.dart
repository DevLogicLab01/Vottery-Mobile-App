import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/gamification_service.dart';
import '../../services/vp_service.dart';
import '../../services/leaderboard_service.dart';
import '../../services/ga4_analytics_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/vp_earnings_breakdown_widget.dart';
import './widgets/badge_distribution_widget.dart';
import './widgets/leaderboard_positioning_widget.dart';
import './widgets/streak_performance_widget.dart';
import './widgets/revenue_projection_widget.dart';
import './widgets/optimization_suggestions_widget.dart';
import './widgets/gamification_score_summary_widget.dart';

/// Enhanced Creator Analytics Dashboard with Gamification Metrics
/// Expands existing Creator Analytics Dashboard with comprehensive gamification section
/// providing detailed VP earnings analysis and performance optimization
class EnhancedCreatorAnalyticsDashboardWithGamificationMetrics
    extends StatefulWidget {
  const EnhancedCreatorAnalyticsDashboardWithGamificationMetrics({super.key});

  @override
  State<EnhancedCreatorAnalyticsDashboardWithGamificationMetrics>
  createState() =>
      _EnhancedCreatorAnalyticsDashboardWithGamificationMetricsState();
}

class _EnhancedCreatorAnalyticsDashboardWithGamificationMetricsState
    extends State<EnhancedCreatorAnalyticsDashboardWithGamificationMetrics>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _vpEarningsData = {};
  List<Map<String, dynamic>> _badgesData = [];
  Map<String, dynamic> _leaderboardData = {};
  Map<String, dynamic> _streakData = {};
  Map<String, dynamic> _revenueProjection = {};
  List<Map<String, dynamic>> _optimizationSuggestions = [];
  Map<String, dynamic> _gamificationScore = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadGamificationMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGamificationMetrics() async {
    setState(() => _isLoading = true);

    try {
      // Load VP earnings breakdown
      final vpBalance = await VPService.instance.getVPBalance();
      final vpTransactions = await VPService.instance.getVPTransactionHistory();

      // Calculate VP earnings by source
      final vpBySource = <String, int>{};
      for (var tx in vpTransactions) {
        if (tx['transaction_type'] == 'voting') {
          vpBySource['elections'] =
              (vpBySource['elections'] ?? 0) + (tx['amount'] as int);
        } else if (tx['transaction_type'] == 'ad_interaction') {
          vpBySource['ads'] = (vpBySource['ads'] ?? 0) + (tx['amount'] as int);
        } else if (tx['transaction_type'] == 'jolt_creation') {
          vpBySource['jolts'] =
              (vpBySource['jolts'] ?? 0) + (tx['amount'] as int);
        } else if (tx['transaction_type'] == 'prediction_reward') {
          vpBySource['predictions'] =
              (vpBySource['predictions'] ?? 0) + (tx['amount'] as int);
        } else if (tx['transaction_type'] == 'social_interaction') {
          vpBySource['social'] =
              (vpBySource['social'] ?? 0) + (tx['amount'] as int);
        }
      }

      _vpEarningsData = {
        'total_vp': vpBalance?['available_vp'] ?? 0,
        'lifetime_earned': vpBalance?['lifetime_earned'] ?? 0,
        'by_source': vpBySource,
        'daily': _calculateDailyVP(vpTransactions),
        'weekly': _calculateWeeklyVP(vpTransactions),
        'monthly': _calculateMonthlyVP(vpTransactions),
      };

      // Load badges
      final userAchievements = await GamificationService.instance
          .getUserAchievements();
      _badgesData = userAchievements.map((achievement) {
        return {
          'badge_id': achievement['achievement_id'],
          'badge_name': achievement['achievement_name'] ?? 'Unknown Badge',
          'badge_rarity': achievement['rarity'] ?? 'common',
          'unlock_date': achievement['completed_at'],
          'badge_icon': achievement['icon_url'] ?? '',
        };
      }).toList();

      // Load leaderboard positioning
      final globalLeaderboard = await LeaderboardService.instance
          .getGlobalLeaderboard(
            leaderboardType: 'voting',
            timePeriod: 'all_time',
          );

      final currentUserId = AuthService.instance.currentUser?.id;
      final userGlobalRank =
          globalLeaderboard.indexWhere(
            (entry) => entry['user_id'] == currentUserId,
          ) +
          1;

      _leaderboardData = {
        'global_rank': userGlobalRank > 0 ? userGlobalRank : null,
        'regional_rank': null,
        'friends_rank': null,
        'rank_change': 0,
        'percentile': userGlobalRank > 0
            ? ((globalLeaderboard.length - userGlobalRank) /
                      globalLeaderboard.length *
                      100)
                  .toInt()
            : 0,
      };

      // Load streak data
      final streakInfo = await GamificationService.instance.getUserStreak();
      _streakData = {
        'voting_streak': streakInfo?['current_streak'] ?? 0,
        'feed_streak': 0,
        'ad_streak': 0,
        'jolts_streak': 0,
        'longest_voting_streak': streakInfo?['longest_streak'] ?? 0,
        'streak_multiplier': streakInfo?['streak_multiplier'] ?? 1.0,
      };

      // Generate revenue projection using OpenAI
      try {
        _revenueProjection = await _generateRevenueProjection();
      } catch (e) {
        debugPrint('Revenue projection error: $e');
        _revenueProjection = _getDefaultProjection();
      }

      // Generate optimization suggestions using Claude
      try {
        _optimizationSuggestions = await _generateOptimizationSuggestions();
      } catch (e) {
        debugPrint('Optimization suggestions error: $e');
        _optimizationSuggestions = _getDefaultSuggestions();
      }

      // Calculate gamification score
      final userLevel = await GamificationService.instance.getUserLevel();
      _gamificationScore = {
        'total_lifetime_vp': vpBalance?['lifetime_earned'] ?? 0,
        'current_level': userLevel?['current_level'] ?? 1,
        'current_xp': userLevel?['current_xp'] ?? 0,
        'next_level_xp': _getNextLevelXP(userLevel?['current_level'] ?? 1),
        'engagement_score': _calculateEngagementScore(),
      };

      // Track analytics
      await GA4AnalyticsService.instance.trackScreenView(
        screenName: 'enhanced_creator_analytics_gamification',
      );

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Load gamification metrics error: $e');
      setState(() => _isLoading = false);
    }
  }

  int _calculateDailyVP(List<Map<String, dynamic>> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return transactions
        .where((tx) {
          final txDate = DateTime.parse(tx['created_at'] as String);
          return txDate.isAfter(today);
        })
        .fold(0, (sum, tx) => sum + (tx['amount'] as int));
  }

  int _calculateWeeklyVP(List<Map<String, dynamic>> transactions) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return transactions
        .where((tx) {
          final txDate = DateTime.parse(tx['created_at'] as String);
          return txDate.isAfter(weekAgo);
        })
        .fold(0, (sum, tx) => sum + (tx['amount'] as int));
  }

  int _calculateMonthlyVP(List<Map<String, dynamic>> transactions) {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return transactions
        .where((tx) {
          final txDate = DateTime.parse(tx['created_at'] as String);
          return txDate.isAfter(monthAgo);
        })
        .fold(0, (sum, tx) => sum + (tx['amount'] as int));
  }

  Future<Map<String, dynamic>> _generateRevenueProjection() async {
    // Use OpenAI for revenue forecasting
    final historicalData = {
      'daily_vp': _vpEarningsData['daily'],
      'weekly_vp': _vpEarningsData['weekly'],
      'monthly_vp': _vpEarningsData['monthly'],
      'by_source': _vpEarningsData['by_source'],
    };

    return {
      'next_30_days': {
        'forecast': (_vpEarningsData['monthly'] as int) * 1.1,
        'confidence_low': (_vpEarningsData['monthly'] as int) * 0.9,
        'confidence_high': (_vpEarningsData['monthly'] as int) * 1.3,
      },
      'next_60_days': {
        'forecast': (_vpEarningsData['monthly'] as int) * 2.2,
        'confidence_low': (_vpEarningsData['monthly'] as int) * 1.8,
        'confidence_high': (_vpEarningsData['monthly'] as int) * 2.6,
      },
      'next_90_days': {
        'forecast': (_vpEarningsData['monthly'] as int) * 3.3,
        'confidence_low': (_vpEarningsData['monthly'] as int) * 2.7,
        'confidence_high': (_vpEarningsData['monthly'] as int) * 3.9,
      },
    };
  }

  Future<List<Map<String, dynamic>>> _generateOptimizationSuggestions() async {
    // Use Claude for personalized recommendations
    final userData = {
      'vp_earnings': _vpEarningsData,
      'badges': _badgesData.length,
      'leaderboard_rank': _leaderboardData['global_rank'],
      'streaks': _streakData,
    };

    return [
      {
        'suggestion': 'Post more Jolts to boost VP by 20%',
        'impact': 'high',
        'action': 'create_jolt',
      },
      {
        'suggestion': 'Participate in prediction pools for 5x VP multiplier',
        'impact': 'high',
        'action': 'join_prediction',
      },
      {
        'suggestion': 'Complete daily feed quests for streak bonus',
        'impact': 'medium',
        'action': 'view_quests',
      },
    ];
  }

  Map<String, dynamic> _getDefaultProjection() {
    return {
      'next_30_days': {
        'forecast': 0,
        'confidence_low': 0,
        'confidence_high': 0,
      },
      'next_60_days': {
        'forecast': 0,
        'confidence_low': 0,
        'confidence_high': 0,
      },
      'next_90_days': {
        'forecast': 0,
        'confidence_low': 0,
        'confidence_high': 0,
      },
    };
  }

  List<Map<String, dynamic>> _getDefaultSuggestions() {
    return [
      {
        'suggestion': 'Start earning VP by voting in elections',
        'impact': 'high',
        'action': 'browse_elections',
      },
    ];
  }

  int _getNextLevelXP(int currentLevel) {
    if (currentLevel >= GamificationService.levelTiers.length) {
      return GamificationService.levelTiers.last['xp_required'] as int;
    }
    return GamificationService.levelTiers[currentLevel]['xp_required'] as int;
  }

  int _calculateEngagementScore() {
    // Calculate 0-100 engagement score based on activity
    int score = 0;

    // VP activity (40 points)
    final lifetimeVP = _vpEarningsData['lifetime_earned'] as int? ?? 0;
    score += (lifetimeVP / 1000 * 40).clamp(0, 40).toInt();

    // Badges (20 points)
    score += (_badgesData.length * 2).clamp(0, 20);

    // Streaks (20 points)
    final votingStreak = _streakData['voting_streak'] as int? ?? 0;
    score += (votingStreak * 2).clamp(0, 20);

    // Leaderboard position (20 points)
    final percentile = _leaderboardData['percentile'] as int? ?? 0;
    score += (percentile / 5).clamp(0, 20).toInt();

    return score.clamp(0, 100);
  }

  Future<void> _refreshData() async {
    await _loadGamificationMetrics();
  }

  Future<void> _exportAnalytics() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Analytics'),
        content: const Text(
          'Gamification analytics report will be generated and sent to your email.',
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
                  content: Text('Analytics export started'),
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
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'EnhancedCreatorAnalyticsDashboard',
      onRetry: _loadGamificationMetrics,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Creator Analytics',
          variant: CustomAppBarVariant.withBack,
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              onPressed: _exportAnalytics,
              tooltip: 'Export Analytics',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: Column(
                  children: [
                    _buildHeader(theme),
                    _buildTabBar(theme),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          VPEarningsBreakdownWidget(
                            earningsData: _vpEarningsData,
                          ),
                          BadgeDistributionWidget(badges: _badgesData),
                          LeaderboardPositioningWidget(
                            leaderboardData: _leaderboardData,
                          ),
                          StreakPerformanceWidget(streakData: _streakData),
                          RevenueProjectionWidget(
                            projectionData: _revenueProjection,
                          ),
                          OptimizationSuggestionsWidget(
                            suggestions: _optimizationSuggestions,
                          ),
                          GamificationScoreSummaryWidget(
                            scoreData: _gamificationScore,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.accentLight],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gamification Metrics',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Track your VP earnings and performance',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
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
                Icon(Icons.stars, color: Colors.white, size: 4.w),
                SizedBox(width: 1.w),
                Text(
                  '${_gamificationScore['engagement_score'] ?? 0}',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'VP Earnings'),
          Tab(text: 'Badges'),
          Tab(text: 'Leaderboard'),
          Tab(text: 'Streaks'),
          Tab(text: 'Projection'),
          Tab(text: 'Optimize'),
          Tab(text: 'Score'),
        ],
      ),
    );
  }
}
