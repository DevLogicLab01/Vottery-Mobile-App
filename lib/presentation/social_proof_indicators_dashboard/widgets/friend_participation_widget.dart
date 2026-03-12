import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../theme/app_theme.dart';

class FriendParticipationWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const FriendParticipationWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Friend Network Analysis',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        _buildParticipationChart(),
        SizedBox(height: 2.h),
        _buildMetricsCards(),
      ],
    );
  }

  Widget _buildParticipationChart() {
    return Container(
      height: 25.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: (metrics['active_friends'] ?? 0).toDouble(),
              title: 'Active',
              color: AppTheme.accentLight,
              radius: 50,
              titleStyle: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value:
                  ((metrics['total_friends'] ?? 0) -
                          (metrics['active_friends'] ?? 0))
                      .toDouble(),
              title: 'Inactive',
              color: AppTheme.borderLight,
              radius: 50,
              titleStyle: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCards() {
    return Column(
      children: [
        _buildMetricCard(
          'Friend-Driven Conversions',
          '${metrics['friend_driven_conversions'] ?? 0}',
          'Elections you voted on after friends',
          Icons.trending_up,
          AppTheme.accentLight,
        ),
        _buildMetricCard(
          'Social Influence Score',
          '${metrics['social_influence_score']?.toStringAsFixed(1) ?? '0'}',
          'Your impact on friend network',
          Icons.stars,
          AppTheme.warningLight,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 6.w),
          ),
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
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
