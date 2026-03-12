import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../widgets/custom_icon_widget.dart';

class TransactionItemWidget extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionItemWidget({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = transaction['amount'] as int;
    final isEarning = amount > 0;
    final transactionType = transaction['transaction_type'] as String;
    final source = transaction['source'] as String;
    final description = transaction['description'] as String? ?? '';
    final createdAt = transaction['created_at'] != null
        ? DateTime.parse(transaction['created_at'])
        : DateTime.now();

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isEarning
                  ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
                  : theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: isEarning ? 'add_circle' : 'remove_circle',
              color: isEarning
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.secondary,
              size: 24,
            ),
          ),

          SizedBox(width: 3.w),

          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatSource(source),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 2.w),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isEarning ? '+' : ''}$amount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isEarning
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.secondary,
                ),
              ),
              Text(
                'VP',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSource(String source) {
    switch (source) {
      case 'voting':
        return 'Voting Reward';
      case 'social':
        return 'Social Interaction';
      case 'challenge':
        return 'Challenge Completed';
      case 'prediction':
        return 'Prediction Pool';
      case 'ad_free':
        return 'Ad-Free Purchase';
      case 'custom_theme':
        return 'Theme Purchase';
      case 'prediction_entry':
        return 'Prediction Entry';
      case 'premium_content':
        return 'Premium Content';
      default:
        return source
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) {
              return word[0].toUpperCase() + word.substring(1);
            })
            .join(' ');
    }
  }
}
