import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class UserEngagementTrackingWidget extends StatelessWidget {
  const UserEngagementTrackingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildReactionHistoryCard(theme),
        SizedBox(height: 3.h),
        _buildNotificationSettingsCard(theme),
        SizedBox(height: 3.h),
        _buildLeaderboardPreviewCard(theme),
      ],
    );
  }

  Widget _buildReactionHistoryCard(ThemeData theme) {
    final recentReactions = [
      {
        'content_type': 'Election',
        'content_title': 'Presidential Election 2024',
        'emoji': '🔥',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'content_type': 'Post',
        'content_title': 'Amazing sunset photo',
        'emoji': '❤️',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'content_type': 'Jolt',
        'content_title': 'Funny cat video',
        'emoji': '😂',
        'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
      },
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Recent Reactions',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...recentReactions.map((reaction) {
            return _buildReactionHistoryItem(theme, reaction);
          }),
        ],
      ),
    );
  }

  Widget _buildReactionHistoryItem(
    ThemeData theme,
    Map<String, dynamic> reaction,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Text(reaction['emoji'] as String, style: TextStyle(fontSize: 28.sp)),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reaction['content_title'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${reaction['content_type']} • ${_formatTimestamp(reaction['timestamp'] as DateTime)}',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reaction Notifications',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildNotificationToggle(
            theme,
            'Notify when someone reacts to my content',
            true,
          ),
          _buildNotificationToggle(
            theme,
            'Notify when content I reacted to gets popular',
            false,
          ),
          _buildNotificationToggle(theme, 'Daily reaction summary', true),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(ThemeData theme, String label, bool value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {},
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardPreviewCard(ThemeData theme) {
    final topUsers = [
      {'name': 'Sarah Johnson', 'reactions_given': 1247, 'rank': 1},
      {'name': 'Mike Chen', 'reactions_given': 1089, 'rank': 2},
      {'name': 'Emma Davis', 'reactions_given': 967, 'rank': 3},
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Reactors This Week',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Icon(
                Icons.emoji_events,
                color: AppTheme.vibrantYellow,
                size: 24.sp,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...topUsers.map((user) {
            return _buildLeaderboardItem(theme, user);
          }),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(ThemeData theme, Map<String, dynamic> user) {
    final rank = user['rank'] as int;
    final rankColor = rank == 1
        ? AppTheme.vibrantYellow
        : rank == 2
        ? Colors.grey.shade400
        : Colors.brown.shade400;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: rankColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${user['reactions_given']} reactions given',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
