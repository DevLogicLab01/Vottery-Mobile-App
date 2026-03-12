import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class ActionPlanTimelineWidget extends StatefulWidget {
  final List<Map<String, dynamic>> actionPlan;

  const ActionPlanTimelineWidget({super.key, required this.actionPlan});

  @override
  State<ActionPlanTimelineWidget> createState() =>
      _ActionPlanTimelineWidgetState();
}

class _ActionPlanTimelineWidgetState extends State<ActionPlanTimelineWidget> {
  late List<bool> _completed;

  @override
  void initState() {
    super.initState();
    _completed = widget.actionPlan
        .map((item) => item['completed'] as bool? ?? false)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '30-Day Action Plan',
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.5.h),
        ...List.generate(widget.actionPlan.length, (index) {
          final item = widget.actionPlan[index];
          final week = item['week'] as int? ?? (index + 1);
          final milestone = item['milestone'] as String? ?? '';
          final isCompleted = _completed[index];
          final isLast = index == widget.actionPlan.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _completed[index] = !_completed[index];
                      });
                    },
                    child: Container(
                      width: 7.w,
                      height: 7.w,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : theme.colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? Icon(Icons.check, color: Colors.white, size: 4.w)
                          : Center(
                              child: Text(
                                '$week',
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 5.h,
                      color: theme.colorScheme.outlineVariant,
                    ),
                ],
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week $week',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.vibrantYellow,
                        ),
                      ),
                      Text(
                        milestone,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: isCompleted
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
