import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../services/carousel_content_service.dart';
import '../../../theme/app_theme.dart' as theme;
import './creator_service_card_widget.dart';
import './recommended_election_card_widget.dart';
import './recommended_group_card_widget.dart';

/// Premium 2D Vertical Card Stack
/// Replaces 3D Isometric Deck-Sifter with beautiful swipeable card stack
/// Features: haptic feedback, swipe gestures, stacked depth illusion, casino aesthetic
class VerticalCardStackWidget extends StatefulWidget {
  final List<Widget>? children;
  final CarouselContentType? contentType;
  final double cardWidth;
  final double cardHeight;
  final Function(int)? onSwipeRight;
  final Function(int)? onSwipeLeft;
  final String? title;

  const VerticalCardStackWidget({
    super.key,
    this.children,
    this.contentType,
    this.cardWidth = 0.9,
    this.cardHeight = 480,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.title,
  }) : assert(
         children != null || contentType != null,
         'Either children or contentType must be provided',
       );

  @override
  State<VerticalCardStackWidget> createState() =>
      _VerticalCardStackWidgetState();
}

class _VerticalCardStackWidgetState extends State<VerticalCardStackWidget>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _contentData = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  late AnimationController _swipeController;
  late AnimationController _stackController;
  late Animation<double> _stackAnimation;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _stackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _stackAnimation = CurvedAnimation(
      parent: _stackController,
      curve: Curves.easeOutBack,
    );
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
        case CarouselContentType.recommendedGroups:
          data = await CarouselContentService.fetchRecommendedGroups();
          break;
        case CarouselContentType.recommendedElections:
          data = await CarouselContentService.fetchRecommendedElections();
          break;
        case CarouselContentType.creatorServices:
          data = await CarouselContentService.fetchCreatorServices();
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
    _swipeController.dispose();
    _stackController.dispose();
    super.dispose();
  }

  void _handleSwipeRight() {
    HapticFeedback.mediumImpact();
    _advanceCard();
    widget.onSwipeRight?.call(_currentIndex);
  }

  void _handleSwipeLeft() {
    HapticFeedback.lightImpact();
    _advanceCard();
    widget.onSwipeLeft?.call(_currentIndex);
  }

  void _advanceCard() {
    if (_contentData.isEmpty) return;
    _stackController.forward(from: 0);
    setState(() {
      _currentIndex = (_currentIndex + 1) % _contentData.length;
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
  }

  Widget _buildContentCard(Map<String, dynamic> data) {
    switch (widget.contentType!) {
      case CarouselContentType.recommendedGroups:
        return RecommendedGroupCardWidget(
          group: data,
          onSwipeRight: _handleSwipeRight,
          onSwipeLeft: _handleSwipeLeft,
        );
      case CarouselContentType.recommendedElections:
        return RecommendedElectionCardWidget(
          election: data,
          onSwipeRight: _handleSwipeRight,
          onSwipeLeft: _handleSwipeLeft,
        );
      case CarouselContentType.creatorServices:
        return CreatorServiceCardWidget(
          service: data,
          onSwipeRight: _handleSwipeRight,
          onSwipeLeft: _handleSwipeLeft,
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.cardHeight,
        child: Center(
          child: CircularProgressIndicator(
            color: theme.AppThemeColors.electricGold,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_contentData.isEmpty) return const SizedBox.shrink();

    final visibleCount = _contentData.length > 3 ? 3 : _contentData.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSwipeHint(),
        SizedBox(
          height: widget.cardHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Background stacked cards (depth illusion)
              for (int i = visibleCount - 1; i >= 1; i--)
                _buildBackgroundCard(i),
              // Top draggable card
              _buildTopCard(),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        _buildCardCounter(),
      ],
    );
  }

  Widget _buildSwipeHint() {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSwipeIndicator(
            Icons.arrow_back_ios_rounded,
            'Skip',
            const Color(0xFFFF4757),
          ),
          SizedBox(width: 4.w),
          Container(width: 1, height: 3.h, color: Colors.grey.withAlpha(80)),
          SizedBox(width: 4.w),
          _buildSwipeIndicator(
            Icons.arrow_forward_ios_rounded,
            _getActionLabel(),
            const Color(0xFF2ED573),
          ),
        ],
      ),
    );
  }

  String _getActionLabel() {
    switch (widget.contentType) {
      case CarouselContentType.recommendedGroups:
        return 'Join';
      case CarouselContentType.recommendedElections:
        return 'Vote';
      default:
        return 'Connect';
    }
  }

  Widget _buildSwipeIndicator(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 3.5.w),
        SizedBox(width: 1.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundCard(int stackIndex) {
    final cardIndex = (_currentIndex + stackIndex) % _contentData.length;
    final offsetY = stackIndex * 12.0;
    final offsetX = stackIndex * 6.0;
    final scale = 1.0 - (stackIndex * 0.04);
    final opacity = 1.0 - (stackIndex * 0.2);

    return AnimatedBuilder(
      animation: _stackAnimation,
      builder: (context, child) {
        final animOffset = stackIndex == 1
            ? _stackAnimation.value * 12.0
            : offsetY;
        return Transform.translate(
          offset: Offset(offsetX, animOffset),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: MediaQuery.of(context).size.width * widget.cardWidth,
                height: widget.cardHeight - 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.0),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: _buildContentCard(_contentData[cardIndex]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopCard() {
    if (_contentData.isEmpty) return const SizedBox.shrink();
    final data = _contentData[_currentIndex];
    final swipeProgress =
        _dragOffset.dx / (MediaQuery.of(context).size.width * 0.5);
    final isSwipingRight = _dragOffset.dx > 0;

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _dragOffset += details.delta;
          _isDragging = true;
        });
      },
      onPanEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond.dx;
        if (_dragOffset.dx > 80 || velocity > 600) {
          _handleSwipeRight();
        } else if (_dragOffset.dx < -80 || velocity < -600) {
          _handleSwipeLeft();
        } else {
          setState(() {
            _dragOffset = Offset.zero;
            _isDragging = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: _isDragging
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        transform: Matrix4.identity()
          ..translate(_dragOffset.dx, _dragOffset.dy * 0.3)
          ..rotateZ(_dragOffset.dx / 800),
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * widget.cardWidth,
              height: widget.cardHeight - 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: theme.AppThemeColors.electricGold.withAlpha(60),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.0),
                child: _buildContentCard(data),
              ),
            ),
            // Swipe direction overlay
            if (_isDragging && swipeProgress.abs() > 0.15)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.0),
                      color: isSwipingRight
                          ? const Color(0xFF2ED573).withAlpha(
                              (swipeProgress.abs() * 120).toInt().clamp(0, 120),
                            )
                          : const Color(0xFFFF4757).withAlpha(
                              (swipeProgress.abs() * 120).toInt().clamp(0, 120),
                            ),
                    ),
                    child: Center(
                      child: Icon(
                        isSwipingRight
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: Colors.white,
                        size: 15.w,
                      ),
                    ),
                  ),
                ),
              ),
            // Rim light border
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: theme.AppThemeColors.electricGold.withAlpha(100),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardCounter() {
    if (_contentData.isEmpty) return const SizedBox.shrink();
    return Center(
      child: Text(
        '${_currentIndex + 1} / ${_contentData.length}',
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
        ),
      ),
    );
  }
}
