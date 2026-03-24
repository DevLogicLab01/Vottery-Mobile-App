import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/gamification_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/level_progression_widget.dart';
import './widgets/achievement_grid_widget.dart';
import './widgets/streak_counter_widget.dart';

/// Gamification Hub - Showcases user progression through level system,
/// achievement tracking, and streak rewards
class GamificationHub extends StatefulWidget {
  const GamificationHub({super.key});

  @override
  State<GamificationHub> createState() => _GamificationHubState();
}

class _GamificationHubState extends State<GamificationHub>
    with SingleTickerProviderStateMixin {
  static const List<int> _levelProgressMilestones = [
    1,
    5,
    15,
    30,
    45,
    60,
    75,
    90,
    100,
  ];

  final GamificationService _gamificationService = GamificationService.instance;

  late TabController _tabController;
  Map<String, dynamic> _userLevel = {};
  List<Map<String, dynamic>> _userAchievements = [];
  List<Map<String, dynamic>> _allAchievements = [];
  Map<String, dynamic> _streakData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final level = await _gamificationService.getUserLevel();
    final userAchievements = await _gamificationService.getUserAchievements();
    final allAchievements = await _gamificationService.getAllAchievements();
    final streak = await _gamificationService.getUserStreak();

    if (mounted) {
      setState(() {
        _userLevel = level ?? {};
        _userAchievements = userAchievements;
        _allAchievements = allAchievements;
        _streakData = streak ?? {};
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'GamificationHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Gamification Hub',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'leaderboard',
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              onPressed: () => _showLeaderboard(),
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _userAchievements.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No Achievements Yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Start participating in elections and completing quests to earn achievements!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: theme.colorScheme.primary,
                child: Column(
                  children: [
                    // Level Progression Header
                    _buildLevelHeader(theme),

                    SizedBox(height: 2.h),

                    // Tab Bar
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: theme.colorScheme.onPrimary,
                        unselectedLabelColor:
                            theme.colorScheme.onSurfaceVariant,
                        indicator: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Levels'),
                          Tab(text: 'Achievements'),
                          Tab(text: 'Streaks'),
                        ],
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLevelsTab(theme),
                          _buildAchievementsTab(theme),
                          _buildStreaksTab(theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLevelHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tier Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Tier ${_userLevel['tier'] ?? 1}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(height: 1.h),

          // Level Name
          Text(
            _userLevel['name'] ?? 'Bronze Voter',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 2.h),

          // XP Progress Bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_userLevel['currentXP'] ?? 0} XP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                  Text(
                    '${_userLevel['xpRequired'] ?? 100} XP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_userLevel['progress'] ?? 0.0) as double,
                  minHeight: 1.5.h,
                  backgroundColor: theme.colorScheme.onPrimary.withValues(
                    alpha: 0.3,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.5.h),

          // VP Multiplier
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'stars',
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                '${_userLevel['vpMultiplier'] ?? 1.0}x VP Multiplier',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Level Progression',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          ..._levelProgressMilestones.map((tierLv) {
            final tier = GamificationService.levelTiers[tierLv - 1];
            final userLv = _userLevel['current_level'] as int? ?? 1;
            return LevelProgressionWidget(
              tier: tier,
              isUnlocked: userLv >= tierLv,
              isCurrent: userLv == tierLv,
            );
          }),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${_userAchievements.length}/${_allAchievements.length}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          AchievementGridWidget(
            userAchievements: _userAchievements,
            allAchievements: _allAchievements,
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildStreaksTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Streaks',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          StreakCounterWidget(streakData: _streakData),
          SizedBox(height: 3.h),
          _buildStreakMilestones(theme),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildStreakMilestones(ThemeData theme) {
    final milestones = [
      {'days': 3, 'multiplier': 1.1, 'reward': 'Bronze Streak Badge'},
      {'days': 7, 'multiplier': 1.3, 'reward': 'Silver Streak Badge'},
      {'days': 14, 'multiplier': 1.5, 'reward': 'Gold Streak Badge'},
      {'days': 30, 'multiplier': 2.0, 'reward': 'Diamond Streak Badge'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Streak Milestones',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.5.h),
        ...milestones.map((milestone) {
          final currentStreak = _streakData['currentStreak'] ?? 0;
          final isAchieved = currentStreak >= milestone['days'];

          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: isAchieved
                  ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAchieved
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: isAchieved
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.2,
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: isAchieved
                        ? 'check_circle'
                        : 'local_fire_department',
                    color: isAchieved
                        ? theme.colorScheme.onTertiary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${milestone['days']} Day Streak',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${milestone['multiplier']}x VP Multiplier • ${milestone['reward']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showLeaderboard() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.unifiedGamificationDashboardWebCanonical);
  }
}
