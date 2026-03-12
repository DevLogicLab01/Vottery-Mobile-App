import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CombinedAnalyticsWidget extends StatelessWidget {
  const CombinedAnalyticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Performance',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildRevenueChart(),
          SizedBox(height: 3.h),
          Text(
            'Revenue Optimization',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          _buildOptimizationSuggestions(),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 25.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartBar('Mon', 120, 0.6),
              _buildChartBar('Tue', 150, 0.75),
              _buildChartBar('Wed', 90, 0.45),
              _buildChartBar('Thu', 180, 0.9),
              _buildChartBar('Fri', 200, 1.0),
              _buildChartBar('Sat', 160, 0.8),
              _buildChartBar('Sun', 140, 0.7),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, double value, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '\$${value.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.h),
        Container(
          width: 8.w,
          height: 15.h * height,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildOptimizationSuggestions() {
    return Column(
      children: [
        _buildSuggestionCard(
          'Marketplace services show 25% higher conversion on weekends',
          Icons.trending_up,
          Colors.green,
        ),
        SizedBox(height: 1.h),
        _buildSuggestionCard(
          'Consider bundling consultation with exclusive access',
          Icons.lightbulb,
          Colors.orange,
        ),
        SizedBox(height: 1.h),
        _buildSuggestionCard(
          'Election engagement peaks at 7PM - schedule releases accordingly',
          Icons.schedule,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 5.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }
}
