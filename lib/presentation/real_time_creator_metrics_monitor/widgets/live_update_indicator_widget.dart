import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class LiveUpdateIndicatorWidget extends StatefulWidget {
  final bool isConnected;
  final int updateCount;
  const LiveUpdateIndicatorWidget({
    super.key,
    required this.isConnected,
    required this.updateCount,
  });
  @override
  State<LiveUpdateIndicatorWidget> createState() =>
      _LiveUpdateIndicatorWidgetState();
}

class _LiveUpdateIndicatorWidgetState extends State<LiveUpdateIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.isConnected) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(LiveUpdateIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isConnected) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: widget.isConnected
            ? const Color(0xFF10B981).withAlpha(26)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: widget.isConnected
              ? const Color(0xFF10B981).withAlpha(77)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) => Opacity(
              opacity: widget.isConnected ? _animation.value : 0.4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.isConnected
                      ? const Color(0xFF10B981)
                      : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SizedBox(width: 1.w),
          Text(
            widget.isConnected ? 'LIVE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: widget.isConnected ? const Color(0xFF10B981) : Colors.grey,
            ),
          ),
          if (widget.updateCount > 0) ...[
            SizedBox(width: 1.w),
            Text(
              '${widget.updateCount} updates',
              style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}
