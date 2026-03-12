import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class ReactionLeaderboardWidget extends StatelessWidget {
  const ReactionLeaderboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final mostReactedContent = [
      {
        'rank': 1,
        'content_type': 'Election',
        'title': 'Presidential Election 2024',
        'total_reactions': 45678,
        'top_emoji': '🔥',
        'engagement_score': 94.2,
      },
      {
        'rank': 2,
        'content_type': 'Post',
        'title': 'Amazing sunset photography',
        'total_reactions': 38291,
        'top_emoji': '❤️',
        'engagement_score': 89.7,
      },
      {
        'rank': 3,
        'content_type': 'Jolt',
        'title': 'Funny cat compilation',
        'total_reactions': 34567,
        'top_emoji': '😂',
        'engagement_score': 87.3,
      },
      {
        'rank': 4,
        'content_type': 'Election',
        'title': 'Best Pizza Topping',
        'total_reactions': 29834,
        'top_emoji': '🍕',
        'engagement_score': 82.1,
      },
      {
        'rank': 5,
        'content_type': 'Post',
        'title': 'Inspirational quote of the day',
        'total_reactions': 24567,
        'top_emoji': '💯',
        'engagement_score': 78.9,
      },
    ];

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildLeaderboardHeader(theme),
        SizedBox(height: 3.h),
        ...mostReactedContent.map((content) {
          return _buildLeaderboardCard(theme, content);
        }),
      ],
    );
  }

  Widget _buildLeaderboardHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: AppTheme.vibrantYellow, size: 40.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Most Reacted Content',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Top performing content across all types',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(ThemeData theme, Map<String, dynamic> content) {
    final rank = content['rank'] as int;
    final rankColor = rank == 1
        ? AppTheme.vibrantYellow
        : rank == 2
        ? Colors.grey.shade400
        : rank == 3
        ? Colors.brown.shade400
        : AppTheme.primaryLight;

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: rank <= 3
            ? Border.all(color: rankColor.withValues(alpha: 0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
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
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            content['content_type'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      content['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                content['top_emoji'] as String,
                style: TextStyle(fontSize: 32.sp),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(
                theme,
                'Reactions',
                '${(content['total_reactions'] as int) ~/ 1000}K',
                Icons.emoji_emotions,
              ),
              _buildMetric(
                theme,
                'Engagement',
                '${content['engagement_score']}%',
                Icons.trending_up,
              ),
              _buildMetric(
                theme,
                'Top Emoji',
                content['top_emoji'] as String,
                null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    ThemeData theme,
    String label,
    String value,
    IconData? icon,
  ) {
    return Column(
      children: [
        if (icon != null)
          Icon(icon, color: AppTheme.primaryLight, size: 20.sp)
        else
          Text(value, style: TextStyle(fontSize: 24.sp)),
        if (icon != null) SizedBox(height: 0.5.h),
        if (icon != null)
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
