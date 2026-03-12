import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class InsightCardWidget extends StatelessWidget {
  final Map<String, dynamic> insight;
  final Function(bool) onVote;

  const InsightCardWidget({
    super.key,
    required this.insight,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = insight['title'] ?? 'Insight';
    final category = insight['category'] ?? 'performance';
    final author = insight['author'];
    final authorName = author != null
        ? (author['full_name'] ?? author['email'] ?? 'Unknown')
        : 'Unknown';
    final createdAt = DateTime.parse(insight['created_at']);
    final upvotes = insight['upvotes'] ?? 0;
    final downvotes = insight['downvotes'] ?? 0;
    final confidenceLevel = insight['confidence_level'] ?? 'medium';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildCategoryBadge(category, theme),
                SizedBox(width: 2.w),
                _buildConfidenceBadge(confidenceLevel, theme),
                const Spacer(),
                Icon(
                  Icons.lightbulb,
                  color: theme.colorScheme.primary,
                  size: 5.w,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Text(
              insight['content'] ?? '',
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                CircleAvatar(
                  radius: 3.w,
                  child: Text(authorName[0].toUpperCase()),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        timeago.format(createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up_outlined),
                      onPressed: () => onVote(true),
                      iconSize: 5.w,
                    ),
                    Text(upvotes.toString(), style: theme.textTheme.bodySmall),
                    SizedBox(width: 2.w),
                    IconButton(
                      icon: const Icon(Icons.thumb_down_outlined),
                      onPressed: () => onVote(false),
                      iconSize: 5.w,
                    ),
                    Text(
                      downvotes.toString(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        category.replaceAll('_', ' ').toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(String confidence, ThemeData theme) {
    Color color;
    switch (confidence) {
      case 'high':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart, size: 3.w, color: color),
          SizedBox(width: 1.w),
          Text(
            confidence.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
