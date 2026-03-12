import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AchievementLeaderboardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboard;

  const AchievementLeaderboardWidget({super.key, required this.leaderboard});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 80, color: theme.colorScheme.outline),
            SizedBox(height: 2.h),
            Text(
              'Leaderboard Coming Soon',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final user = leaderboard[index];
        final rank = index + 1;
        final username = user['username'] as String? ?? 'Anonymous';
        final badgeCount = user['badge_count'] as int? ?? 0;
        final totalVP = user['total_vp'] as int? ?? 0;

        final isTopThree = rank <= 3;
        Color? rankColor;
        IconData? rankIcon;

        if (rank == 1) {
          rankColor = const Color(0xFFFFD700); // Gold
          rankIcon = Icons.emoji_events;
        } else if (rank == 2) {
          rankColor = const Color(0xFFC0C0C0); // Silver
          rankIcon = Icons.emoji_events;
        } else if (rank == 3) {
          rankColor = const Color(0xFFCD7F32); // Bronze
          rankIcon = Icons.emoji_events;
        }

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isTopThree
                ? rankColor!.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isTopThree
                  ? rankColor!
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: isTopThree ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: isTopThree
                      ? rankColor
                      : theme.colorScheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isTopThree
                      ? Icon(rankIcon, color: Colors.white, size: 24)
                      : Text(
                          '#$rank',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),

              SizedBox(width: 3.w),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '$badgeCount badges',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Icon(
                          Icons.stars,
                          size: 16,
                          color: theme.colorScheme.tertiary,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '$totalVP VP',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
