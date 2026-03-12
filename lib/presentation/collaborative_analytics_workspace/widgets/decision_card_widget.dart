import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class DecisionCardWidget extends StatelessWidget {
  final Map<String, dynamic> decision;
  final Function(String) onStatusChange;

  const DecisionCardWidget({
    super.key,
    required this.decision,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = decision['title'] ?? 'Decision';
    final proposer = decision['proposer'];
    final proposerName = proposer != null
        ? (proposer['full_name'] ?? proposer['email'] ?? 'Unknown')
        : 'Unknown';
    final createdAt = DateTime.parse(decision['created_at']);
    final impactBadge = decision['impact_badge'] ?? 'medium';
    final status = decision['status'] ?? 'proposed';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildImpactBadge(impactBadge, theme),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                CircleAvatar(
                  radius: 3.w,
                  child: Text(proposerName[0].toUpperCase()),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proposerName,
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
              ],
            ),
            SizedBox(height: 2.h),
            PopupMenuButton<String>(
              onSelected: onStatusChange,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'proposed',
                  child: Text('Move to Proposed'),
                ),
                const PopupMenuItem(
                  value: 'under_review',
                  child: Text('Move to Under Review'),
                ),
                const PopupMenuItem(
                  value: 'approved',
                  child: Text('Move to Approved'),
                ),
                const PopupMenuItem(
                  value: 'rejected',
                  child: Text('Move to Rejected'),
                ),
                const PopupMenuItem(
                  value: 'implemented',
                  child: Text('Move to Implemented'),
                ),
              ],
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_horiz, size: 16),
                    SizedBox(width: 1.w),
                    const Text('Change Status'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactBadge(String impact, ThemeData theme) {
    Color color;
    switch (impact) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        impact.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
