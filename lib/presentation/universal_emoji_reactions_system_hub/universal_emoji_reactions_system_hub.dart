import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';

import '../../services/auth_service.dart';
import '../../services/universal_emoji_reaction_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/content_type_coverage_widget.dart';
import './widgets/reaction_analytics_widget.dart';
import './widgets/user_engagement_tracking_widget.dart';
import './widgets/moderation_controls_widget.dart';
import './widgets/emoji_picker_panel_widget.dart';
import './widgets/reaction_leaderboard_widget.dart';

class UniversalEmojiReactionsSystemHub extends StatefulWidget {
  const UniversalEmojiReactionsSystemHub({super.key});

  @override
  State<UniversalEmojiReactionsSystemHub> createState() =>
      _UniversalEmojiReactionsSystemHubState();
}

class _UniversalEmojiReactionsSystemHubState
    extends State<UniversalEmojiReactionsSystemHub>
    with SingleTickerProviderStateMixin {
  final UniversalEmojiReactionService _reactionService =
      UniversalEmojiReactionService.instance;
  final AuthService _auth = AuthService.instance;

  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic> _overviewStats = {};
  List<Map<String, dynamic>> _topReactions = [];
  List<Map<String, dynamic>> _moderationQueue = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOverviewData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOverviewData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load overview statistics
      _overviewStats = {
        'total_reactions': 1247893,
        'popular_emoji_trends': ['👍', '❤️', '😂', '🔥', '🎉'],
        'moderation_queue_count': 23,
        'avg_sentiment_score': 67.3,
        'reaction_velocity': 12.4,
      };

      // Load top reactions
      _topReactions = [
        {'emoji': '👍', 'count': 342567, 'percentage': 27.4},
        {'emoji': '❤️', 'count': 289431, 'percentage': 23.2},
        {'emoji': '😂', 'count': 187184, 'percentage': 15.0},
        {'emoji': '🔥', 'count': 155987, 'percentage': 12.5},
        {'emoji': '🎉', 'count': 133524, 'percentage': 10.7},
      ];

      // Load moderation queue
      _moderationQueue = [
        {
          'content_type': 'post',
          'content_id': '123',
          'emoji': '🖕',
          'user_id': 'user_456',
          'flagged_at': DateTime.now().subtract(const Duration(hours: 2)),
          'reason': 'Inappropriate emoji usage',
        },
      ];

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Load overview data error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Universal Emoji Reactions System',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
            onPressed: _loadOverviewData,
          ),
          IconButton(
            icon: Icon(Icons.settings, color: theme.colorScheme.onSurface),
            onPressed: () {
              // Settings dialog
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusOverview(theme),
          _buildTabBar(theme),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      ContentTypeCoverageWidget(),
                      ReactionAnalyticsWidget(
                        topReactions: _topReactions,
                        overviewStats: _overviewStats,
                      ),
                      UserEngagementTrackingWidget(),
                      ModerationControlsWidget(
                        moderationQueue: _moderationQueue,
                        onRefresh: _loadOverviewData,
                      ),
                      ReactionLeaderboardWidget(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEmojiPickerDemo,
        backgroundColor: theme.colorScheme.secondary,
        icon: const Icon(Icons.emoji_emotions, color: Colors.white),
        label: Text(
          'Test Emoji Picker',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverview(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                theme,
                'Total Reactions',
                '${(_overviewStats['total_reactions'] ?? 0) ~/ 1000}K',
                Icons.emoji_emotions,
              ),
              _buildStatCard(
                theme,
                'Moderation Queue',
                '${_overviewStats['moderation_queue_count'] ?? 0}',
                Icons.flag,
              ),
              _buildStatCard(
                theme,
                'Sentiment Score',
                '${_overviewStats['avg_sentiment_score'] ?? 0}%',
                Icons.trending_up,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Popular Emoji Trends: ',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ...(_overviewStats['popular_emoji_trends'] as List? ?? []).map(
                (emoji) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1.w),
                  child: Text(emoji, style: TextStyle(fontSize: 20.sp)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: theme.cardColor,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: theme.colorScheme.primary,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        labelStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Content Coverage'),
          Tab(text: 'Analytics'),
          Tab(text: 'User Engagement'),
          Tab(text: 'Moderation'),
          Tab(text: 'Leaderboard'),
        ],
      ),
    );
  }

  void _showEmojiPickerDemo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmojiPickerPanelWidget(
        onEmojiSelected: (emoji) {
          Navigator.pop(context);
          _showReactionAnimation(emoji.emoji);
        },
      ),
    );
  }

  void _showReactionAnimation(String emoji) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          width: 60.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/reaction_burst.json',
                width: 40.w,
                height: 20.h,
                repeat: false,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.celebration,
                    size: 60.sp,
                    color: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
              SizedBox(height: 2.h),
              Text(emoji, style: TextStyle(fontSize: 60.sp)),
              SizedBox(height: 2.h),
              Text(
                'Reaction Added!',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }
}
