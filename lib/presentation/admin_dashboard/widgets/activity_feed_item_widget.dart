import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Activity feed item widget showing recent system events
/// Displays real-time updates with appropriate icons and timestamps
class ActivityFeedItemWidget extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityFeedItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              color: _getActivityColor(
                activity['type'] as String,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: _getActivityIcon(activity['type'] as String),
              color: _getActivityColor(activity['type'] as String),
              size: 20,
            ),
          ),
          SizedBox(width: 3.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5),
                Text(
                  activity['description'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5),
                Text(
                  activity['time'] as String,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'user':
        return 'person_add';
      case 'vote':
        return 'how_to_vote';
      case 'alert':
        return 'warning';
      case 'system':
        return 'settings';
      default:
        return 'notifications';
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'user':
        return const Color(0xFF3B82F6);
      case 'vote':
        return const Color(0xFF10B981);
      case 'alert':
        return const Color(0xFFF59E0B);
      case 'system':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}
