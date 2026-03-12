import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class LotteryDrawCardWidget extends StatelessWidget {
  final Map<String, dynamic> lottery;
  final VoidCallback onJoin;

  const LotteryDrawCardWidget({
    super.key,
    required this.lottery,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drawName = lottery['draw_name'] ?? 'Lottery Draw';
    final prizePool = lottery['prize_pool'] ?? 0.0;
    final totalParticipants = lottery['total_participants'] ?? 0;
    final scheduledDrawTime = lottery['scheduled_draw_time'] != null
        ? DateTime.parse(lottery['scheduled_draw_time'])
        : null;
    final status = lottery['status'] ?? 'scheduled';

    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.casino, color: AppTheme.accentLight, size: 8.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  drawName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.accentLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prize Pool',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '\$${prizePool.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentLight,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Participants',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      totalParticipants.toString(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (scheduledDrawTime != null) ...[
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 4.w,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Draw: ${DateFormat('MMM dd, yyyy HH:mm').format(scheduledDrawTime)}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: status == 'active' ? () => _joinLottery(context) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: Text('Join Lottery'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinLottery(BuildContext context) async {
    // Remove the joinLottery call since the method doesn't exist in WalletService
    // Call the onJoin callback directly
    onJoin();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined lottery'),
          backgroundColor: AppTheme.accentLight,
        ),
      );
    }
  }
}
