import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EngagementHotspotDetectionWidget extends StatefulWidget {
  const EngagementHotspotDetectionWidget({super.key});

  @override
  State<EngagementHotspotDetectionWidget> createState() =>
      _EngagementHotspotDetectionWidgetState();
}

class _EngagementHotspotDetectionWidgetState
    extends State<EngagementHotspotDetectionWidget> {
  final List<Map<String, dynamic>> _hotspots = [
    {
      'screen': 'Vote Casting',
      'zone': 'Submit Button Area',
      'click_density': 0.92,
      'avg_clicks': 847,
      'intensity': 'Hot',
      'color': Colors.red,
    },
    {
      'screen': 'Election Discovery',
      'zone': 'Featured Elections',
      'click_density': 0.78,
      'avg_clicks': 623,
      'intensity': 'Warm',
      'color': Colors.orange,
    },
    {
      'screen': 'Social Feed',
      'zone': 'Like/React Buttons',
      'click_density': 0.85,
      'avg_clicks': 712,
      'intensity': 'Hot',
      'color': Colors.red,
    },
    {
      'screen': 'User Profile',
      'zone': 'Settings Icon',
      'click_density': 0.34,
      'avg_clicks': 189,
      'intensity': 'Cool',
      'color': Colors.blue,
    },
  ];

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
              Icon(Icons.whatshot, color: theme.colorScheme.primary, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                'Engagement Hotspot Detection',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Density-based clustering of most-clicked areas',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          _buildHeatmapLegend(theme),
          SizedBox(height: 3.h),
          ..._hotspots.map((hotspot) {
            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: hotspot['color'].withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        hotspot['screen'],
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: hotspot['color'].withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          hotspot['intensity'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hotspot['color'],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Zone: ${hotspot['zone']}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Click Density',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${(hotspot['click_density'] * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  LinearProgressIndicator(
                    value: hotspot['click_density'],
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(hotspot['color']),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Avg Clicks: ${hotspot['avg_clicks']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Heatmap Color Legend',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(theme, 'Cold', Colors.blue),
              _buildLegendItem(theme, 'Cool', Colors.lightBlue),
              _buildLegendItem(theme, 'Warm', Colors.orange),
              _buildLegendItem(theme, 'Hot', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(ThemeData theme, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(height: 0.5.h),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
