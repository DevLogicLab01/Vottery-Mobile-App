import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActiveVoteCardWidget extends StatelessWidget {
  final Map<String, dynamic> vote;
  final VoidCallback onVoteNow;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onDetails;

  const ActiveVoteCardWidget({
    super.key,
    required this.vote,
    required this.onVoteNow,
    required this.onBookmark,
    required this.onShare,
    required this.onDetails,
  });

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'ending_soon':
        return const Color(0xFFF59E0B);
      case 'participated':
        return const Color(0xFF10B981);
      default:
        return theme.colorScheme.primary;
    }
  }

  String _getTimeRemaining(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m remaining';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h remaining';
    } else {
      return '${difference.inDays}d remaining';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(vote["status"], theme);
    final participated = vote["participated"] as bool;

    return Slidable(
      key: ValueKey(vote["id"]),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onBookmark(),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.bookmark_outline,
            label: 'Bookmark',
          ),
          SlidableAction(
            onPressed: (context) => onShare(),
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            icon: Icons.share_outlined,
            label: 'Share',
          ),
          SlidableAction(
            onPressed: (context) => onDetails(),
            backgroundColor: const Color(0xFF6B7280),
            foregroundColor: Colors.white,
            icon: Icons.info_outline,
            label: 'Details',
          ),
        ],
      ),
      child: InkWell(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => _buildContextMenu(context, theme),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: participated
                  ? statusColor.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: participated ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with creator info and status
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    CustomImageWidget(
                      imageUrl: vote["creatorAvatar"],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      semanticLabel: vote["creatorAvatarLabel"],
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vote["creator"],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getTimeRemaining(vote["deadline"]),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (participated)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: 'check_circle',
                              color: statusColor,
                              size: 16,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'Voted',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Vote title and description
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vote["title"],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      vote["description"],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 2.h),

              // Progress bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${vote["totalVotes"]} votes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(vote["progress"] * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: vote["progress"],
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 2.h),

              // Action button
              if (!participated)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onVoteNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Vote Now',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onDetails,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        side: BorderSide(color: statusColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'View Results',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextMenu(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'bookmark_outline',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            title: Text('Bookmark', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              onBookmark();
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'share_outlined',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            title: Text('Share', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              onShare();
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'info_outline',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            title: Text('View Details', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              onDetails();
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'notifications_outlined',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            title: Text('Set Reminder', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reminder set for this vote'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
