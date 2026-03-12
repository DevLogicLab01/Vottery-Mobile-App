import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/auth_service.dart';
import '../../services/jolts_service.dart';
import '../../services/leaderboard_service.dart';
import '../../services/vp_service.dart';
import '../../services/blockchain_gamification_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/creator_badge_card_widget.dart';
import './widgets/creator_leaderboard_widget.dart';
import './widgets/revenue_analytics_widget.dart';
import './widgets/tier_progression_widget.dart';

/// Jolts Creator Gamification Hub
/// Comprehensive creator achievement tracking with badge system, leaderboards,
/// and revenue analytics for Jolts video creators
class JoltsCreatorGamificationHub extends StatefulWidget {
  const JoltsCreatorGamificationHub({super.key});

  @override
  State<JoltsCreatorGamificationHub> createState() =>
      _JoltsCreatorGamificationHubState();
}

class _JoltsCreatorGamificationHubState
    extends State<JoltsCreatorGamificationHub>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService.instance;
  final JoltsService _joltsService = JoltsService.instance;
  final LeaderboardService _leaderboardService = LeaderboardService.instance;
  final VPService _vpService = VPService.instance;
  final BlockchainGamificationService _blockchainService =
      BlockchainGamificationService.instance;
  final _client = SupabaseService.instance.client;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _creatorStatus = {};
  List<Map<String, dynamic>> _badges = [];
  List<Map<String, dynamic>> _leaderboard = [];
  Map<String, dynamic> _revenueAnalytics = {};
  String _leaderboardFilter = 'monthly';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCreatorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCreatorData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final results = await Future.wait([
        _loadCreatorStatus(userId),
        _loadCreatorBadges(userId),
        _loadCreatorLeaderboard(),
        _loadRevenueAnalytics(userId),
      ]);

      setState(() {
        _creatorStatus = results[0] as Map<String, dynamic>;
        _badges = results[1] as List<Map<String, dynamic>>;
        _leaderboard = results[2] as List<Map<String, dynamic>>;
        _revenueAnalytics = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load creator data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _loadCreatorStatus(String userId) async {
    try {
      final joltsResponse = await _client
          .from('jolts')
          .select('id, view_count, like_count')
          .eq('creator_id', userId);

      final jolts = List<Map<String, dynamic>>.from(joltsResponse);
      final totalJolts = jolts.length;
      final totalViews = jolts.fold<int>(
        0,
        (sum, jolt) => sum + ((jolt['view_count'] as int?) ?? 0),
      );
      final totalLikes = jolts.fold<int>(
        0,
        (sum, jolt) => sum + ((jolt['like_count'] as int?) ?? 0),
      );

      // Get creator tier
      String tier = 'Bronze Creator';
      if (totalJolts >= 100) {
        tier = 'Platinum Creator';
      } else if (totalJolts >= 50) {
        tier = 'Gold Creator';
      } else if (totalJolts >= 10) {
        tier = 'Silver Creator';
      }

      // Get monthly rank
      final leaderboardData = await _leaderboardService.getUserRank(
        leaderboardType: 'jolts_creator',
        timePeriod: 'monthly',
      );

      return {
        'total_jolts': totalJolts,
        'total_views': totalViews,
        'total_likes': totalLikes,
        'tier': tier,
        'monthly_rank': leaderboardData?['rank_position'] ?? 0,
        'badges_earned': _badges.length,
      };
    } catch (e) {
      debugPrint('Load creator status error: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _loadCreatorBadges(String userId) async {
    try {
      // Get all available creator badges
      final allBadgesResponse = await _client
          .from('jolts_creator_badges')
          .select()
          .order('requirement_threshold', ascending: true);

      final allBadges = List<Map<String, dynamic>>.from(allBadgesResponse);

      // Get user's earned badges
      final earnedBadgesResponse = await _client
          .from('user_jolts_creator_badges')
          .select('badge_id, earned_at')
          .eq('user_id', userId);

      final earnedBadgeIds = earnedBadgesResponse
          .map((e) => e['badge_id'] as String)
          .toSet();

      // Get creator stats for progress calculation
      final joltsResponse = await _client
          .from('jolts')
          .select('id, view_count, like_count, created_at')
          .eq('creator_id', userId);

      final jolts = List<Map<String, dynamic>>.from(joltsResponse);
      final totalJolts = jolts.length;
      final totalViews = jolts.fold<int>(
        0,
        (sum, jolt) => sum + ((jolt['view_count'] as int?) ?? 0),
      );
      final totalLikes = jolts.fold<int>(
        0,
        (sum, jolt) => sum + ((jolt['like_count'] as int?) ?? 0),
      );

      // Calculate 7-day streak
      final now = DateTime.now();
      int streak = 0;
      for (int i = 0; i < 7; i++) {
        final targetDate = now.subtract(Duration(days: i));
        final hasJoltOnDay = jolts.any((jolt) {
          final createdAt = DateTime.parse(jolt['created_at'] as String);
          return createdAt.year == targetDate.year &&
              createdAt.month == targetDate.month &&
              createdAt.day == targetDate.day;
        });
        if (hasJoltOnDay) {
          streak++;
        } else {
          break;
        }
      }

      // Check for viral videos (1000+ views)
      final viralCount = jolts
          .where((j) => ((j['view_count'] as int?) ?? 0) >= 1000)
          .length;

      // Check for rising star (100+ views in first 24 hours)
      final risingStarCount = jolts.where((jolt) {
        final views = (jolt['view_count'] as int?) ?? 0;
        final createdAt = DateTime.parse(jolt['created_at'] as String);
        final hoursSinceCreation = DateTime.now().difference(createdAt).inHours;
        return views >= 100 && hoursSinceCreation <= 24;
      }).length;

      // Map badges with progress
      return allBadges.map((badge) {
        final isEarned = earnedBadgeIds.contains(badge['id']);
        final requirementType = badge['requirement_type'] as String;
        final threshold = badge['requirement_threshold'] as int;

        int currentProgress = 0;
        if (requirementType == 'total_jolts_created') {
          currentProgress = totalJolts;
        } else if (requirementType == 'total_views') {
          currentProgress = totalViews;
        } else if (requirementType == 'total_likes') {
          currentProgress = totalLikes;
        } else if (requirementType == 'consecutive_days') {
          currentProgress = streak;
        } else if (requirementType == 'viral_jolts') {
          currentProgress = viralCount;
        } else if (requirementType == 'rising_star') {
          currentProgress = risingStarCount;
        }

        return {
          ...badge,
          'is_earned': isEarned,
          'current_progress': currentProgress,
          'progress_percentage': ((currentProgress / threshold) * 100)
              .clamp(0, 100)
              .toInt(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Load creator badges error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadCreatorLeaderboard() async {
    try {
      // Get top Jolts creators by views/likes/shares
      final response = await _client
          .rpc(
            'get_jolts_creator_leaderboard',
            params: {'time_period': _leaderboardFilter, 'limit_count': 50},
          )
          .select('*, user:user_profiles!user_id(*)');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback: manual calculation
      try {
        final joltsResponse = await _client
            .from('jolts')
            .select('creator_id, view_count, like_count, share_count');

        final jolts = List<Map<String, dynamic>>.from(joltsResponse);
        final creatorStats = <String, Map<String, int>>{};

        for (var jolt in jolts) {
          final creatorId = jolt['creator_id'] as String;
          if (!creatorStats.containsKey(creatorId)) {
            creatorStats[creatorId] = {'views': 0, 'likes': 0, 'shares': 0};
          }
          creatorStats[creatorId]!['views'] =
              creatorStats[creatorId]!['views']! +
              ((jolt['view_count'] as int?) ?? 0);
          creatorStats[creatorId]!['likes'] =
              creatorStats[creatorId]!['likes']! +
              ((jolt['like_count'] as int?) ?? 0);
          creatorStats[creatorId]!['shares'] =
              creatorStats[creatorId]!['shares']! +
              ((jolt['share_count'] as int?) ?? 0);
        }

        final leaderboardList = creatorStats.entries.map((entry) {
          return {
            'user_id': entry.key,
            'total_views': entry.value['views'],
            'total_likes': entry.value['likes'],
            'total_shares': entry.value['shares'],
          };
        }).toList();

        leaderboardList.sort(
          (a, b) =>
              (b['total_views'] as int).compareTo(a['total_views'] as int),
        );

        return leaderboardList.take(50).toList();
      } catch (e2) {
        debugPrint('Fallback leaderboard error: $e2');
        return [];
      }
    }
  }

  Future<Map<String, dynamic>> _loadRevenueAnalytics(String userId) async {
    try {
      // Get VP earnings from Jolts
      final vpEarningsResponse = await _client
          .from('jolts_vp_earnings')
          .select('vp_amount, earning_type')
          .eq('user_id', userId);

      final earnings = List<Map<String, dynamic>>.from(vpEarningsResponse);
      final totalVP = earnings.fold<int>(
        0,
        (sum, e) => sum + ((e['vp_amount'] as int?) ?? 0),
      );

      // Get Jolts performance metrics
      final joltsResponse = await _client
          .from('jolts')
          .select('view_count, like_count, share_count')
          .eq('creator_id', userId);

      final jolts = List<Map<String, dynamic>>.from(joltsResponse);
      final avgViews = jolts.isEmpty
          ? 0
          : jolts.fold<int>(
                  0,
                  (sum, j) => sum + ((j['view_count'] as int?) ?? 0),
                ) ~/
                jolts.length;
      final avgLikes = jolts.isEmpty
          ? 0
          : jolts.fold<int>(
                  0,
                  (sum, j) => sum + ((j['like_count'] as int?) ?? 0),
                ) ~/
                jolts.length;

      final engagementRate = avgViews > 0 ? (avgLikes / avgViews * 100) : 0.0;
      final viralScore = jolts
          .where((j) => ((j['view_count'] as int?) ?? 0) >= 1000)
          .length;

      return {
        'total_vp_earned': totalVP,
        'vp_conversion_rate': 1.0, // 1 VP = $0.01 (example)
        'average_views': avgViews,
        'average_likes': avgLikes,
        'engagement_rate': engagementRate,
        'viral_score': viralScore,
      };
    } catch (e) {
      debugPrint('Load revenue analytics error: $e');
      return {};
    }
  }

  Future<void> _shareBadge(Map<String, dynamic> badge) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      // Generate blockchain verification URL
      final blockchainLog = await _blockchainService.logBadgeAward(
        badgeId: badge['id'] as String,
        badgeName: badge['badge_name'] as String,
        vpReward: badge['vp_reward'] as int,
      );

      final verificationUrl =
          'https://vottery2205.builtwithrocket.new/verify-badge?hash=${blockchainLog['transaction_hash']}';

      await Share.share(
        '🏆 I just earned the "${badge['badge_name']}" badge on Vottery!\n\n'
        '${badge['badge_description']}\n\n'
        'Verify on blockchain: $verificationUrl\n\n'
        '#VotteryCreator #JoltsCreator',
        subject: 'Check out my Vottery achievement!',
      );
    } catch (e) {
      debugPrint('Share badge error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share badge: $e')));
      }
    }
  }

  void _showBadgeQRCode(Map<String, dynamic> badge) {
    final verificationUrl =
        'https://vottery2205.builtwithrocket.new/verify-badge?badge_id=${badge['id']}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(badge['badge_name'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: verificationUrl,
              version: QrVersions.auto,
              size: 200.0,
            ),
            SizedBox(height: 2.h),
            Text(
              'Scan to verify on blockchain',
              style: TextStyle(fontSize: 11.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _shareBadge(badge);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'JoltsCreatorGamificationHub',
      onRetry: _loadCreatorData,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Jolts Creator Hub',
          variant: CustomAppBarVariant.withBack,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCreatorData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _loadCreatorData,
                child: Column(
                  children: [
                    _buildCreatorStatusHeader(theme),
                    SizedBox(height: 2.h),
                    _buildTabBar(theme),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildBadgesTab(),
                          _buildLeaderboardTab(),
                          _buildRevenueTab(),
                          _buildTierProgressionTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCreatorStatusHeader(ThemeData theme) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          Text(
            _creatorStatus['tier'] ?? 'Bronze Creator',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'Badges',
                '${_creatorStatus['badges_earned'] ?? 0}',
              ),
              _buildStatColumn(
                'Rank',
                '#${_creatorStatus['monthly_rank'] ?? 0}',
              ),
              _buildStatColumn(
                'Jolts',
                '${_creatorStatus['total_jolts'] ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10.0),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Badges'),
          Tab(text: 'Leaderboard'),
          Tab(text: 'Revenue'),
          Tab(text: 'Tier'),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Creator Badge Gallery',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        ..._badges.map(
          (badge) => CreatorBadgeCardWidget(
            badge: badge,
            onShare: () => _shareBadge(badge),
            onShowQR: () => _showBadgeQRCode(badge),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFilterChip('Monthly', 'monthly'),
              _buildFilterChip('All Time', 'all_time'),
            ],
          ),
        ),
        Expanded(
          child: CreatorLeaderboardWidget(
            leaderboard: _leaderboard,
            currentUserId: _authService.currentUser?.id ?? '',
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _leaderboardFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _leaderboardFilter = value;
          });
          _loadCreatorData();
        }
      },
    );
  }

  Widget _buildRevenueTab() {
    return RevenueAnalyticsWidget(analytics: _revenueAnalytics);
  }

  Widget _buildTierProgressionTab() {
    return TierProgressionWidget(
      currentTier: _creatorStatus['tier'] ?? 'Bronze Creator',
      totalJolts: _creatorStatus['total_jolts'] ?? 0,
    );
  }
}
