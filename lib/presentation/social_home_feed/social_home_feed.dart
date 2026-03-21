import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/prediction_service.dart';
import '../../services/social_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/feed_card_widget.dart';
import './widgets/jolt_video_card_widget.dart';
import './widgets/prediction_pool_card_widget.dart';
import './widgets/story_scroll_widget.dart';

/// Social Home Feed - Personalized content discovery hub
/// Combines voting activities, Jolts videos, and social interactions with VP earning
class SocialHomeFeed extends StatefulWidget {
  const SocialHomeFeed({super.key});

  @override
  State<SocialHomeFeed> createState() => _SocialHomeFeedState();
}

class _SocialHomeFeedState extends State<SocialHomeFeed> {
  final SocialService _socialService = SocialService.instance;
  final PredictionService _predictionService = PredictionService.instance;
  final VPService _vpService = VPService.instance;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _feedItems = [];
  List<Map<String, dynamic>> _joltVideos = [];
  List<Map<String, dynamic>> _predictionPools = [];
  List<Map<String, dynamic>> _friendActivities = [];
  Map<String, dynamic>? _vpBalance;
  final int _unreadNotifications = 3;
  int _feedOffset = 0;
  bool _feedHasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFeedData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreContent();
    }
  }

  Future<void> _loadFeedData() async {
    setState(() => _isLoading = true);
    _feedOffset = 0;
    _feedHasMore = true;

    try {
      final feedResult = await _socialService.getSocialFeedPaginated(offset: 0, limit: 20);
      final results = await Future.wait<dynamic>([
        Future.value(feedResult),
        _socialService.getSocialFeed(limit: 10),
        _predictionService.getActivePools(),
        _socialService.getSocialFeed(limit: 10),
        _vpService.getVPBalance(),
      ]);

      final feedData = results[0] as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _feedItems = List<Map<String, dynamic>>.from(feedData['data'] ?? []);
          _feedHasMore = feedData['hasMore'] == true;
          _feedOffset = (_feedItems.length);
          _joltVideos = results[1] as List<Map<String, dynamic>>;
          _predictionPools = results[2] as List<Map<String, dynamic>>;
          _friendActivities = results[3] as List<Map<String, dynamic>>;
          _vpBalance = results[4] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load feed data error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshFeed() async {
    setState(() => _isRefreshing = true);
    await _loadFeedData();
    setState(() => _isRefreshing = false);
  }

  Future<void> _loadMoreContent() async {
    if (_isLoadingMore || !_feedHasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await _socialService.getSocialFeedPaginated(
        offset: _feedOffset,
        limit: 20,
      );
      final more = List<Map<String, dynamic>>.from(result['data'] ?? []);
      if (mounted) {
        setState(() {
          _feedItems = [..._feedItems, ...more];
          _feedOffset += more.length;
          _feedHasMore = result['hasMore'] == true;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Load more content error: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'SocialHomeFeed',
      onRetry: _loadFeedData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Home Feed',
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: CustomIconWidget(
              iconName: 'home',
              size: 6.w,
              color: AppTheme.primaryLight,
            ),
          ),
          actions: [
            // VP Balance
            Container(
              margin: EdgeInsets.only(right: 3.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.accentLight.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'stars',
                    size: 4.w,
                    color: AppTheme.accentLight,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${_vpBalance?['available_vp'] ?? 0}',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentLight,
                    ),
                  ),
                ],
              ),
            ),
            // Notifications
            Stack(
              children: [
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'notifications',
                    size: 6.w,
                    color: AppTheme.textPrimaryLight,
                  ),
                  onPressed: () {
                    // Navigate to notifications
                  },
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: AppTheme.errorLight,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 4.w,
                        minHeight: 4.w,
                      ),
                      child: Text(
                        '$_unreadNotifications',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryLight),
              )
            : _feedItems.isEmpty
            ? NoDataEmptyState(
                title: 'No Content Available',
                description:
                    'Start following users and engaging with content to personalize your feed.',
                onRefresh: _loadFeedData,
              )
            : RefreshIndicator(
                onRefresh: _refreshFeed,
                color: AppTheme.primaryLight,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Story-style horizontal scroll for prediction pools
                    SliverToBoxAdapter(
                      child: StoryScrollWidget(
                        predictionPools: _predictionPools,
                        onPoolTap: (poolId) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.predictionAnalyticsDashboard,
                            arguments: poolId,
                          );
                        },
                      ),
                    ),

                    // Mixed content feed
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index % 5 == 0 && _joltVideos.isNotEmpty) {
                            // Show Jolt video every 5 items
                            final joltIndex = (index ~/ 5) % _joltVideos.length;
                            return JoltVideoCardWidget(
                              jolt: _joltVideos[joltIndex],
                              onLike: (joltId) => _handleJoltLike(joltId),
                              onShare: (joltId) => _handleJoltShare(joltId),
                              onComment: (joltId) => _handleJoltComment(joltId),
                            );
                          } else if (index % 3 == 0 &&
                              _predictionPools.isNotEmpty) {
                            // Show prediction pool every 3 items
                            final poolIndex =
                                (index ~/ 3) % _predictionPools.length;
                            return PredictionPoolCardWidget(
                              pool: _predictionPools[poolIndex],
                              onEnter: (poolId) =>
                                  _handleEnterPrediction(poolId),
                            );
                          } else if (_friendActivities.isNotEmpty) {
                            // Show friend activity
                            final activityIndex =
                                index % _friendActivities.length;
                            return FeedCardWidget(
                              activity: _friendActivities[activityIndex],
                              onQuickVote: (electionId) =>
                                  _handleQuickVote(electionId),
                            );
                          }
                          return SizedBox.shrink();
                        },
                        childCount: 20, // Initial feed size
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showComposeOptions();
          },
          backgroundColor: AppTheme.primaryLight,
          icon: CustomIconWidget(
            iconName: 'add',
            size: 5.w,
            color: Colors.white,
          ),
          label: Text(
            'Create',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showComposeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'videocam',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              title: Text(
                'Create Jolt Video',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to Jolt creation
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'how_to_vote',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              title: Text(
                'Share Vote',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.createVote);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'trending_up',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              title: Text(
                'Create Prediction Pool',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to prediction creation
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleJoltLike(String joltId) async {
    // Placeholder: Add your jolt like logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+5 VP earned for liking!'),
        backgroundColor: AppTheme.accentLight,
      ),
    );
  }

  Future<void> _handleJoltShare(String joltId) async {
    // Placeholder: Add your jolt share logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+10 VP earned for sharing!'),
        backgroundColor: AppTheme.accentLight,
      ),
    );
  }

  Future<void> _handleJoltComment(String joltId) async {
    // Navigate to comment screen
  }

  Future<void> _handleEnterPrediction(String poolId) async {
    Navigator.pushNamed(
      context,
      AppRoutes.predictionAnalyticsDashboard,
      arguments: poolId,
    );
  }

  Future<void> _handleQuickVote(String electionId) async {
    Navigator.pushNamed(context, AppRoutes.voteCasting, arguments: electionId);
  }
}
