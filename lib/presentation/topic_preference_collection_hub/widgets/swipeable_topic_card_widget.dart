import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SwipeableTopicCardWidget extends StatefulWidget {
  final Map<String, dynamic> category;
  final Function(String direction, double velocity, int dwellTimeMs) onSwipe;

  const SwipeableTopicCardWidget({
    super.key,
    required this.category,
    required this.onSwipe,
  });

  @override
  State<SwipeableTopicCardWidget> createState() =>
      _SwipeableTopicCardWidgetState();
}

class _SwipeableTopicCardWidgetState extends State<SwipeableTopicCardWidget>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  DateTime? _cardViewStartTime;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _cardViewStartTime = DateTime.now();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _cardViewStartTime = DateTime.now();
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final dwellTime = _cardViewStartTime != null
        ? DateTime.now().difference(_cardViewStartTime!).inMilliseconds
        : 0;
    final velocity = details.velocity.pixelsPerSecond.dx.abs();

    String? swipeDirection;

    if (_dragOffset.dx.abs() > 100) {
      swipeDirection = _dragOffset.dx > 0 ? 'right' : 'left';
    } else if (_dragOffset.dy < -100) {
      swipeDirection = 'up';
    } else if (_dragOffset.dy > 100) {
      swipeDirection = 'down';
    }

    if (swipeDirection != null) {
      widget.onSwipe(swipeDirection, velocity, dwellTime);
    }

    setState(() {
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rotation = _dragOffset.dx / 1000;
    final opacity = 1.0 - (_dragOffset.dx.abs() / 500).clamp(0.0, 0.5);

    return GestureDetector(
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: opacity,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: Image.network(
                        widget.category['image_url'] ??
                            'https://images.unsplash.com/photo-1557683316-973673baf926',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            child: Icon(
                              Icons.image,
                              size: 20.w,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.all(6.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.category['display_name'] ?? 'Category',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              widget.category['description'] ??
                                  'Explore this category',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Swipe Direction Indicators
                    if (_isDragging && _dragOffset.dx > 50)
                      Positioned(
                        top: 10.h,
                        right: 4.w,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 12.w,
                          ),
                        ),
                      ),

                    if (_isDragging && _dragOffset.dx < -50)
                      Positioned(
                        top: 10.h,
                        left: 4.w,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 12.w,
                          ),
                        ),
                      ),

                    if (_isDragging && _dragOffset.dy < -50)
                      Positioned(
                        top: 4.h,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 12.w,
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
    );
  }
}
