import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RuleBuilderWidget extends StatelessWidget {
  final Map<String, dynamic> rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const RuleBuilderWidget({
    super.key,
    required this.rule,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = rule['status'] == 'active';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule['rule_name'] ?? 'Unnamed Rule',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        rule['description'] ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: isActive, onChanged: (_) => onToggle()),
              ],
            ),
            SizedBox(height: 2.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: [
                _buildInfoChip(
                  theme,
                  Icons.analytics,
                  rule['metric_type'] ?? 'N/A',
                ),
                _buildInfoChip(
                  theme,
                  Icons.trending_up,
                  '${rule['threshold_value'] ?? 0}',
                ),
                _buildSeverityChip(theme, rule['severity'] ?? 'medium'),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit, size: 16.sp),
                  label: Text('Edit'),
                ),
                SizedBox(width: 2.w),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete, size: 16.sp, color: Colors.red),
                  label: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16.sp),
      label: Text(label, style: theme.textTheme.bodySmall),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    );
  }

  Widget _buildSeverityChip(ThemeData theme, String severity) {
    Color color;
    switch (severity) {
      case 'critical':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.yellow.shade700;
        break;
      default:
        color = Colors.blue;
    }

    return Chip(
      label: Text(
        severity.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
    );
  }
}
