import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/creator_earnings_service.dart';

class EarningsBreakdownWidget extends StatelessWidget {
  final String period;
  final CreatorEarningsService _earningsService =
      CreatorEarningsService.instance;

  EarningsBreakdownWidget({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: period == 'weekly'
          ? _earningsService.getWeeklyEarnings()
          : _earningsService.getMonthlyEarnings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {};

        if (period == 'weekly') {
          return _buildWeeklyBreakdown(data);
        } else {
          return _buildMonthlyBreakdown(data);
        }
      },
    );
  }

  Widget _buildWeeklyBreakdown(Map<String, dynamic> data) {
    final currentWeekUsd = data['current_week_usd'] ?? 0.0;
    final previousWeekUsd = data['previous_week_usd'] ?? 0.0;
    final growthPercentage = data['growth_percentage'] ?? 0.0;
    final isPositiveGrowth = growthPercentage >= 0;

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Earnings',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'This Week',
                '\$${currentWeekUsd.toStringAsFixed(2)}',
                AppTheme.primaryLight,
              ),
              _buildStatCard(
                'Last Week',
                '\$${previousWeekUsd.toStringAsFixed(2)}',
                AppTheme.textSecondaryLight,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: isPositiveGrowth
                  ? AppTheme.accentLight.withAlpha(26)
                  : AppTheme.errorLight.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: isPositiveGrowth ? 'trending_up' : 'trending_down',
                  size: 5.w,
                  color: isPositiveGrowth
                      ? AppTheme.accentLight
                      : AppTheme.errorLight,
                ),
                SizedBox(width: 2.w),
                Text(
                  '${growthPercentage.abs().toStringAsFixed(1)}% ${isPositiveGrowth ? 'growth' : 'decline'}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isPositiveGrowth
                        ? AppTheme.accentLight
                        : AppTheme.errorLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdown(Map<String, dynamic> data) {
    final totalUsd = data['total_usd'] ?? 0.0;
    final averagePerDay = data['average_per_day'] ?? 0.0;
    final daysWithEarnings = data['days_with_earnings'] ?? 0;

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Summary',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildStatCard(
            'Total Earnings',
            '\$${totalUsd.toStringAsFixed(2)}',
            AppTheme.primaryLight,
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Avg/Day',
                '\$${averagePerDay.toStringAsFixed(2)}',
                AppTheme.accentLight,
              ),
              _buildStatCard(
                'Active Days',
                '$daysWithEarnings',
                AppTheme.secondaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
