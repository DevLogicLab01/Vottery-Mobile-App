import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TemplateLibraryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> templates;
  final Function(Map<String, dynamic>?) onEdit;
  final Function(Map<String, dynamic>) onTest;
  final Function(String, bool) onToggleStatus;

  const TemplateLibraryWidget({
    super.key,
    required this.templates,
    required this.onEdit,
    required this.onTest,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'No templates found',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: templates.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(context, template);
      },
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    Map<String, dynamic> template,
  ) {
    final theme = Theme.of(context);
    final templateName = template['template_name'] as String? ?? 'Untitled';
    final category = template['category'] as String? ?? 'unknown';
    final messageBody = template['message_body'] as String? ?? '';
    final priority = template['priority'] as String? ?? 'medium';
    final isActive = template['is_active'] as bool? ?? false;
    final usageCount = template['usage_count'] as int? ?? 0;

    final categoryColor = _getCategoryColor(category);
    final priorityColor = _getPriorityColor(priority);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  templateName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (value) {
                  onToggleStatus(template['template_id'] as String, isActive);
                },
                activeThumbColor: Colors.green,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: priorityColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getPriorityIcon(priority),
                      size: 10.sp,
                      color: priorityColor,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '$usageCount uses',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            messageBody,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => onTest(template),
                icon: Icon(Icons.play_arrow, size: 14.sp),
                label: const Text('Test'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
              TextButton.icon(
                onPressed: () => onEdit(template),
                icon: Icon(Icons.edit, size: 14.sp),
                label: const Text('Edit'),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'fraud':
        return Colors.red;
      case 'system_outage':
        return Colors.orange;
      case 'performance_degradation':
        return Colors.amber;
      case 'anomaly_detection':
        return Colors.purple;
      case 'security':
        return Colors.deepOrange;
      case 'operational':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}
