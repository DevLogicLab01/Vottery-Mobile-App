import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class FeatureRequestCardWidget extends StatelessWidget {
  final Map<String, dynamic> request;
  final Function(bool) onVote;

  const FeatureRequestCardWidget({
    super.key,
    required this.request,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upvotes = request['vote_count'] ?? 0;
    final status = request['status'] ?? 'submitted';
    final category = request['category'] ?? 'other';
    final priority = request['priority'] ?? 'medium';

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
                  child: Text(
                    request['title'] ?? 'Feature Request',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStatusChip(theme, status),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              request['description'] ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Chip(
                  label: Text(category, style: theme.textTheme.bodySmall),
                  backgroundColor: _getCategoryColor(category, theme),
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                ),
                const Spacer(),
                _buildVoteButton(theme, Icons.thumb_up_outlined, upvotes, true),
                SizedBox(width: 2.w),
                _buildVoteButton(theme, Icons.thumb_down_outlined, 0, false),
              ],
            ),
            if (request['created_at'] != null) ...[
              SizedBox(height: 1.h),
              Text(
                'Submitted ${_formatDate(request['created_at'])}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'implemented':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        label = 'Implemented';
        break;
      case 'in_development':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        label = 'In Development';
        break;
      case 'under_review':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        label = 'Under Review';
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        label = 'Open';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVoteButton(
    ThemeData theme,
    IconData icon,
    int count,
    bool isUpvote,
  ) {
    return InkWell(
      onTap: () => onVote(isUpvote),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 5.w, color: theme.colorScheme.onSurfaceVariant),
            SizedBox(width: 1.w),
            Text(
              count.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category, ThemeData theme) {
    switch (category) {
      case 'Bug Reports':
        return Colors.red.withValues(alpha: 0.1);
      case 'Feature Requests':
        return Colors.blue.withValues(alpha: 0.1);
      case 'UI/UX Improvements':
        return Colors.purple.withValues(alpha: 0.1);
      case 'Performance':
        return Colors.orange.withValues(alpha: 0.1);
      case 'Security':
        return Colors.green.withValues(alpha: 0.1);
      default:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }

  String _formatDate(dynamic date) {
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'Recently';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 30) {
        return DateFormat('MMM d, y').format(dateTime);
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inMinutes} minutes ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildPriorityChip(String priority, ThemeData theme) {
    Color chipColor;
    switch (priority) {
      case 'critical':
        chipColor = Colors.red;
        break;
      case 'high':
        chipColor = Colors.orange;
        break;
      case 'medium':
        chipColor = Colors.blue;
        break;
      case 'low':
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withAlpha(77)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w600,
          fontSize: 10.sp,
        ),
      ),
    );
  }
}
