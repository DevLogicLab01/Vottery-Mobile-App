import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class WorkspaceCardWidget extends StatelessWidget {
  final Map<String, dynamic> workspace;
  final VoidCallback onTap;
  final VoidCallback onToggleStar;

  const WorkspaceCardWidget({
    super.key,
    required this.workspace,
    required this.onTap,
    required this.onToggleStar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = workspace['icon'] ?? '📊';
    final name = workspace['name'] ?? 'Workspace';
    final description = workspace['description'] ?? '';
    final memberCount = workspace['member_count'] ?? 1;
    final lastActivity = workspace['last_activity_at'] != null
        ? DateTime.parse(workspace['last_activity_at'])
        : DateTime.now();
    final isStarred = workspace['is_starred'] ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(icon, style: TextStyle(fontSize: 20.sp)),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (description.isNotEmpty)
                          Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isStarred ? Icons.star : Icons.star_border,
                      color: isStarred
                          ? Colors.amber
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onToggleStar,
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 4.w,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '$memberCount members',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.access_time,
                    size: 4.w,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    timeago.format(lastActivity),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
