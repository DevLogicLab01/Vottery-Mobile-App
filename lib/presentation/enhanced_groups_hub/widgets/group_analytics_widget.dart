import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Group Analytics Widget - Comprehensive group performance metrics
class GroupAnalyticsWidget extends StatelessWidget {
  final String groupId;

  const GroupAnalyticsWidget({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    if (groupId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 20.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'Select a group to view analytics',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Members',
                  '12,450',
                  '+245 this week',
                  Icons.people,
                  AppTheme.primaryLight,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Engagement',
                  '85%',
                  '+5% this week',
                  Icons.trending_up,
                  AppTheme.accentLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Member Growth Chart
          Text(
            'Member Growth',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            height: 25.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowLight,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(4.w),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 10000),
                      FlSpot(1, 10500),
                      FlSpot(2, 11200),
                      FlSpot(3, 11800),
                      FlSpot(4, 12450),
                    ],
                    isCurved: true,
                    color: AppTheme.primaryLight,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryLight.withAlpha(51),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 3.h),

          // Popular Content
          Text(
            'Popular Content',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildPopularContentCard(
            'Election Discussion Thread',
            '1,245 engagements',
            '342 comments',
          ),
          SizedBox(height: 1.5.h),
          _buildPopularContentCard(
            'Voting Guide 2026',
            '892 engagements',
            '156 shares',
          ),
          SizedBox(height: 3.h),

          // Retention Stats
          Text(
            'Retention Statistics',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowLight,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                _buildRetentionRow('7-day retention', 0.92),
                SizedBox(height: 1.5.h),
                _buildRetentionRow('30-day retention', 0.78),
                SizedBox(height: 1.5.h),
                _buildRetentionRow('90-day retention', 0.65),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            change,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularContentCard(
    String title,
    String metric1,
    String metric2,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: AppTheme.vibrantYellow, size: 8.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '$metric1 • $metric2',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionRow(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentLight,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.8.h),
        LinearProgressIndicator(
          value: value,
          backgroundColor: AppTheme.borderLight,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentLight),
          minHeight: 0.8.h,
          borderRadius: BorderRadius.circular(4.0),
        ),
      ],
    );
  }
}
