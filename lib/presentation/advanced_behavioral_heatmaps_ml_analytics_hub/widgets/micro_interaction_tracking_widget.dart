import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MicroInteractionTrackingWidget extends StatefulWidget {
  const MicroInteractionTrackingWidget({super.key});

  @override
  State<MicroInteractionTrackingWidget> createState() =>
      _MicroInteractionTrackingWidgetState();
}

class _MicroInteractionTrackingWidgetState
    extends State<MicroInteractionTrackingWidget> {
  final List<Map<String, dynamic>> _interactions = [
    {
      'type': 'Tap',
      'coordinates': '(245.3, 512.7)',
      'element': 'Vote Button',
      'dwell_time': 1.2,
      'pressure': 0.75,
      'timestamp': '2 min ago',
    },
    {
      'type': 'Scroll',
      'velocity': '420 px/s',
      'direction': 'Vertical',
      'distance': '1250 px',
      'duration': 2.8,
      'timestamp': '5 min ago',
    },
    {
      'type': 'Swipe',
      'gesture': 'Left',
      'speed': '680 px/s',
      'element': 'Election Card',
      'completion': 0.92,
      'timestamp': '8 min ago',
    },
    {
      'type': 'Long Press',
      'coordinates': '(180.5, 320.1)',
      'element': 'Profile Avatar',
      'duration': 1.5,
      'pressure': 0.82,
      'timestamp': '12 min ago',
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
              Icon(
                Icons.touch_app,
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Micro-Interaction Tracking',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Real-time gesture and interaction analysis',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          ..._interactions.map((interaction) {
            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getInteractionIcon(interaction['type']),
                            color: theme.colorScheme.primary,
                            size: 5.w,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            interaction['type'],
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        interaction['timestamp'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  if (interaction['coordinates'] != null)
                    _buildDetailRow(
                      theme,
                      'Coordinates',
                      interaction['coordinates'],
                    ),
                  if (interaction['element'] != null)
                    _buildDetailRow(theme, 'Element', interaction['element']),
                  if (interaction['dwell_time'] != null)
                    _buildDetailRow(
                      theme,
                      'Dwell Time',
                      '${interaction['dwell_time']}s',
                    ),
                  if (interaction['pressure'] != null)
                    _buildDetailRow(
                      theme,
                      'Pressure',
                      '${(interaction['pressure'] * 100).toStringAsFixed(0)}%',
                    ),
                  if (interaction['velocity'] != null)
                    _buildDetailRow(theme, 'Velocity', interaction['velocity']),
                  if (interaction['gesture'] != null)
                    _buildDetailRow(theme, 'Gesture', interaction['gesture']),
                  if (interaction['duration'] != null)
                    _buildDetailRow(
                      theme,
                      'Duration',
                      '${interaction['duration']}s',
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getInteractionIcon(String type) {
    switch (type) {
      case 'Tap':
        return Icons.touch_app;
      case 'Scroll':
        return Icons.swap_vert;
      case 'Swipe':
        return Icons.swipe;
      case 'Long Press':
        return Icons.touch_app_outlined;
      default:
        return Icons.touch_app;
    }
  }
}
