import 'package:flutter/material.dart'
    show
        StatelessWidget,
        Widget,
        BuildContext,
        Container,
        BoxDecoration,
        BorderRadius,
        Border,
        EdgeInsets,
        Row,
        Column,
        Expanded,
        SizedBox,
        Text,
        Theme,
        Color,
        CrossAxisAlignment,
        FontWeight,
        BoxShape;
import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// System status indicator widget showing health metrics
/// Displays real-time system health with visual indicators
class SystemStatusWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool isHealthy;
  final String iconName;

  const SystemStatusWidget({
    super.key,
    required this.label,
    required this.value,
    required this.isHealthy,
    required this.iconName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isHealthy ? Color(0xFF10B981) : Color(0xFFEF4444))
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: isHealthy ? Color(0xFF10B981) : Color(0xFFEF4444),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isHealthy ? Color(0xFF10B981) : Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
