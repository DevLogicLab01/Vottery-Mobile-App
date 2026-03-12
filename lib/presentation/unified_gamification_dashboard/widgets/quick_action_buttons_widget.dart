import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Quick Action Buttons Widget
/// Provides 1-tap navigation to Redeem VP, Join Pool, Start Quest, View Achievements
class QuickActionButtonsWidget extends StatelessWidget {
  final VoidCallback onRedeemVP;
  final VoidCallback onJoinPool;
  final VoidCallback onStartQuest;
  final VoidCallback onViewAchievements;

  const QuickActionButtonsWidget({
    super.key,
    required this.onRedeemVP,
    required this.onJoinPool,
    required this.onStartQuest,
    required this.onViewAchievements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            theme,
            'Redeem VP',
            'redeem',
            Colors.purple,
            onRedeemVP,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildActionButton(
            context,
            theme,
            'Join Pool',
            'psychology',
            Colors.blue,
            onJoinPool,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildActionButton(
            context,
            theme,
            'Start Quest',
            'assignment',
            Colors.orange,
            onStartQuest,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildActionButton(
            context,
            theme,
            'Achievements',
            'emoji_events',
            Colors.green,
            onViewAchievements,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ThemeData theme,
    String label,
    String iconName,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            CustomIconWidget(iconName: iconName, color: color, size: 28),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
