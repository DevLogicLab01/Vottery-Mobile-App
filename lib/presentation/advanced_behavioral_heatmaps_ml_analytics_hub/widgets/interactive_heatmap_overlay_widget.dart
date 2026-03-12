import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class InteractiveHeatmapOverlayWidget extends StatelessWidget {
  const InteractiveHeatmapOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers, color: theme.colorScheme.primary, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                'Interactive Heatmap Overlay',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Container(
            height: 30.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.3),
                  Colors.green.withValues(alpha: 0.3),
                  Colors.yellow.withValues(alpha: 0.3),
                  Colors.orange.withValues(alpha: 0.3),
                  Colors.red.withValues(alpha: 0.3),
                ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Text(
                'Real-time Heatmap Visualization',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                theme,
                'Session Replay',
                Icons.play_circle_outline,
              ),
              _buildActionButton(theme, 'A/B Test', Icons.compare_arrows),
              _buildActionButton(theme, 'Export', Icons.download),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 6.w),
        ),
        SizedBox(height: 1.h),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
