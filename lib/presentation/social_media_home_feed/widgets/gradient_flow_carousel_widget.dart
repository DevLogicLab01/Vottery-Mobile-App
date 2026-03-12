import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../services/carousel_content_service.dart';
import '../../../theme/app_theme.dart' as theme;
import './accuracy_champion_card_widget.dart';
import './top_earner_card_widget.dart';
import './trending_topic_card_widget.dart';

/// Premium 2D Gradient Flow Carousel
/// Replaces 3D Liquid Horizon with smooth gradient backgrounds and glassmorphism
/// Features: animated gradients, haptic feedback, parallax, casino aesthetic
class GradientFlowCarouselWidget extends StatefulWidget {
  final List<Widget>? children;
  final CarouselContentType? contentType;
  final double cardHeight;
  final String? title;
  final Function(int)? onCardTap;
  final double cardWidth;
  final EdgeInsets cardMargin;

  const GradientFlowCarouselWidget({
    super.key,
    this.children,
    this.contentType,
    this.cardHeight = 200,
    this.title,
    this.onCardTap,
    this.cardWidth = 280,
    this.cardMargin = const EdgeInsets.only(right: 16),
  }) : assert(
         children != null || contentType != null,
         'Either children or contentType must be provided',
       );

  @override
  State<GradientFlowCarouselWidget> createState() =>
      _GradientFlowCarouselWidgetState();
}

class _GradientFlowCarouselWidgetState extends State<GradientFlowCarouselWidget>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _gradientController;
  late AnimationController _shimmerController;
  int _currentGradientIndex = 0;
  List<Map<String, dynamic>> _contentData = [];
  bool _isLoading = true;

  // Premium gradient palettes - casino/lottery aesthetic
  static const List<List<Color>> _gradientPalettes = [
    [Color(0xFFFFD700), Color(0xFFFF8C00)], // Gold → Orange
    [Color(0xFF00D2FF), Color(0xFF3A7BD5)], // Cyan → Blue
    [Color(0xFF7B2FF7), Color(0xFFFF006E)], // Purple → Pink
    [Color(0xFF00F5A0), Color(0xFF00D9F5)], // Mint → Cyan
    [Color(0xFFFF416C), Color(0xFFFF4B2B)], // Red → Orange
    [Color(0xFF4776E6), Color(0xFF8E54E9)], // Blue → Purple
  ];

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    if (widget.contentType != null) {
      _loadContent();
    } else {
      setState(() => _isLoading = false);
    }
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadContent() async {
    if (widget.contentType == null) return;
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> data = [];
      switch (widget.contentType!) {
        case CarouselContentType.trendingTopics:
          data = await CarouselContentService.fetchTrendingTopics();
          break;
        case CarouselContentType.topEarners:
          data = await CarouselContentService.fetchTopEarners();
          break;
        case CarouselContentType.accuracyChampions:
          data = await CarouselContentService.fetchAccuracyChampions();
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

  Widget _buildContentCard(Map<String, dynamic> data) {
    switch (widget.contentType!) {
      case CarouselContentType.trendingTopics:
        return TrendingTopicCardWidget(topic: data);
      case CarouselContentType.topEarners:
        return TopEarnerCardWidget(earner: data);
      case CarouselContentType.accuracyChampions:
        return AccuracyChampionCardWidget(champion: data);
      default:
        return Container();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _gradientController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final scrollOffset = _scrollController.offset;
      final cardWidth = widget.cardWidth + widget.cardMargin.right;
      final newIndex =
          (scrollOffset / cardWidth).floor() % _gradientPalettes.length;
      if (newIndex != _currentGradientIndex) {
        setState(() => _currentGradientIndex = newIndex);
        _gradientController.forward(from: 0);
      }
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
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: children.length,
              itemBuilder: (context, index) {
                return _buildFlowCard(children[index], index);
              },
            ),
          ),
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
          GestureDetector(
            onTap: () => HapticFeedback.selectionClick(),
            child: Text(
              'See All →',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: theme.AppThemeColors.electricGold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowCard(Widget child, int index) {
    final gradientIndex = index % _gradientPalettes.length;
    final gradient = _gradientPalettes[gradientIndex];

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onCardTap?.call(index);
      },
      child: RepaintBoundary(
        child: Container(
          width: widget.cardWidth,
          height: widget.cardHeight,
          margin: widget.cardMargin,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.95, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, scale, _) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.0),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withAlpha(90),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.0),
                    child: Stack(
                      children: [
                        // Glassmorphic overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withAlpha(40),
                                  Colors.white.withAlpha(10),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Shimmer highlight
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, _) {
                            return Positioned(
                              top: -widget.cardHeight,
                              left:
                                  -widget.cardWidth +
                                  (_shimmerController.value *
                                      widget.cardWidth *
                                      3),
                              child: Transform.rotate(
                                angle: 0.5,
                                child: Container(
                                  width: widget.cardWidth * 0.3,
                                  height: widget.cardHeight * 3,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withAlpha(0),
                                        Colors.white.withAlpha(30),
                                        Colors.white.withAlpha(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Content
                        Positioned.fill(child: child),
                        // Rim border
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24.0),
                              border: Border.all(
                                color: Colors.white.withAlpha(60),
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
