import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PaymentRetryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> retryLogs;
  final Function(String) onRetry;

  const PaymentRetryWidget({
    super.key,
    required this.retryLogs,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRetryStrategyCard(),
          SizedBox(height: 3.h),
          Text(
            'Retry Logic Configuration',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildRetrySchedule(),
          SizedBox(height: 3.h),
          Text(
            'Failed Payment Retry History',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (retryLogs.isEmpty)
            _buildEmptyState()
          else
            ...retryLogs.map((log) => _buildRetryLogCard(context, log)),
        ],
      ),
    );
  }

  Widget _buildRetryStrategyCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(Icons.autorenew, color: Colors.white, size: 10.w),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exponential Backoff Strategy',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Automatic retry with 3 attempts: immediate, 24h, 72h',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetrySchedule() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _buildRetryStep(
            'Attempt 1',
            'Immediate',
            Icons.flash_on,
            Colors.green,
          ),
          Divider(height: 3.h),
          _buildRetryStep(
            'Attempt 2',
            '24 hours later',
            Icons.schedule,
            Colors.orange,
          ),
          Divider(height: 3.h),
          _buildRetryStep(
            'Attempt 3',
            '72 hours later',
            Icons.update,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildRetryStep(
    String attempt,
    String timing,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 6.w),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attempt,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                timing,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRetryLogCard(BuildContext context, Map<String, dynamic> log) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Attempt ${log['attempt_number']}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: log['success'] == true
                      ? Colors.green.withAlpha(26)
                      : Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  log['success'] == true ? 'Success' : 'Failed',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: log['success'] == true ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          if (log['error_message'] != null) ...[
            SizedBox(height: 1.h),
            Text(
              log['error_message'],
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 20.w, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No failed payments to retry',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
