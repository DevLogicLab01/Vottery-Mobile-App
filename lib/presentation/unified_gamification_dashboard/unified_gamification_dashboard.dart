import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../services/leaderboard_service.dart';
import '../../services/prediction_service.dart';
import '../../services/supabase_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../routes/app_routes.dart';
import './widgets/vp_earnings_breakdown_widget.dart';
import './widgets/active_prediction_pools_widget.dart';
import './widgets/current_challenges_widget.dart';
import './widgets/achievement_progress_widget.dart';
import './widgets/leaderboard_standings_widget.dart';
import './widgets/real_time_notifications_widget.dart';
import './widgets/quick_action_buttons_widget.dart';
import './widgets/gamification_score_widget.dart';
import './widgets/next_level_progress_widget.dart';

/// Unified Gamification Dashboard
/// Consolidates all gamification metrics into single comprehensive interface
/// providing complete VP economy oversight and engagement tracking
class UnifiedGamificationDashboard extends StatefulWidget {
  const UnifiedGamificationDashboard({super.key});

  @override
  State<UnifiedGamificationDashboard> createState() =>
      _UnifiedGamificationDashboardState();
}

class _UnifiedGamificationDashboardState
    extends State<UnifiedGamificationDashboard>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _client = SupabaseService.instance.client;
  final AuthService _authService = AuthService.instance;
  final VPService _vpService = VPService.instance;
  final GamificationService _gamificationService = GamificationService.instance;
  final PredictionService _predictionService = PredictionService.instance;
  final LeaderboardService _leaderboardService = LeaderboardService.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  StreamSubscription? _vpBalanceSubscription;
  StreamSubscription? _notificationsSubscription;

  bool _isLoading = true;
  int _currentVP = 0;
  int _lifetimeEarned = 0;
  Map<String, dynamic>? _userLevel;
  List<Map<String, dynamic>> _vpEarningsBreakdown = [];
  List<Map<String, dynamic>> _activePredictionPools = [];
  List<Map<String, dynamic>> _currentChallenges = [];
  List<Map<String, dynamic>> _achievements = [];
  Map<String, dynamic>? _leaderboardStandings;
  List<Map<String, dynamic>> _recentNotifications = [];
  int _gamificationScore = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadDashboardData();
    _setupRealTimeSubscriptions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _vpBalanceSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final results = await Future.wait<dynamic>([
        _vpService.getVPBalance(),
        _gamificationService.getUserLevel(),
        _loadVPEarningsBreakdown(userId),
        _predictionService.getActivePools(),
        _loadCurrentChallenges(userId),
        _gamificationService.getUserAchievements(),
        _loadLeaderboardStandings(userId),
        _loadRecentNotifications(userId),
        _calculateGamificationScore(userId),
      ]);

      if (mounted) {
        setState(() {
          final vpBalance = results[0] as Map<String, dynamic>?;
          _currentVP = vpBalance?['available_vp'] as int? ?? 0;
          _lifetimeEarned = vpBalance?['lifetime_earned'] as int? ?? 0;
          _userLevel = results[1] as Map<String, dynamic>?;
          _vpEarningsBreakdown =
              results[2] as List<Map<String, dynamic>>? ?? [];
          _activePredictionPools =
              results[3] as List<Map<String, dynamic>>? ?? [];
          _currentChallenges = results[4] as List<Map<String, dynamic>>? ?? [];
          _achievements = results[5] as List<Map<String, dynamic>>? ?? [];
          _leaderboardStandings = results[6] as Map<String, dynamic>?;
          _recentNotifications =
              results[7] as List<Map<String, dynamic>>? ?? [];
          _gamificationScore = results[8] as int? ?? 0;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Load dashboard data error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadVPEarningsBreakdown(
    String userId,
  ) async {
    final response = await _client
        .from('vp_transactions')
        .select()
        .eq('user_id', userId)
        .eq('transaction_type', 'earn')
        .gte(
          'created_at',
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        )
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _loadCurrentChallenges(
    String userId,
  ) async {
    final response = await _client
        .from('user_feed_quest_progress')
        .select('*, quest:feed_quests(*)')
        .eq('user_id', userId)
        .eq('status', 'in_progress')
        .order('progress_percentage', ascending: false)
        .limit(5);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> _loadLeaderboardStandings(String userId) async {
    final globalRank = await _leaderboardService.getUserRank(
      leaderboardType: 'vp_earned',
      scope: 'global',
      timePeriod: 'all_time',
    );

    final regionalRank = await _leaderboardService.getUserRank(
      leaderboardType: 'vp_earned',
      scope: 'regional',
      timePeriod: 'all_time',
    );

    return {'global': globalRank, 'regional': regionalRank};
  }

  Future<List<Map<String, dynamic>>> _loadRecentNotifications(
    String userId,
  ) async {
    final response = await _client
        .from('gamification_notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(10);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<int> _calculateGamificationScore(String userId) async {
    final vpBalance = await _vpService.getVPBalance();
    final userLevel = await _gamificationService.getUserLevel();
    final streak = await _gamificationService.getUserStreak();
    final achievements = await _gamificationService.getUserAchievements();

    final vpScore = ((vpBalance?['lifetime_earned'] ?? 0) / 100).clamp(0, 30);
    final levelScore = ((userLevel?['current_level'] ?? 1) * 5).clamp(0, 30);
    final streakScore = ((streak?['current_streak'] ?? 0) * 2).clamp(0, 20);
    final achievementScore = (achievements.length * 2).clamp(0, 20);

    return (vpScore + levelScore + streakScore + achievementScore)
        .round()
        .clamp(0, 100);
  }

  void _setupRealTimeSubscriptions() {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    _vpBalanceSubscription = _client
        .from('vp_balance')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          if (mounted && data.isNotEmpty) {
            setState(() {
              _currentVP = data.first['available_vp'] as int;
              _lifetimeEarned = data.first['lifetime_earned'] as int;
            });
          }
        });

    _notificationsSubscription = _client
        .from('gamification_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(10)
        .listen((data) {
          if (mounted) {
            setState(() {
              _recentNotifications = List<Map<String, dynamic>>.from(data);
            });
          }
        });
  }

  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'UnifiedGamificationDashboard',
      onRetry: _loadDashboardData,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Gamification Dashboard',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              onPressed: _refreshDashboard,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _refreshDashboard,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(3.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // VP Balance Header with Animated Counter
                        _buildVPBalanceHeader(theme),
                        SizedBox(height: 2.h),

                        // Next Level Progress Indicator
                        NextLevelProgressWidget(userLevel: _userLevel),
                        SizedBox(height: 2.h),

                        // Overall Gamification Score (0-100)
                        GamificationScoreWidget(score: _gamificationScore),
                        SizedBox(height: 2.h),

                        // Quick-Action Buttons
                        QuickActionButtonsWidget(
                          onRedeemVP: () => _navigateToRewardsShop(),
                          onJoinPool: () => _navigateToActivePools(),
                          onStartQuest: () => _navigateToQuests(),
                          onViewAchievements: () => _navigateToAchievements(),
                        ),
                        SizedBox(height: 3.h),

                        // VP Earnings Breakdown (Daily/Weekly/Monthly Charts)
                        _buildSectionHeader(theme, 'VP Earnings Breakdown'),
                        SizedBox(height: 1.h),
                        VPEarningsBreakdownWidget(
                          earningsData: _vpEarningsBreakdown,
                        ),
                        SizedBox(height: 3.h),

                        // Active Prediction Pools Widget
                        _buildSectionHeader(theme, 'Active Prediction Pools'),
                        SizedBox(height: 1.h),
                        ActivePredictionPoolsWidget(
                          pools: _activePredictionPools,
                          onJoinPool: (poolId) => _joinPredictionPool(poolId),
                        ),
                        SizedBox(height: 3.h),

                        // Current Challenges Widget
                        _buildSectionHeader(theme, 'Current Challenges'),
                        SizedBox(height: 1.h),
                        CurrentChallengesWidget(challenges: _currentChallenges),
                        SizedBox(height: 3.h),

                        // Achievement Progress Tracking
                        _buildSectionHeader(theme, 'Achievement Progress'),
                        SizedBox(height: 1.h),
                        AchievementProgressWidget(achievements: _achievements),
                        SizedBox(height: 3.h),

                        // Leaderboard Standings Widget
                        _buildSectionHeader(theme, 'Leaderboard Standings'),
                        SizedBox(height: 1.h),
                        LeaderboardStandingsWidget(
                          standings: _leaderboardStandings,
                        ),
                        SizedBox(height: 3.h),

                        // Real-time Notifications Stream
                        _buildSectionHeader(theme, 'Recent Activity'),
                        SizedBox(height: 1.h),
                        RealTimeNotificationsWidget(
                          notifications: _recentNotifications,
                        ),
                        SizedBox(height: 2.h),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildVPBalanceHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(77),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current VP Balance',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.white.withAlpha(230),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: _currentVP),
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, value, child) {
                      return Text(
                        '$value VP',
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
              CustomIconWidget(
                iconName: 'stars',
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Divider(color: Colors.white.withAlpha(77)),
          SizedBox(height: 0.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lifetime Earned',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.white.withAlpha(204),
                ),
              ),
              Text(
                '$_lifetimeEarned VP',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Level',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.white.withAlpha(204),
                ),
              ),
              Text(
                _userLevel?['level_title'] ?? 'Novice',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  void _navigateToRewardsShop() {
    Navigator.pushNamed(context, AppRoutes.rewardsShopHub);
  }

  void _navigateToActivePools() {
    Navigator.pushNamed(context, AppRoutes.enhancedVoteCastingWithPredictionIntegration);
  }

  void _navigateToQuests() {
    Navigator.pushNamed(context, AppRoutes.feedQuestDashboard);
  }

  void _navigateToAchievements() {
    Navigator.pushNamed(context, AppRoutes.gamificationHub);
  }

  Future<void> _joinPredictionPool(String poolId) async {
    final pool = _activePredictionPools.firstWhere(
      (item) => item['id'] == poolId,
      orElse: () => <String, dynamic>{},
    );
    final election = pool['election'] as Map<String, dynamic>?;
    final options = (election?['options'] as List?) ?? const [];
    final optionCount = options.isEmpty ? 1 : options.length;
    final defaultWeight = 1.0 / optionCount;
    final defaultOutcome = <String, dynamic>{};

    for (var i = 0; i < optionCount; i++) {
      defaultOutcome['option_$i'] = defaultWeight;
    }

    final success = await _predictionService.enterPredictionPool(
      poolId: poolId,
      predictedOutcome: defaultOutcome,
      confidenceLevel: 0.5,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Prediction pool joined successfully.'
              : 'Unable to join pool. Check VP balance and try again.',
        ),
      ),
    );
    if (success) {
      await _loadDashboardData();
    }
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          ShimmerSkeletonLoader(
            child: Container(
              height: 15.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          ShimmerSkeletonLoader(
            child: Container(
              height: 8.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          ShimmerSkeletonLoader(
            child: Container(
              height: 20.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          ShimmerSkeletonLoader(
            child: Container(
              height: 15.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
