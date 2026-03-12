import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class CohortAnalysisWidget extends StatelessWidget {
  final Map<String, dynamic> trackingData;

  const CohortAnalysisWidget({super.key, required this.trackingData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Cohort Analysis',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Segmenting users by gamification engagement level based on VP activity',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          _buildCohortCard(
            'Low Engagement',
            '0-500 VP earned',
            35,
            Colors.red,
            theme,
          ),
          SizedBox(height: 2.h),
          _buildCohortCard(
            'Medium Engagement',
            '501-2000 VP earned',
            45,
            Colors.orange,
            theme,
          ),
          SizedBox(height: 2.h),
          _buildCohortCard(
            'High Engagement',
            '2001+ VP earned',
            20,
            Colors.green,
            theme,
          ),
          SizedBox(height: 3.h),
          _buildCohortDistributionChart(theme),
        ],
      ),
    );
  }

  Widget _buildCohortCard(
    String title,
    String criteria,
    int percentage,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color, width: 2.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  criteria,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              '$percentage%',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCohortDistributionChart(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cohort Distribution',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 35,
                    title: '35%',
                    color: Colors.red,
                    radius: 15.w,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 45,
                    title: '45%',
                    color: Colors.orange,
                    radius: 15.w,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 20,
                    title: '20%',
                    color: Colors.green,
                    radius: 15.w,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2.0,
                centerSpaceRadius: 10.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
