import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../services/carousel_content_service.dart';
import '../../../services/carousel_interaction_logger.dart';
import '../../../theme/app_theme.dart' as theme;
import './creator_spotlight_card_widget.dart';
import './jolt_card_widget.dart';
import './moment_card_widget.dart';
import './recommended_group_compact_card.dart';

/// Premium 2D Horizontal Snap Carousel
/// Replaces 3D Kinetic Spindle with sharp, beautiful 2D PageView
/// Features: haptic feedback, parallax, scale transforms, rim glow, casino aesthetic
class HorizontalSnapCarouselWidget extends StatefulWidget {
  final List<Widget>? children;
  final CarouselContentType? contentType;
  final double viewportFraction;
  final double cardHeight;
  final EdgeInsets cardPadding;
  final bool enableHapticFeedback;
  final Function(int)? onPageChanged;
  final String? title;

  const HorizontalSnapCarouselWidget({
    super.key,
    this.children,
    this.contentType,
    this.viewportFraction = 0.82,
    this.cardHeight = 320,
    this.cardPadding = const EdgeInsets.symmetric(horizontal: 8.0),
    this.enableHapticFeedback = true,
    this.onPageChanged,
    this.title,
  }) : assert(
         children != null || contentType != null,
         'Either children or contentType must be provided',
       );

  @override
  State<HorizontalSnapCarouselWidget> createState() =>
      _HorizontalSnapCarouselWidgetState();
}

class _HorizontalSnapCarouselWidgetState
    extends State<HorizontalSnapCarouselWidget>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _pulseController;
  int _currentPage = 0;
  double _currentPageValue = 0.0;
  List<Map<String, dynamic>> _contentData = [];
  bool _isLoading = true;
  DateTime? _viewStartTime;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: 0,
    );
    _pageController.addListener(_onPageScroll);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (widget.contentType != null) {
      _loadContent();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadContent() async {
    if (widget.contentType == null) return;
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> data = [];
      switch (widget.contentType!) {
        case CarouselContentType.jolts:
          data = await CarouselContentService.fetchJolts();
          break;
        case CarouselContentType.moments:
          data = await CarouselContentService.fetchMoments();
          break;
        case CarouselContentType.creatorSpotlights:
          data = await CarouselContentService.fetchCreatorSpotlights();
          break;
        case CarouselContentType.recommendedGroups:
          data = await CarouselContentService.fetchRecommendedGroups();
          break;
        default:
          break;
      }
      if (mounted) {
        setState(() {
          _contentData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    if (_pageController.hasClients && mounted) {
      setState(() {
        _currentPageValue = _pageController.page ?? 0.0;
      });
    }
  }

  void _onPageChanged(int page) {
    if (_currentPage != page) {
      _logSwipe(_currentPage, page);
      setState(() {
        _currentPage = page;
        _viewStartTime = DateTime.now();
      });
      if (widget.enableHapticFeedback) HapticFeedback.mediumImpact();
      widget.onPageChanged?.call(page);
    }
  }

  void _logSwipe(int fromPage, int toPage) {
    final duration = _viewStartTime != null
        ? DateTime.now().difference(_viewStartTime!).inMilliseconds / 1000.0
        : 1.0;
    final direction = toPage > fromPage ? 'swipe_left' : 'swipe_right';
    final itemId = fromPage < _contentData.length
        ? (_contentData[fromPage]['id'] ?? _contentData[fromPage]['jolt_id'] ?? 'item_$fromPage').toString()
        : 'item_$fromPage';
    CarouselInteractionLogger.instance.logSwipe(
      itemId: itemId,
      interactionType: direction,
      viewDurationSeconds: duration,
    );
  }

  Widget _buildContentCard(Map<String, dynamic> data) {
    switch (widget.contentType!) {
      case CarouselContentType.jolts:
        return JoltCardWidget(jolt: data, onTap: () {});
      case CarouselContentType.moments:
        return MomentCardWidget(moment: data, onTap: () {});
      case CarouselContentType.creatorSpotlights:
        return CreatorSpotlightCardWidget(spotlight: data);
      case CarouselContentType.recommendedGroups:
        return RecommendedGroupCompactCard(group: data);
      default:
        return Container();
    }
  }

  List<Widget> get _displayChildren {
    if (widget.children != null) return widget.children!;
    if (_isLoading) return [];
    return _contentData.map((d) => _buildContentCard(d)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final children = _displayChildren;
    if (children.isEmpty && !_isLoading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) _buildHeader(),
        if (_isLoading)
          SizedBox(
            height: widget.cardHeight,
            child: Center(
              child: CircularProgressIndicator(
                color: theme.AppThemeColors.electricGold,
                strokeWidth: 2,
              ),
            ),
          )
        else
          SizedBox(
            height: widget.cardHeight,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: children.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildCarouselCard(children[index], index);
              },
            ),
          ),
        if (!_isLoading && children.isNotEmpty) ...[
          SizedBox(height: 1.h),
          _buildPageIndicator(children.length),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title!,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
                letterSpacing: -0.3,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.AppThemeColors.electricGold,
                      theme.AppThemeColors.electricGold.withAlpha(
                        (180 + (_pulseController.value * 75)).toInt(),
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: theme.AppThemeColors.electricGold.withAlpha(
                        (80 + (_pulseController.value * 80).toInt()),
                      ),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  'LIVE',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 1.2,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(Widget child, int index) {
    final double pageOffset = _currentPageValue - index;
    final double absOffset = pageOffset.abs();
    final double scale = (1.0 - (absOffset * 0.12)).clamp(0.88, 1.0);
    final double opacity = (1.0 - (absOffset * 0.35)).clamp(0.65, 1.0);
    final double parallaxOffset = pageOffset * 25;
    final bool isCenter = absOffset < 0.5;

    return RepaintBoundary(
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Padding(
            padding: widget.cardPadding,
            child: Transform.translate(
              offset: Offset(parallaxOffset, 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: isCenter
                      ? [
                          BoxShadow(
                            color: theme.AppThemeColors.electricGold.withAlpha(
                              90,
                            ),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: Stack(
                    children: [
                      child,
                      // Center card CTA overlay
                      if (isCenter &&
                          widget.contentType == CarouselContentType.jolts)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _buildWatchNowCTA(),
                        ),
                      // Rim light border for center card
                      if (isCenter)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24.0),
                              border: Border.all(
                                color: theme.AppThemeColors.electricGold
                                    .withAlpha(120),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatchNowCTA() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withAlpha(200)],
        ),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.2.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.AppThemeColors.electricGold,
                const Color(0xFFFF8C00),
              ],
            ),
            borderRadius: BorderRadius.circular(30.0),
            boxShadow: [
              BoxShadow(
                color: theme.AppThemeColors.electricGold.withAlpha(100),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.black, size: 5.w),
              SizedBox(width: 1.w),
              Text(
                'Watch Now',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int count) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count > 8 ? 8 : count, (index) {
          final isActive = index == _currentPage % (count > 8 ? 8 : count);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isActive ? 5.w : 1.5.w,
            height: 1.5.w,
            margin: EdgeInsets.symmetric(horizontal: 0.5.w),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.AppThemeColors.electricGold
                  : theme.AppThemeColors.electricGold.withAlpha(80),
              borderRadius: BorderRadius.circular(10.0),
            ),
          );
        }),
      ),
    );
  }
}
