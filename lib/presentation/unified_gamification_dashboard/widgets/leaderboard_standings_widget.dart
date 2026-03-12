import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Leaderboard Standings Widget
/// Shows current global/regional/friends rank with rank change arrows (↑↓)
class LeaderboardStandingsWidget extends StatelessWidget {
  final Map<String, dynamic>? standings;

  const LeaderboardStandingsWidget({super.key, required this.standings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (standings == null) {
      return _buildEmptyState(theme);
    }

    final global = standings!['global'] as Map<String, dynamic>?;
    final regional = standings!['regional'] as Map<String, dynamic>?;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          if (global != null) _buildRankCard('Global', global, theme),
          if (global != null && regional != null) SizedBox(height: 2.h),
          if (regional != null) _buildRankCard('Regional', regional, theme),
        ],
      ),
    );
  }

  Widget _buildRankCard(
    String scope,
    Map<String, dynamic> rankData,
    ThemeData theme,
  ) {
    final rank = rankData['rank_position'] as int? ?? 0;
    final score = rankData['score'] as int? ?? 0;
    final rankChange = rankData['rank_change'] as int? ?? 0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: scope == 'Global' ? 'public' : 'location_on',
            color: theme.colorScheme.primary,
            size: 28,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$scope Rank',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '#$rank',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    if (rankChange != 0)
                      Row(
                        children: [
                          Icon(
                            rankChange > 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: rankChange > 0 ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          Text(
                            '${rankChange.abs()}',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: rankChange > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Score',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
              Text(
                '$score VP',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'leaderboard',
              color: theme.colorScheme.onSurface.withAlpha(77),
              size: 40,
            ),
            SizedBox(height: 1.h),
            Text(
              'No Leaderboard Data',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
