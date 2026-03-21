import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/claude_feed_curation_service.dart';
import '../../services/follow_service.dart';
import '../../services/moments_service.dart';
import '../../services/social_service.dart';
import '../../services/voting_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/offline_status_badge.dart';
import '../social_media_home_feed/widgets/recommendation_sidebar_widget.dart';

class EnhancedSocialMediaHomeFeedWithClaudeConfidenceSidebar
    extends StatefulWidget {
  const EnhancedSocialMediaHomeFeedWithClaudeConfidenceSidebar({super.key});

  @override
  State<EnhancedSocialMediaHomeFeedWithClaudeConfidenceSidebar> createState() =>
      _EnhancedSocialMediaHomeFeedWithClaudeConfidenceSidebarState();
}

class _EnhancedSocialMediaHomeFeedWithClaudeConfidenceSidebarState
    extends State<EnhancedSocialMediaHomeFeedWithClaudeConfidenceSidebar> {
  final SocialService _socialService = SocialService.instance;
  final VPService _vpService = VPService.instance;
  final VotingService _votingService = VotingService.instance;
  final FollowService _followService = FollowService.instance;
  final MomentsService _momentsService = MomentsService.instance;
  final ClaudeFeedCurationService _claudeService =
      ClaudeFeedCurationService.instance;
  final AuthService _authService = AuthService.instance;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSidebarOpen = false;
  List<Map<String, dynamic>> _feedItems = [];
  List<Map<String, dynamic>> _activeElections = [];
  List<Map<String, dynamic>> _moments = [];
  int _friendRequestsCount = 0;
  String? _userId;

  Stream<List<FeedRecommendation>>? _recommendationsStream;
  List<FeedRecommendation> _currentRecommendations = [];

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
    if (_scrollController.position.pixels > 200 && _userId != null) {
      _claudeService.refreshRecommendations();
    }
  }

  Future<void> _loadFeedData() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      _userId = user?.id;

      final results = await Future.wait<dynamic>([
        _socialService.getSocialFeed(limit: 30),
        _votingService.getElections(status: 'active', limit: 10),
        _momentsService.getFollowingMoments(),
        _followService.getSuggestedUsers(),
        _socialService.getPendingRequests(),
      ]);

      setState(() {
        _feedItems = results[0] as List<Map<String, dynamic>>;
        _activeElections = results[1] as List<Map<String, dynamic>>;
        _moments = results[2] as List<Map<String, dynamic>>;
        _friendRequestsCount = (results[4] as List).length;
        _isLoading = false;
      });

      if (_userId != null) {
        setState(() {
          _recommendationsStream = _claudeService.getRecommendationsStream(
            userId: _userId!,
            contentType: 'mixed',
          );
        });
      }
    } catch (e) {
      debugPrint('Load feed data error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _isLoading
                      ? const ShimmerSkeletonLoader(child: SizedBox())
                      : _buildFeedContent(),
                ),
                _buildBottomBar(),
              ],
            ),
            if (_isSidebarOpen)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: _buildRecommendationSidebar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Text(
            'Vottery',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1877F2),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: _isSidebarOpen
                    ? const Color(0xFF1877F2)
                    : Colors.grey.withAlpha(30),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: _isSidebarOpen
                        ? Colors.white
                        : const Color(0xFF1877F2),
                    size: 4.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'AI',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: _isSidebarOpen
                          ? Colors.white
                          : const Color(0xFF1877F2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 2.w),
          const OfflineStatusBadge(),
          SizedBox(width: 2.w),
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                ),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.notificationCenterHub),
              ),
              if (_friendRequestsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 4.w,
                    height: 4.w,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _friendRequestsCount.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 7.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedContent() {
    return RefreshIndicator(
      onRefresh: _loadFeedData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildStorySection()),
          SliverToBoxAdapter(child: _buildPostComposer()),
          SliverToBoxAdapter(child: _buildElectionsSection()),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index >= _feedItems.length) return null;
              return _buildFeedItem(_feedItems[index]);
            }, childCount: _feedItems.length),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 2.h)),
        ],
      ),
    );
  }

  Widget _buildStorySection() {
    return Container(
      height: 12.h,
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        itemCount: _moments.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildAddStoryButton();
          return _buildStoryItem(_moments[index - 1]);
        },
      ),
    );
  }

  Widget _buildAddStoryButton() {
    return Container(
      width: 15.w,
      margin: EdgeInsets.only(right: 2.w),
      child: Column(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(40),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1877F2), width: 2),
            ),
            child: const Icon(Icons.add, color: Color(0xFF1877F2)),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Add Story',
            style: GoogleFonts.inter(fontSize: 7.sp, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(Map<String, dynamic> moment) {
    return Container(
      width: 15.w,
      margin: EdgeInsets.only(right: 2.w),
      child: Column(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1877F2), width: 2),
              image: DecorationImage(
                image: NetworkImage(
                  moment['thumbnail_url'] as String? ??
                      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            moment['creator_name'] as String? ?? 'User',
            style: GoogleFonts.inter(fontSize: 7.sp, color: Colors.black87),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPostComposer() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.socialPostComposer),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(30),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: Colors.grey.withAlpha(60)),
                ),
                child: Text(
                  "What's on your mind?",
                  style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionsSection() {
    if (_activeElections.isEmpty) return const SizedBox();
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Elections',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 12.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _activeElections.take(5).length,
              itemBuilder: (context, index) =>
                  _buildElectionChip(_activeElections[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionChip(Map<String, dynamic> election) {
    return Container(
      width: 35.w,
      margin: EdgeInsets.only(right: 2.w),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2).withAlpha(15),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFF1877F2).withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            election['title'] as String? ?? 'Election',
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '${election['vote_count'] ?? 0} votes',
            style: GoogleFonts.inter(fontSize: 8.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> item) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    item['author_avatar'] as String? ??
                        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['author_name'] as String? ?? 'User',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatTime(
                          DateTime.tryParse(
                            item['created_at'] as String? ?? '',
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: Colors.grey),
              ],
            ),
          ),
          if (item['content'] != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Text(
                item['content'] as String,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.black87,
                ),
              ),
            ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Row(
              children: [
                Icon(Icons.thumb_up_outlined, size: 4.w, color: Colors.grey),
                SizedBox(width: 1.w),
                Text(
                  '${item['like_count'] ?? 0}',
                  style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey),
                ),
                SizedBox(width: 3.w),
                Icon(Icons.comment_outlined, size: 4.w, color: Colors.grey),
                SizedBox(width: 1.w),
                Text(
                  '${item['comment_count'] ?? 0}',
                  style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey),
                ),
                const Spacer(),
                Icon(Icons.share_outlined, size: 4.w, color: Colors.grey),
              ],
            ),
          ),
          SizedBox(height: 1.h),
        ],
      ),
    );
  }

  Widget _buildRecommendationSidebar() {
    if (_recommendationsStream == null) {
      return RecommendationSidebarWidget(
        recommendations: _currentRecommendations.map((r) => r.toMap()).toList(),
        onClose: () => setState(() => _isSidebarOpen = false),
      );
    }
    return StreamBuilder<List<FeedRecommendation>>(
      stream: _recommendationsStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _currentRecommendations = snapshot.data!;
        }
        return RecommendationSidebarWidget(
          recommendations: _currentRecommendations
              .map((r) => r.toMap())
              .toList(),
          onClose: () => setState(() => _isSidebarOpen = false),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', true),
          _buildNavItem(Icons.people_outline, 'Friends', false),
          _buildNavItem(Icons.ondemand_video_outlined, 'Watch', false),
          _buildNavItem(Icons.storefront_outlined, 'Marketplace', false),
          _buildNavItem(Icons.menu, 'Menu', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFF1877F2) : Colors.grey,
          size: 6.w,
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 7.sp,
            color: isActive ? const Color(0xFF1877F2) : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Just now';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}