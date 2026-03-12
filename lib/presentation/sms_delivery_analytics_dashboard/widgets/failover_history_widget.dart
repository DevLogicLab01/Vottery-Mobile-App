import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class FailoverHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> failoverHistory;

  const FailoverHistoryWidget({
    required this.failoverHistory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (failoverHistory.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 48,
                color: Colors.green,
              ),
              SizedBox(height: 2.h),
              Text(
                'No failover events',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textPrimaryDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Failover History',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        SizedBox(height: 2.h),
        ...failoverHistory.map((failover) => _buildFailoverCard(failover)),
      ],
    );
  }

  Widget _buildFailoverCard(Map<String, dynamic> failover) {
    final fromProvider = failover['from_provider'] as String;
    final toProvider = failover['to_provider'] as String;
    final reason = failover['failover_reason'] as String;
    final failedAt = DateTime.parse(failover['failed_at'] as String);
    final restoredAt = failover['restored_at'] != null
        ? DateTime.parse(failover['restored_at'] as String)
        : null;
    final triggeredBy = failover['triggered_by'] as String;
    final messagesAffected = failover['messages_affected'] as int? ?? 0;

    final duration = restoredAt != null
        ? restoredAt.difference(failedAt)
        : DateTime.now().difference(failedAt);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: restoredAt != null
              ? Colors.green.withAlpha(77)
              : Colors.orange.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: triggeredBy == 'automatic'
                      ? Colors.orange
                      : Colors.blue,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  triggeredBy.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: restoredAt != null ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  restoredAt != null ? 'RESTORED' : 'ACTIVE',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProviderBadge(fromProvider, Colors.red),
              SizedBox(width: 2.w),
              Icon(
                Icons.arrow_forward,
                color: AppTheme.textSecondaryDark,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              _buildProviderBadge(toProvider, Colors.green),
            ],
          ),
          SizedBox(height: 2.h),
          _buildInfoRow(Icons.info, 'Reason', reason),
          SizedBox(height: 1.h),
          _buildInfoRow(
            Icons.access_time,
            'Failed At',
            DateFormat('MMM dd, yyyy HH:mm').format(failedAt),
          ),
          if (restoredAt != null) ...[
            SizedBox(height: 1.h),
            _buildInfoRow(
              Icons.check_circle,
              'Restored At',
              DateFormat('MMM dd, yyyy HH:mm').format(restoredAt),
            ),
          ],
          SizedBox(height: 1.h),
          _buildInfoRow(
            Icons.timer,
            'Duration',
            _formatDuration(duration),
          ),
          if (messagesAffected > 0) ...[
            SizedBox(height: 1.h),
            _buildInfoRow(
              Icons.message,
              'Messages Affected',
              messagesAffected.toString(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderBadge(String provider, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color),
      ),
      child: Text(
        provider.toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppTheme.textSecondaryDark),
        SizedBox(width: 2.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppTheme.textSecondaryDark,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textPrimaryDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}