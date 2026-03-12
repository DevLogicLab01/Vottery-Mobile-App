import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class IncidentSummaryCardWidget extends StatefulWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final bool isPulsing;

  const IncidentSummaryCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.isPulsing = false,
  });

  @override
  State<IncidentSummaryCardWidget> createState() =>
      _IncidentSummaryCardWidgetState();
}

class _IncidentSummaryCardWidgetState extends State<IncidentSummaryCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(IncidentSummaryCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !oldWidget.isPulsing) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && oldWidget.isPulsing) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: widget.color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: widget.color.withAlpha(77), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              widget.isPulsing
                  ? ScaleTransition(
                      scale: _animation,
                      child: Icon(widget.icon, size: 6.w, color: widget.color),
                    )
                  : Icon(widget.icon, size: 6.w, color: widget.color),
              Spacer(),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            widget.value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: widget.color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
