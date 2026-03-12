import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ModerationQueueCardWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onApprove;
  final VoidCallback onRemove;
  final VoidCallback onEscalate;

  const ModerationQueueCardWidget({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onRemove,
    required this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final violations = item['violation_categories'] as List? ?? [];
    final confidenceScore =
        (item['confidence_score'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getSeverityColor(violations).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['content_type']?.toString().toUpperCase() ?? 'CONTENT',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getSeverityColor(violations),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Confidence: ${(confidenceScore * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            item['content_text'] ?? 'No content text',
            style: theme.textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (violations.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: violations.map((v) {
                final violation = v as Map<String, dynamic>;
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'warning',
                        color: const Color(0xFFEF4444),
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        violation['category']?.toString() ?? 'Unknown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: CustomIconWidget(
                    iconName: 'check_circle',
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: CustomIconWidget(
                    iconName: 'delete',
                    color: const Color(0xFFEF4444),
                    size: 18,
                  ),
                  label: Text(
                    'Remove',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                onPressed: onEscalate,
                icon: CustomIconWidget(
                  iconName: 'arrow_upward',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(List violations) {
    if (violations.isEmpty) return const Color(0xFF10B981);

    for (final v in violations) {
      final violation = v as Map<String, dynamic>;
      final severity = violation['severity'] as String?;
      if (severity == 'critical') return const Color(0xFFEF4444);
      if (severity == 'high') return const Color(0xFFF59E0B);
    }

    return const Color(0xFF3B82F6);
  }
}
