import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class FlaggedContentCardWidget extends StatelessWidget {
  final Map<String, dynamic> content;
  final VoidCallback onApprove;
  final VoidCallback onRemove;
  final VoidCallback onEscalate;

  const FlaggedContentCardWidget({
    super.key,
    required this.content,
    required this.onApprove,
    required this.onRemove,
    required this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskScore = content['risk_score'] ?? 0;
    final riskCategories = content['risk_categories'] as List? ?? [];
    final contentText = content['content_text'] ?? 'No content available';
    final createdAt = DateTime.parse(
      content['created_at'] ?? DateTime.now().toIso8601String(),
    );

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRiskColor(riskScore).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getRiskColor(riskScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'warning',
                      color: _getRiskColor(riskScore),
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Risk: $riskScore',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getRiskColor(riskScore),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                timeago.format(createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            contentText,
            style: theme.textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (riskCategories.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Wrap(
              spacing: 1.w,
              runSpacing: 0.5.h,
              children: riskCategories.map((category) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onApprove,
                  icon: CustomIconWidget(
                    iconName: 'check_circle',
                    color: const Color(0xFF10B981),
                    size: 18,
                  ),
                  label: Text(
                    'Approve',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF10B981)),
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEscalate,
                  icon: CustomIconWidget(
                    iconName: 'arrow_upward',
                    color: const Color(0xFFF59E0B),
                    size: 18,
                  ),
                  label: Text(
                    'Escalate',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(int riskScore) {
    if (riskScore >= 80) return const Color(0xFFEF4444);
    if (riskScore >= 60) return const Color(0xFFF59E0B);
    if (riskScore >= 40) return const Color(0xFF3B82F6);
    return const Color(0xFF10B981);
  }
}
