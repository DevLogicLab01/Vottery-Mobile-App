import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class PerformanceHeaderWidget extends StatelessWidget {
  final int avgLoadTime;
  final int performanceScore;
  final int criticalAlerts;

  const PerformanceHeaderWidget({
    super.key,
    required this.avgLoadTime,
    required this.performanceScore,
    required this.criticalAlerts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.white,
      child: Row(
        children: [
          _buildMetricCard(
            icon: 'speed',
            label: 'Avg Load',
            value: '${avgLoadTime}ms',
            color: avgLoadTime > 2000 ? Colors.red : Colors.green,
          ),
          SizedBox(width: 3.w),
          _buildMetricCard(
            icon: 'star',
            label: 'Score',
            value: performanceScore.toString(),
            color: performanceScore >= 80 ? Colors.green : Colors.orange,
          ),
          SizedBox(width: 3.w),
          _buildMetricCard(
            icon: 'warning',
            label: 'Alerts',
            value: criticalAlerts.toString(),
            color: criticalAlerts > 0 ? Colors.red : Colors.green,
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
        ),
        child: Column(
          children: [
            CustomIconWidget(iconName: icon, size: 6.w, color: color),
            SizedBox(height: 1.h),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
