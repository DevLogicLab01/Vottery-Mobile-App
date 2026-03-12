import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/jolts_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/double_tap_heart_animation_widget.dart';
import './widgets/jolt_action_panel_widget.dart';
import './widgets/jolt_comment_bottom_sheet_widget.dart';
import './widgets/jolt_creator_overlay_widget.dart';

/// Jolts Video Feed - TikTok-style vertical video experience
/// Implements swipeable interface with social engagement and VP rewards
class JoltsVideoFeed extends StatefulWidget {
  const JoltsVideoFeed({super.key});

  @override
  State<JoltsVideoFeed> createState() => _JoltsVideoFeedState();
}

class _JoltsVideoFeedState extends State<JoltsVideoFeed> {
  final JoltsService _joltsService = JoltsService.instance;
  final VPService _vpService = VPService.instance;
  final AuthService _authService = AuthService.instance;
  final PageController _pageController = PageController();

  List<Map<String, dynamic>> _jolts = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final Map<int, VideoPlayerController?> _controllers = {};
  final Map<int, bool> _isLiked = {};
  bool _showHeartAnimation = false;

  @override
  void initState() {
    super.initState();
    _loadJolts();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var controller in _controllers.values) {
      controller?.dispose();
    }
    _controllers.clear();
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentIndex) {
      setState(() {
        _pauseCurrentVideo();
        _currentIndex = page;
        _playCurrentVideo();
        _incrementViewCount();
      });

      // Load more when near end
      if (_currentIndex >= _jolts.length - 3 && !_isLoadingMore) {
        _loadMoreJolts();
      }
    }
  }

  Future<void> _loadJolts() async {
    setState(() => _isLoading = true);

    try {
      final jolts = await _joltsService.getJoltsFeed(limit: 20);
      setState(() {
        _jolts = jolts;
        _isLoading = false;
      });

      if (_jolts.isNotEmpty) {
        _initializeVideo(0);
        _preloadNextVideos();
      }
    } catch (e) {
      debugPrint('Load jolts error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreJolts() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreJolts = await _joltsService.getJoltsFeed(limit: 10);
      setState(() {
        _jolts.addAll(moreJolts);
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Load more jolts error: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _initializeVideo(int index) async {
    if (index >= _jolts.length) return;

    final videoUrl = _jolts[index]['video_url'] as String?;
    if (videoUrl == null) return;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();
      controller.setLooping(true);

      setState(() {
        _controllers[index] = controller;
      });

      if (index == _currentIndex) {
        controller.play();
      }
    } catch (e) {
      debugPrint('Initialize video error: $e');
    }
  }

  void _preloadNextVideos() {
    for (
      int i = _currentIndex + 1;
      i <= _currentIndex + 2 && i < _jolts.length;
      i++
    ) {
      if (!_controllers.containsKey(i)) {
        _initializeVideo(i);
      }
    }
  }

  void _playCurrentVideo() {
    _controllers[_currentIndex]?.play();
  }

  void _pauseCurrentVideo() {
    _controllers[_currentIndex]?.pause();
  }

  void _togglePlayPause() {
    final controller = _controllers[_currentIndex];
    if (controller == null) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _incrementViewCount() {
    if (_currentIndex < _jolts.length) {
      final joltId = _jolts[_currentIndex]['id'] as String;
      // Track view and award VP (2 VP for viewing)
      _joltsService.trackJoltView(joltId);
    }
  }

  Future<void> _handleDoubleTapLike() async {
    if (_currentIndex >= _jolts.length) return;

    final joltId = _jolts[_currentIndex]['id'] as String;
    final success = await _joltsService.likeJolt(joltId);

    if (success) {
      setState(() {
        _isLiked[_currentIndex] = true;
        _showHeartAnimation = true;
        _jolts[_currentIndex]['like_count'] =
            (_jolts[_currentIndex]['like_count'] as int? ?? 0) + 1;
      });

      await _vpService.awardSocialVP('jolt_like', joltId);

      // Hide animation after 1 second
      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() => _showHeartAnimation = false);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❤️ Liked! +5 VP earned'),
            backgroundColor: AppTheme.accentLight,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleLike() async {
    if (_currentIndex >= _jolts.length) return;

    final joltId = _jolts[_currentIndex]['id'] as String;
    final isCurrentlyLiked = _isLiked[_currentIndex] ?? false;

    if (!isCurrentlyLiked) {
      setState(() {
        _isLiked[_currentIndex] = true;
        _jolts[_currentIndex]['like_count'] =
            (_jolts[_currentIndex]['like_count'] ?? 0) + 1;
        _showHeartAnimation = true;
      });

      await _joltsService.likeJolt(joltId);
      // Award VP for voting/liking (5 VP)
      await _joltsService.awardJoltsVP(joltId: joltId, earningType: 'voting');

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _showHeartAnimation = false);
        }
      });
    }
  }

  void _showComments() {
    if (_currentIndex >= _jolts.length) return;

    _pauseCurrentVideo();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JoltCommentBottomSheetWidget(
        jolt: _jolts[_currentIndex],
        onCommentAdded: () async {
          final joltId = _jolts[_currentIndex]['id'] as String;
          await _vpService.awardSocialVP('jolt_comment', joltId);
          setState(() {
            _jolts[_currentIndex]['comment_count'] =
                (_jolts[_currentIndex]['comment_count'] as int? ?? 0) + 1;
          });
        },
      ),
    ).whenComplete(() => _playCurrentVideo());
  }

  Future<void> _handleShare() async {
    if (_currentIndex >= _jolts.length) return;

    final joltId = _jolts[_currentIndex]['id'] as String;

    // Award VP for sharing (10 VP)
    await _joltsService.awardJoltsVP(joltId: joltId, earningType: 'sharing');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jolt shared! +10 VP earned'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToCreatorProfile() {
    if (_currentIndex >= _jolts.length) return;

    final creator = _jolts[_currentIndex]['creator'] as Map<String, dynamic>?;
    if (creator == null) return;

    Navigator.pushNamed(
      context,
      AppRoutes.userProfile,
      arguments: creator['id'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'JoltsVideoFeed',
      onRetry: _loadJolts,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _jolts.isEmpty
            ? NoDataEmptyState(
                title: 'No Jolts',
                description: 'Discover short-form video content from creators.',
                onRefresh: _loadJolts,
              )
            : PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: _jolts.length,
                itemBuilder: (context, index) {
                  final jolt = _jolts[index];
                  final controller = _controllers[index];

                  return GestureDetector(
                    onTap: _togglePlayPause,
                    onDoubleTap: _handleDoubleTapLike,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Video Player
                        if (controller != null &&
                            controller.value.isInitialized)
                          Center(
                            child: AspectRatio(
                              aspectRatio: controller.value.aspectRatio,
                              child: VideoPlayer(controller),
                            ),
                          )
                        else
                          CustomImageWidget(
                            imageUrl:
                                jolt['thumbnail_url'] as String? ??
                                'https://images.pexels.com/photos/1550337/pexels-photo-1550337.jpeg',
                            fit: BoxFit.cover,
                            semanticLabel: 'Jolt video thumbnail',
                          ),

                        // Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(128),
                              ],
                              stops: [0.6, 1.0],
                            ),
                          ),
                        ),

                        // Double Tap Heart Animation
                        if (_showHeartAnimation && index == _currentIndex)
                          DoubleTapHeartAnimationWidget(),

                        // Right-side Action Panel
                        Positioned(
                          right: 3.w,
                          bottom: 20.h,
                          child: JoltActionPanelWidget(
                            likeCount: jolt['like_count'] as int? ?? 0,
                            commentCount: jolt['comment_count'] as int? ?? 0,
                            shareCount: jolt['share_count'] as int? ?? 0,
                            isLiked: _isLiked[index] ?? false,
                            onLike: _handleLike,
                            onComment: _showComments,
                            onShare: _handleShare,
                            onCreatorTap: _navigateToCreatorProfile,
                            creatorAvatarUrl:
                                (jolt['creator']
                                        as Map<String, dynamic>?)?['avatar_url']
                                    as String?,
                          ),
                        ),

                        // Bottom Creator Overlay
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: JoltCreatorOverlayWidget(
                            jolt: jolt,
                            onFollowTap: () {},
                          ),
                        ),

                        // Play/Pause Indicator
                        if (controller != null && !controller.value.isPlaying)
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(77),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                size: 12.w,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}