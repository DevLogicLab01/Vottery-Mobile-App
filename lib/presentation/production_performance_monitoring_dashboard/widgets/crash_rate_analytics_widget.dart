import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class CrashRateAnalyticsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> crashRateMetrics;

  const CrashRateAnalyticsWidget({super.key, required this.crashRateMetrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.red[700], size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Crash Rate Analytics',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Crashes per 1000 sessions (Critical threshold: >2%)',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          ...crashRateMetrics.map((metric) => _buildCrashRateCard(metric)),
        ],
      ),
    );
  }

  Widget _buildCrashRateCard(Map<String, dynamic> metric) {
    final screenName = metric['screen_name'] ?? 'Unknown';
    final crashRate = metric['crash_rate_percentage'] ?? 0.0;
    final crashesPerK = metric['crashes_per_1000_sessions'] ?? 0;
    final severity = metric['severity'] ?? 'low';
    final trend = metric['trend'] ?? 'stable';

    Color severityColor = Colors.green;
    if (severity == 'medium') severityColor = Colors.orange;
    if (severity == 'high') severityColor = Colors.deepOrange;
    if (severity == 'critical') severityColor = Colors.red;

    IconData trendIcon = Icons.trending_flat;
    Color trendColor = Colors.grey;
    if (trend == 'increasing') {
      trendIcon = Icons.trending_up;
      trendColor = Colors.red;
    } else if (trend == 'decreasing') {
      trendIcon = Icons.trending_down;
      trendColor = Colors.green;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: severityColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: severityColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  screenName,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '$crashesPerK crashes per 1000 sessions',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 16.sp),
                  SizedBox(width: 1.w),
                  Text(
                    '${crashRate.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
