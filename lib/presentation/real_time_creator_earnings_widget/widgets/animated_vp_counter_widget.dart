import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AnimatedVpCounterWidget extends StatefulWidget {
  final int vpBalance;
  final double usdBalance;

  const AnimatedVpCounterWidget({
    super.key,
    required this.vpBalance,
    required this.usdBalance,
  });

  @override
  State<AnimatedVpCounterWidget> createState() =>
      _AnimatedVpCounterWidgetState();
}

class _AnimatedVpCounterWidgetState extends State<AnimatedVpCounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousVp = 0;

  @override
  void initState() {
    super.initState();
    _previousVp = widget.vpBalance;
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(AnimatedVpCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vpBalance != widget.vpBalance) {
      _previousVp = oldWidget.vpBalance;
      _controller.reset();
      _controller.forward();
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
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withAlpha(77),
            blurRadius: 12.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'account_balance_wallet',
                size: 6.w,
                color: Colors.white,
              ),
              SizedBox(width: 2.w),
              Text(
                'Available Balance',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(230),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final currentVp =
                  (_previousVp +
                          (_animation.value * (widget.vpBalance - _previousVp)))
                      .round();
              return Text(
                '$currentVp VP',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          SizedBox(height: 1.h),
          Text(
            '\$${widget.usdBalance.toStringAsFixed(2)} USD',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha(230),
            ),
          ),
          SizedBox(height: 2.h),
          LinearProgressIndicator(
            value: widget.usdBalance >= 50.0 ? 1.0 : widget.usdBalance / 50.0,
            backgroundColor: Colors.white.withAlpha(77),
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.usdBalance >= 50.0
                  ? AppTheme.accentLight
                  : AppTheme.vibrantYellow,
            ),
            minHeight: 6.0,
            borderRadius: BorderRadius.circular(3.0),
          ),
          SizedBox(height: 1.h),
          Text(
            widget.usdBalance >= 50.0
                ? 'Ready for withdrawal'
                : 'Minimum \$50.00 required for withdrawal',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }
}
