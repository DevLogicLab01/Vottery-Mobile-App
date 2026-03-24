import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../config/batch1_route_allowlist.dart';
import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/carousel_content_service.dart';
import '../../services/claude_feed_curation_service.dart';
import '../../services/follow_service.dart';
import '../../services/jolts_service.dart';
import '../../services/moments_service.dart';
import '../../services/social_service.dart';
import '../../services/voting_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/dual_header_bottom_bar.dart';
import '../../widgets/dual_header_top_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/gamification/platform_gamification_banner.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/ad_slot_widget.dart';
import './widgets/gradient_flow_carousel_widget.dart';
import './widgets/horizontal_snap_carousel_widget.dart';
import './widgets/post_card_widget.dart';
import './widgets/post_composer_widget.dart';
import './widgets/suggested_connection_compact_card.dart';
import './widgets/suggested_elections_widget.dart';
import './widgets/vertical_card_stack_widget.dart';

/// Social Media Home Feed - Facebook mobile app-style interface
/// Implements comprehensive social interactions with VP earning and real-time updates
class SocialMediaHomeFeed extends StatefulWidget {
  const SocialMediaHomeFeed({super.key});

  @override
  State<SocialMediaHomeFeed> createState() => _SocialMediaHomeFeedState();
}

class _SocialMediaHomeFeedState extends State<SocialMediaHomeFeed>
    with SingleTickerProviderStateMixin {
  final SocialService _socialService = SocialService.instance;
  final JoltsService _joltsService = JoltsService.instance;
  final VPService _vpService = VPService.instance;
  final VotingService _votingService = VotingService.instance;
  final FollowService _followService = FollowService.instance;
  final MomentsService _momentsService = MomentsService.instance;
  final ScrollController _scrollController = ScrollController();
  final CarouselContentService _carouselService = CarouselContentService();
  final AuthService _authService = AuthService.instance;
  final ClaudeFeedCurationService _claudeCurationService =
      ClaudeFeedCurationService.instance;

  final int _currentBottomTab = 0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _feedItems = [];
  List<Map<String, dynamic>> _activeElections = [];
  List<Map<String, dynamic>> _liveJackpots = [];
  Map<String, dynamic>? _vpBalance;
  final int _unreadNotifications = 3;
  final int _unreadMessages = 5;
  final int _friendRequests = 2;
  List<Map<String, dynamic>> _moments = [];
  List<Map<String, dynamic>> _suggestedConnections = [];
  List<Map<String, dynamic>> _recommendedGroups = [];
  List<Map<String, dynamic>> _recommendedElections = [];
  List<Map<String, dynamic>> _recentWinners = [];
  int _friendRequestsCount = 0;
  final int _messagesCount = 0;
  final int _notificationsCount = 0;

  // Carousel data
  final List<Map<String, dynamic>> _jolts = [];
  final List<Map<String, dynamic>> _momentsCarousel = [];
  final List<Map<String, dynamic>> _groups = [];
  final List<Map<String, dynamic>> _trendingTopics = [];
  final List<Map<String, dynamic>> _topEarners = [];

  final bool _isLoadingCarousels = true;
  String? _userId;

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
    // Refresh Claude recommendations on scroll
    if (_scrollController.position.pixels % 500 < 10) {
      _claudeCurationService.refreshRecommendations();
    }
  }

  Future<void> _loadFeedData() async {
    setState(() => _isLoading = true);
    _userId = _authService.currentUser?.id;

    try {
      final results = await Future.wait<dynamic>([
        _socialService.getSocialFeed(limit: 50),
        _votingService.getElections(status: 'active', limit: 10),
        _vpService.getVPBalance(),
        _momentsService.getFollowingMoments(),
        _followService.getSuggestedUsers(),
        _socialService.getPendingRequests(),
        _votingService.getElections(status: 'active', limit: 5),
        _loadRecentWinners(),
      ]);

      setState(() {
        _feedItems = results[0] as List<Map<String, dynamic>>;
        _activeElections = results[1] as List<Map<String, dynamic>>;
        _vpBalance = results[2] as Map<String, dynamic>?;
        _moments = results[3] as List<Map<String, dynamic>>;
        _suggestedConnections = results[4] as List<Map<String, dynamic>>;
        _friendRequestsCount = (results[5] as List).length;
        _liveJackpots = (results[1] as List<Map<String, dynamic>>)
            .take(3)
            .toList();
        _recommendedElections = results[6] as List<Map<String, dynamic>>;
        _recentWinners = results[7] as List<Map<String, dynamic>>;
        _recommendedGroups = _loadMockGroups();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load feed data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadRecentWinners() async {
    return [
      {
        'id': '1',
        'name': 'Sarah Johnson',
        'avatar_url':
            'https://images.unsplash.com/photo-1653506586621-c5c745c7e937',
        'achievement': 'Won 5000 VP in Daily Lottery',
      },
      {
        'id': '2',
        'name': 'Michael Chen',
        'avatar_url':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
        'achievement': 'Top voter this week',
      },
      {
        'id': '3',
        'name': 'Emma Williams',
        'avatar_url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_19b45cc39-1765034594667.png',
        'achievement': 'Jackpot winner - 10,000 VP',
      },
    ];
  }

  List<Map<String, dynamic>> _loadMockGroups() {
    return [
      {
        'id': '1',
        'name': 'Tech Enthusiasts',
        'description': 'Discuss latest technology trends',
        'image_url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1b0aaa9b3-1771047807901.png',
        'member_count': 1250,
      },
      {
        'id': '2',
        'name': 'Political Debate',
        'description': 'Engage in political discussions',
        'image_url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1bdbe81c3-1769675101120.png',
        'member_count': 3400,
      },
      {
        'id': '3',
        'name': 'Community Voting',
        'description': 'Local community decisions',
        'image_url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_11d906d2e-1768190256729.png',
        'member_count': 890,
      },
    ];
  }

  Future<void> _refreshFeed() async {
    setState(() => _isRefreshing = true);
    await _loadFeedData();
    setState(() => _isRefreshing = false);
  }

  Future<void> _loadMoreContent() async {
    debugPrint('Loading more content...');
  }

  void _handleDoubleTapLike(String postId) async {
    await _socialService.sendFriendRequest(postId);
    await _vpService.awardSocialVP('post_like', postId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❤️ Liked! +5 VP earned'),
        backgroundColor: AppTheme.accentLight,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPostComposer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostComposerWidget(
        onPost: (content, mediaUrls) async {
          await _refreshFeed();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'SocialMediaHomeFeed',
      onRetry: _loadFeedData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: DualHeaderTopBar(
          friendRequestsCount: _friendRequestsCount,
          messagesCount: _messagesCount,
          notificationsCount: _notificationsCount,
          currentRoute: AppRoutes.socialMediaHomeFeed,
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 8)
            : _feedItems.isEmpty
            ? NoDataEmptyState(
                title: 'No Posts Yet',
                description:
                    'Follow users and join communities to see content in your feed.',
                onRefresh: _loadFeedData,
              )
            : RefreshIndicator(
                onRefresh: _refreshFeed,
                color: AppTheme.primaryLight,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Platform Gamification Banner
                    const SliverToBoxAdapter(
                      child: PlatformGamificationBanner(),
                    ),

                    // Moments Carousel (Create Moment first, then moments - always visible)
                    SliverToBoxAdapter(child: _buildMomentsCarousel()),

                    // Suggested Connections - horizontal scroll (People You May Know style)
                    SliverToBoxAdapter(child: _buildSuggestedConnectionsCarousel()),

                    // Jolts - horizontal scroll (Reels-style short videos)
                    SliverToBoxAdapter(child: _buildJoltsCarousel()),

                    // Suggested Elections Sidebar
                    SliverToBoxAdapter(child: SuggestedElectionsWidget()),
                    SliverToBoxAdapter(child: SizedBox(height: 2.h)),

                    // Post Composer
                    SliverToBoxAdapter(
                      child: PostComposerWidget(
                        onPost: (content, mediaUrls) async {
                          await _refreshFeed();
                        },
                      ),
                    ),

                    // Standard Posts (2-3 items)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _feedItems.length || index >= 2) {
                            return null;
                          }
                          final item = _feedItems[index];
                          return PostCardWidget(
                            post: item,
                            onLike: (postId) => _handleDoubleTapLike(postId),
                            onComment: (postId) {},
                            onShare: (postId) {},
                          );
                        },
                        childCount: _feedItems.length > 2
                            ? 2
                            : _feedItems.length,
                      ),
                    ),

                    // Ad Slot 1 - home_feed_1 (after first 7 items)
                    SliverToBoxAdapter(
                      child: AdSlotWidget(slotId: 'home_feed_1'),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 40)),

                    // Standard Posts (2-3 more)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final actualIndex = index + 2;
                          if (actualIndex >= _feedItems.length || index >= 2) {
                            return null;
                          }
                          final item = _feedItems[actualIndex];
                          return PostCardWidget(
                            post: item,
                            onLike: (postId) => _handleDoubleTapLike(postId),
                            onComment: (postId) {},
                            onShare: (postId) {},
                          );
                        },
                        childCount: _feedItems.length > 4
                            ? 2
                            : (_feedItems.length - 2).clamp(0, 2),
                      ),
                    ),

                    // Ad Slot 2 - home_feed_2 (after second 7 items)
                    SliverToBoxAdapter(
                      child: AdSlotWidget(slotId: 'home_feed_2'),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 40)),

                    // HORIZONTAL CAROUSEL - Recommended Groups (Suggested Group for You style)
                    SliverToBoxAdapter(child: _buildRecommendedGroupsCarousel()),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 60)),

                    // More Posts
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final actualIndex = index + 4;
                          if (actualIndex >= _feedItems.length || index >= 2) {
                            return null;
                          }
                          final item = _feedItems[actualIndex];
                          return PostCardWidget(
                            post: item,
                            onLike: (postId) => _handleDoubleTapLike(postId),
                            onComment: (postId) {},
                            onShare: (postId) {},
                          );
                        },
                        childCount: _feedItems.length > 6
                            ? 2
                            : (_feedItems.length - 4).clamp(0, 2),
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 40)),

                    // GRADIENT FLOW CAROUSEL - Trending Topics
                    SliverToBoxAdapter(
                      child: GradientFlowCarouselWidget(
                        contentType: CarouselContentType.trendingTopics,
                        title: '📈 Trending Topics',
                        cardHeight: 180,
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 60)),

                    // More Posts
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final actualIndex = index + 6;
                          if (actualIndex >= _feedItems.length || index >= 2) {
                            return null;
                          }
                          final item = _feedItems[actualIndex];
                          return PostCardWidget(
                            post: item,
                            onLike: (postId) => _handleDoubleTapLike(postId),
                            onComment: (postId) {},
                            onShare: (postId) {},
                          );
                        },
                        childCount: _feedItems.length > 8
                            ? 2
                            : (_feedItems.length - 6).clamp(0, 2),
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 40)),

                    // HORIZONTAL SNAP CAROUSEL - Live Moments (Stories)
                    SliverToBoxAdapter(
                      child: HorizontalSnapCarouselWidget(
                        contentType: CarouselContentType.moments,
                        title: '⏰ Live Moments',
                        cardHeight: 280,
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 60)),

                    // More Posts
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final actualIndex = index + 8;
                          if (actualIndex >= _feedItems.length || index >= 2) {
                            return null;
                          }
                          final item = _feedItems[actualIndex];
                          return PostCardWidget(
                            post: item,
                            onLike: (postId) => _handleDoubleTapLike(postId),
                            onComment: (postId) {},
                            onShare: (postId) {},
                          );
                        },
                        childCount: _feedItems.length > 10
                            ? 2
                            : (_feedItems.length - 8).clamp(0, 2),
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 40)),

                    // VERTICAL CARD STACK - Recommended Elections
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🗳️ Elections For You',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              height: 520,
                              child: VerticalCardStackWidget(
                                contentType:
                                    CarouselContentType.recommendedElections,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 60)),

                    // More Posts
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final actualIndex = index + 10;
                          if (actualIndex >= _feedItems.length || index >= 2) {
                            return null;
                          }
                          final item = _feedItems[actualIndex];
                          return PostCardWidget(
                            post: item,
                            onLike: (postId) => _handleDoubleTapLike(postId),
                            onComment: (postId) {},
                            onShare: (postId) {},
                          );
                        },
                        childCount: _feedItems.length > 12
                            ? 2
                            : (_feedItems.length - 10).clamp(0, 2),
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 40)),

                    // GRADIENT FLOW CAROUSEL - Top Earners Leaderboard
                    SliverToBoxAdapter(
                      child: GradientFlowCarouselWidget(
                        contentType: CarouselContentType.topEarners,
                        title: '🏆 Top Earners This Month',
                        cardHeight: 160,
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 60)),

                    // More Posts
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final actualIndex = index + 12;
                          if (actualIndex >= _feedItems.length || index >= 2) {
                            return null;
                          }
                          final item = _feedItems[actualIndex];
                          return PostCardWidget(
                            post: item,
                            onLike: (postId) => _handleDoubleTapLike(postId),
                            onComment: (postId) {},
                            onShare: (postId) {},
                          );
                        },
                        childCount: _feedItems.length > 14
                            ? 2
                            : (_feedItems.length - 12).clamp(0, 2),
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 40)),

                    // HORIZONTAL SNAP CAROUSEL - Featured Creator Spotlights
                    SliverToBoxAdapter(
                      child: HorizontalSnapCarouselWidget(
                        contentType: CarouselContentType.creatorSpotlights,
                        title: '⭐ Featured Creators',
                        cardHeight: 340,
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 60)),

                    // More Posts
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final actualIndex = index + 14;
                          if (actualIndex >= _feedItems.length || index >= 2) {
                            return null;
                          }
                          final item = _feedItems[actualIndex];
                          return PostCardWidget(
                            post: item,
                            onLike: (postId) => _handleDoubleTapLike(postId),
                            onComment: (postId) {},
                            onShare: (postId) {},
                          );
                        },
                        childCount: _feedItems.length > 16
                            ? 2
                            : (_feedItems.length - 14).clamp(0, 2),
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 40)),

                    // VERTICAL CARD STACK - Creator Marketplace Services
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💼 Creator Services',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              height: 520,
                              child: VerticalCardStackWidget(
                                contentType:
                                    CarouselContentType.creatorServices,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 60)),

                    // More Posts
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final actualIndex = index + 16;
                          if (actualIndex >= _feedItems.length || index >= 2) {
                            return null;
                          }
                          final item = _feedItems[actualIndex];
                          return PostCardWidget(
                            post: item,
                            onLike: (postId) => _handleDoubleTapLike(postId),
                            onComment: (postId) {},
                            onShare: (postId) {},
                          );
                        },
                        childCount: _feedItems.length > 18
                            ? 2
                            : (_feedItems.length - 16).clamp(0, 2),
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 40)),

                    // GRADIENT FLOW CAROUSEL - Prediction Accuracy Champions
                    SliverToBoxAdapter(
                      child: GradientFlowCarouselWidget(
                        contentType: CarouselContentType.accuracyChampions,
                        title: '🎯 Prediction Champions',
                        cardHeight: 140,
                      ),
                    ),

                    // Buffer zone
                    SliverToBoxAdapter(child: SizedBox(height: 60)),

                    // Remaining Posts
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final actualIndex = index + 18;
                          if (actualIndex >= _feedItems.length) {
                            return null;
                          }
                          final item = _feedItems[actualIndex];
                          return PostCardWidget(
                            post: item,
                            onLike: (postId) => _handleDoubleTapLike(postId),
                            onComment: (postId) {},
                            onShare: (postId) {},
                          );
                        },
                        childCount: _feedItems.length > 18
                            ? _feedItems.length - 18
                            : 0,
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: DualHeaderBottomBar(
          currentRoute: AppRoutes.socialMediaHomeFeed,
          onNavigate: (route) {
            if (!Batch1RouteAllowlist.isAllowed(route)) return;
            Navigator.pushNamed(context, route);
          },
        ),
      ),
    );
  }

  Widget _buildMomentsCarousel() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Moments',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (!Batch1RouteAllowlist.isAllowed(
                      AppRoutes.momentsStoriesHub,
                    )) {
                      return;
                    }
                    Navigator.pushNamed(context, AppRoutes.momentsStoriesHub);
                  },
                  child: Text(
                    'See All',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 12.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: _moments.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCreateMomentCard();
                }
                final moment = _moments[index - 1];
                return _buildMomentCard(moment);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateMomentCard() {
    if (!Batch1RouteAllowlist.isAllowed(AppRoutes.momentsStoriesHub)) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.momentsStoriesHub);
      },
      child: Container(
        width: 22.w,
        margin: EdgeInsets.only(right: 3.w),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.vibrantYellow,
                        AppTheme.vibrantYellow.withAlpha(179),
                      ],
                    ),
                  ),
                  child: Icon(Icons.add, color: Colors.black, size: 8.w),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Create Moment',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentCard(Map<String, dynamic> moment) {
    final creator = moment['creator'] as Map<String, dynamic>?;
    final username = creator?['username'] as String? ?? 'User';
    final avatarUrl = creator?['avatar_url'] as String?;

    return GestureDetector(
      onTap: () {
        if (!Batch1RouteAllowlist.isAllowed(AppRoutes.momentsStoriesHub)) {
          return;
        }
        Navigator.pushNamed(context, AppRoutes.momentsStoriesHub);
      },
      child: Container(
        width: 22.w,
        margin: EdgeInsets.only(right: 3.w),
        child: Column(
          children: [
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.vibrantYellow, width: 2),
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.grey[300],
              ),
              child: avatarUrl == null
                  ? Icon(Icons.person, color: Colors.grey[600], size: 8.w)
                  : null,
            ),
            SizedBox(height: 0.5.h),
            Text(
              username,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedConnectionsCarousel() {
    if (_suggestedConnections.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suggested Connections',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (!Batch1RouteAllowlist.isAllowed(
                      AppRoutes.friendRequestsHub,
                    )) {
                      return;
                    }
                    Navigator.pushNamed(context, AppRoutes.friendRequestsHub);
                  },
                  child: Text(
                    'See All',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 18.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: _suggestedConnections.length,
              itemBuilder: (context, index) {
                final user = _suggestedConnections[index];
                final userId = user['id'] as String?;
                if (userId == null) return const SizedBox.shrink();
                return SuggestedConnectionCompactCard(
                  user: user,
                  onFollow: () async {
                    await _followService.followUser(userId);
                    if (mounted) _loadFeedData();
                  },
                  onAddFriend: () async {
                    await _socialService.sendFriendRequest(userId);
                    if (mounted) _loadFeedData();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoltsCarousel() {
    return HorizontalSnapCarouselWidget(
      contentType: CarouselContentType.jolts,
      title: '⚡ Jolts',
      cardHeight: 200,
      onPageChanged: (_) {},
    );
  }

  Widget _buildRecommendedGroupsCarousel() {
    return HorizontalSnapCarouselWidget(
      contentType: CarouselContentType.recommendedGroups,
      title: '👥 Recommended Groups',
      cardHeight: 180,
      onPageChanged: (_) {},
    );
  }
}
