import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

/// User Segmentation Panel - Pie chart showing feature usage by user tiers
class UserSegmentationPanelWidget extends StatelessWidget {
  final Map<String, double> userSegments;

  const UserSegmentationPanelWidget({super.key, required this.userSegments});

  static const Map<String, Color> _segmentColors = {
    'new_users': Colors.blue,
    'power_users': Colors.green,
    'creators': Colors.purple,
    'standard': Colors.orange,
  };

  static const Map<String, String> _segmentLabels = {
    'new_users': 'New Users',
    'power_users': 'Power Users',
    'creators': 'Creators',
    'standard': 'Standard',
  };

  @override
  Widget build(BuildContext context) {
    final entries = userSegments.entries.toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Segmentation',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Feature usage breakdown by user tier with engagement correlation',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: PieChart(
              PieChartData(
                sections: entries.asMap().entries.map((entry) {
                  final e = entry.value;
                  final color = _segmentColors[e.key] ?? Colors.grey;
                  return PieChartSectionData(
                    value: e.value,
                    color: color,
                    title: '${e.value.toStringAsFixed(1)}%',
                    titleStyle: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    radius: 12.w,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 8.w,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          ...entries.map((e) => _buildSegmentRow(e.key, e.value)),
          SizedBox(height: 2.h),
          _buildEngagementCorrelation(),
        ],
      ),
    );
  }

  Widget _buildSegmentRow(String key, double value) {
    final label = _segmentLabels[key] ?? key;
    final color = _segmentColors[key] ?? Colors.grey;
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 3.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementCorrelation() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.teal.withAlpha(20),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.teal.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement Correlation',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: Colors.teal,
            ),
          ),
          SizedBox(height: 1.h),
          _buildCorrelationRow(
            'Power Users',
            'Highest AI feature adoption',
            0.92,
            Colors.green,
          ),
          _buildCorrelationRow(
            'Creators',
            'Strong quest completion rate',
            0.85,
            Colors.purple,
          ),
          _buildCorrelationRow(
            'New Users',
            'Growing consensus usage',
            0.67,
            Colors.blue,
          ),
          _buildCorrelationRow(
            'Standard',
            'Baseline engagement',
            0.45,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationRow(
    String segment,
    String insight,
    double score,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  segment,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  insight,
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              '${(score * 100).toInt()}%',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
