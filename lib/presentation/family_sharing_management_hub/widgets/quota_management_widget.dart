import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class QuotaManagementWidget extends StatelessWidget {
  final Map<String, dynamic>? subscription;
  final Map<String, dynamic> usageAnalytics;
  final List<Map<String, dynamic>> familyMembers;

  const QuotaManagementWidget({
    super.key,
    this.subscription,
    required this.usageAnalytics,
    required this.familyMembers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalQuota = 10000; // Mock total quota
    final usedQuota = usageAnalytics['total_api_calls'] as int? ?? 0;
    final usagePercentage = (usedQuota / totalQuota * 100)
        .clamp(0, 100)
        .toDouble();

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quota Management',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildTotalQuotaCard(usedQuota, totalQuota, usagePercentage),
          SizedBox(height: 3.h),
          _buildAllocationBreakdown(),
          SizedBox(height: 3.h),
          if (usagePercentage >= 80) _buildQuotaWarning(usagePercentage),
        ],
      ),
    );
  }

  Widget _buildTotalQuotaCard(
    int usedQuota,
    int totalQuota,
    double percentage,
  ) {
    final color = percentage >= 100
        ? Colors.red
        : percentage >= 80
        ? Colors.orange
        : Colors.green;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(100), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Subscription Quota',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Stack(
            children: [
              Container(
                height: 2.h,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '$usedQuota / $totalQuota API calls used',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationBreakdown() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Allocation Breakdown',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildAllocationRow('Primary Account', 45, Colors.blue),
          _buildAllocationRow('Member 1', 25, Colors.green),
          _buildAllocationRow('Member 2', 15, Colors.orange),
          _buildAllocationRow('Member 3', 10, Colors.purple),
          _buildAllocationRow('Available', 5, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildAllocationRow(String label, int percentage, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Stack(
                  children: [
                    Container(
                      height: 0.8.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 0.8.h,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
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
  }

  Widget _buildQuotaWarning(double percentage) {
    final isExceeded = percentage >= 100;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isExceeded ? Colors.red[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isExceeded ? Colors.red : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExceeded ? Icons.error : Icons.warning,
            color: isExceeded ? Colors.red : Colors.orange,
            size: 8.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExceeded ? 'Quota Exceeded' : 'Quota Warning',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isExceeded ? Colors.red[900] : Colors.orange[900],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  isExceeded
                      ? 'Your family has exceeded the quota limit. New actions are prevented until next billing cycle.'
                      : 'Your family is using ${percentage.toStringAsFixed(1)}% of quota. Consider upgrading to a higher tier.',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isExceeded ? Colors.red[700] : Colors.orange[700],
                  ),
                ),
                if (!isExceeded) ...[
                  SizedBox(height: 1.h),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                    ),
                    child: const Text('Upgrade Plan'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
