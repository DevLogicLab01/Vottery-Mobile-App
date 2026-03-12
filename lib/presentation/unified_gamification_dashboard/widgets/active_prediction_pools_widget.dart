import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Active Prediction Pools Widget
/// Displays live pools with current odds, entry fees, prize pools, and join buttons
class ActivePredictionPoolsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> pools;
  final Function(String poolId) onJoinPool;

  const ActivePredictionPoolsWidget({
    super.key,
    required this.pools,
    required this.onJoinPool,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (pools.isEmpty) {
      return _buildEmptyState(theme);
    }

    return SizedBox(
      height: 22.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pools.length,
        itemBuilder: (context, index) {
          final pool = pools[index];
          return _buildPoolCard(pool, theme);
        },
      ),
    );
  }

  Widget _buildPoolCard(Map<String, dynamic> pool, ThemeData theme) {
    final entryFee = pool['entry_fee_vp'] as int? ?? 0;
    final prizePool = pool['prize_pool_vp'] as int? ?? 0;
    final participants = pool['participant_count'] as int? ?? 0;
    final election = pool['election'] as Map<String, dynamic>?;
    final title = election?['title'] as String? ?? 'Prediction Pool';

    return Container(
      width: 70.w,
      margin: EdgeInsets.only(right: 3.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'psychology',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('Entry Fee', '$entryFee VP', theme),
              _buildInfoItem('Prize Pool', '$prizePool VP', theme),
              _buildInfoItem('Participants', '$participants', theme),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onJoinPool(pool['id'] as String),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Join Pool',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
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
              iconName: 'psychology',
              color: theme.colorScheme.onSurface.withAlpha(77),
              size: 40,
            ),
            SizedBox(height: 1.h),
            Text(
              'No Active Prediction Pools',
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
