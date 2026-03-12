import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TrackingStatusOverviewWidget extends StatelessWidget {
  final int activeEvents;
  final double dataQualityScore;
  final int eventsToday;
  final bool realTimeActive;

  const TrackingStatusOverviewWidget({
    super.key,
    required this.activeEvents,
    required this.dataQualityScore,
    required this.eventsToday,
    required this.realTimeActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              _buildMetricCard(
                icon: 'event',
                label: 'Active Events',
                value: activeEvents.toString(),
                color: AppTheme.primaryLight,
              ),
              SizedBox(width: 3.w),
              _buildMetricCard(
                icon: 'verified',
                label: 'Data Quality',
                value: '${dataQualityScore.toStringAsFixed(1)}%',
                color: Colors.green,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildMetricCard(
                icon: 'analytics',
                label: 'Events Today',
                value: eventsToday.toString(),
                color: Colors.orange,
              ),
              SizedBox(width: 3.w),
              _buildMetricCard(
                icon: realTimeActive ? 'check_circle' : 'error',
                label: 'Real-Time',
                value: realTimeActive ? 'Active' : 'Inactive',
                color: realTimeActive ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomIconWidget(iconName: icon, size: 6.w, color: color),
            SizedBox(height: 1.h),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
