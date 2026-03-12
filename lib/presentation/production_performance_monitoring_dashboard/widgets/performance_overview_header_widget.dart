import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class PerformanceOverviewHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> systemHealthScore;

  const PerformanceOverviewHeaderWidget({
    super.key,
    required this.systemHealthScore,
  });

  @override
  Widget build(BuildContext context) {
    final healthScore = systemHealthScore['overall_health_score'] ?? 0.0;
    final activeIncidents = systemHealthScore['active_incidents'] ?? 0;
    final automatedRemediations =
        systemHealthScore['automated_remediations'] ?? 0;
    final status = systemHealthScore['status'] ?? 'unknown';

    Color statusColor = Colors.green;
    if (status == 'degraded') statusColor = Colors.orange;
    if (status == 'critical') statusColor = Colors.red;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart, color: Colors.white, size: 24.sp),
              SizedBox(width: 2.w),
              Text(
                'System Health Overview',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricCard(
                'Health Score',
                '${healthScore.toStringAsFixed(1)}%',
                statusColor,
              ),
              _buildMetricCard(
                'Active Incidents',
                activeIncidents.toString(),
                activeIncidents > 5 ? Colors.red : Colors.white,
              ),
              _buildMetricCard(
                'Auto Remediations',
                automatedRemediations.toString(),
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 1.w),
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.white.withAlpha(230),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
