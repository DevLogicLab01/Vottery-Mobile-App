import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/twilio_notification_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/active_vote_card_widget.dart';
import './widgets/empty_state_widget.dart';

class VoteDashboardInitialPage extends StatefulWidget {
  const VoteDashboardInitialPage({super.key});

  @override
  State<VoteDashboardInitialPage> createState() =>
      _VoteDashboardInitialPageState();
}

class _VoteDashboardInitialPageState extends State<VoteDashboardInitialPage> {
  bool isOnline = true;
  bool isRefreshing = false;
  int queuedVotes = 0;

  // Mock data for active votes
  final List<Map<String, dynamic>> activeVotes = [
    {
      "id": 1,
      "title": "Annual Budget Allocation 2026",
      "creator": "Sarah Johnson",
      "creatorAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1bc4388a2-1764913853283.png",
      "creatorAvatarLabel":
          "Professional headshot of a woman with shoulder-length brown hair wearing a navy blazer",
      "deadline": DateTime.now().add(const Duration(hours: 6)),
      "totalVotes": 1247,
      "participated": false,
      "status": "urgent",
      "progress": 0.68,
      "description":
          "Vote on the proposed budget allocation for fiscal year 2026",
    },
    {
      "id": 2,
      "title": "New Office Location Selection",
      "creator": "Michael Chen",
      "creatorAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1968dc5fe-1768042766151.png",
      "creatorAvatarLabel":
          "Professional headshot of an Asian man with short black hair wearing glasses and a white shirt",
      "deadline": DateTime.now().add(const Duration(hours: 18)),
      "totalVotes": 892,
      "participated": false,
      "status": "ending_soon",
      "progress": 0.45,
      "description":
          "Choose the preferred location for our new regional office",
    },
    {
      "id": 3,
      "title": "Employee Benefits Package Update",
      "creator": "Emily Rodriguez",
      "creatorAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_111b18b26-1764843644335.png",
      "creatorAvatarLabel":
          "Professional headshot of a Hispanic woman with long dark hair wearing a teal blouse",
      "deadline": DateTime.now().add(const Duration(days: 2)),
      "totalVotes": 2156,
      "participated": true,
      "status": "participated",
      "progress": 0.82,
      "description": "Vote on proposed changes to employee benefits and perks",
    },
    {
      "id": 4,
      "title": "Company Sustainability Initiative",
      "creator": "David Thompson",
      "creatorAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_16899eed5-1765527709680.png",
      "creatorAvatarLabel":
          "Professional headshot of a man with gray hair and beard wearing a dark suit",
      "deadline": DateTime.now().add(const Duration(days: 5)),
      "totalVotes": 1534,
      "participated": false,
      "status": "active",
      "progress": 0.56,
      "description": "Support our new environmental sustainability programs",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await TwilioNotificationService.instance.initialize();
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => isRefreshing = true);

    // Simulate network refresh
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isRefreshing = false;
      isOnline = true;
    });
  }

  void _handleVoteNow(Map<String, dynamic> vote) {
    Navigator.of(context, rootNavigator: true).pushNamed('/vote-casting');
  }

  void _handleBookmark(Map<String, dynamic> vote) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vote bookmarked: ${vote["title"]}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleShare(Map<String, dynamic> vote) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: ${vote["title"]}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleDetails(Map<String, dynamic> vote) {
    Navigator.of(context, rootNavigator: true).pushNamed('/vote-results');
  }

  void _handleCreateVote() {
    Navigator.of(context, rootNavigator: true).pushNamed('/create-vote');
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Vote Dashboard',
        variant: CustomAppBarVariant.withSyncStatus,
        isOnline: isOnline,
        actions: [
          IconButton(
            icon: Icon(Icons.analytics, size: 24.w),
            onPressed: () {
              Navigator.pushNamed(context, '/ai-analytics-hub');
            },
            tooltip: 'AI Analytics Hub',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'search',
              color:
                  theme.appBarTheme.foregroundColor ??
                  theme.colorScheme.onPrimary,
              size: 24,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/vote-discovery');
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'notifications_outlined',
              color:
                  theme.appBarTheme.foregroundColor ??
                  theme.colorScheme.onPrimary,
              size: 24,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: activeVotes.isEmpty
            ? EmptyStateWidget(
                onBrowseAll: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Browse all votes feature coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              )
            : CustomScrollView(
                slivers: [
                  // Sticky header with greeting and status
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'You have ${activeVotes.where((v) => !v["participated"]).length} active votes',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (!isOnline && queuedVotes > 0) ...[
                            SizedBox(height: 1.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 3.w,
                                vertical: 1.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CustomIconWidget(
                                    iconName: 'cloud_off',
                                    color: const Color(0xFFF59E0B),
                                    size: 20,
                                  ),
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: Text(
                                      '$queuedVotes vote(s) queued for sync',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFFF59E0B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Active votes list
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final vote = activeVotes[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: ActiveVoteCardWidget(
                            vote: vote,
                            onVoteNow: () => _handleVoteNow(vote),
                            onBookmark: () => _handleBookmark(vote),
                            onShare: () => _handleShare(vote),
                            onDetails: () => _handleDetails(vote),
                          ),
                        );
                      }, childCount: activeVotes.length),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleCreateVote,
        icon: CustomIconWidget(
          iconName: 'add',
          color:
              theme.floatingActionButtonTheme.foregroundColor ??
              theme.colorScheme.onSecondary,
          size: 24,
        ),
        label: Text(
          'Create Vote',
          style: theme.textTheme.labelLarge?.copyWith(
            color:
                theme.floatingActionButtonTheme.foregroundColor ??
                theme.colorScheme.onSecondary,
          ),
        ),
      ),
    );
  }
}