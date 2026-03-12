import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class WinnerAnnouncementWidget extends StatelessWidget {
  final List<Map<String, dynamic>> winners;
  final VoidCallback onRefresh;

  const WinnerAnnouncementWidget({
    super.key,
    required this.winners,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (winners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 20.w,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No winners announced yet',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: winners.length,
        itemBuilder: (context, index) {
          final winner = winners[index];
          return _buildWinnerCard(theme, winner, index + 1);
        },
      ),
    );
  }

  Widget _buildWinnerCard(
    ThemeData theme,
    Map<String, dynamic> winner,
    int position,
  ) {
    final username = winner['user_profiles']?['username'] ?? 'Anonymous';
    final prizeAmount = winner['prize_amount'] ?? 0.0;
    final voterId = winner['voter_id_number'] ?? 'N/A';

    Color positionColor;
    IconData positionIcon;

    switch (position) {
      case 1:
        positionColor = const Color(0xFFFFD700); // Gold
        positionIcon = Icons.emoji_events;
        break;
      case 2:
        positionColor = const Color(0xFFC0C0C0); // Silver
        positionIcon = Icons.emoji_events;
        break;
      case 3:
        positionColor = const Color(0xFFCD7F32); // Bronze
        positionIcon = Icons.emoji_events;
        break;
      default:
        positionColor = AppTheme.accentLight;
        positionIcon = Icons.star;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            positionColor.withValues(alpha: 0.2),
            positionColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: positionColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(positionIcon, color: positionColor, size: 8.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getPositionSuffix(position)} Place Winner',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: positionColor,
                      ),
                    ),
                    Text(
                      username,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${prizeAmount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: positionColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.confirmation_number,
                  size: 4.w,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Voter ID: $voterId',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
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

  String _getPositionSuffix(int position) {
    if (position == 1) return '1st';
    if (position == 2) return '2nd';
    if (position == 3) return '3rd';
    return '${position}th';
  }
}
