import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class SessionStabilityWidget extends StatelessWidget {
  final Map<String, dynamic> sessionStabilityData;

  const SessionStabilityWidget({super.key, required this.sessionStabilityData});

  @override
  Widget build(BuildContext context) {
    final stabilityScore =
        sessionStabilityData['session_stability_score'] ?? 0.0;
    final successfulSessions = sessionStabilityData['successful_sessions'] ?? 0;
    final totalSessions = sessionStabilityData['total_sessions'] ?? 0;
    final severity = sessionStabilityData['severity'] ?? 'low';

    Color scoreColor = Colors.green;
    if (stabilityScore < 95) scoreColor = Colors.orange;
    if (stabilityScore < 90) scoreColor = Colors.red;

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
              Icon(Icons.verified_user, color: Colors.green[700], size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Session Stability',
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
            'Successful sessions / Total sessions (Medium alert: <95%)',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          Center(
            child: Column(
              children: [
                Text(
                  '${stabilityScore.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Stability Score',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSessionMetric(
                'Successful',
                successfulSessions.toString(),
                Colors.green,
              ),
              _buildSessionMetric(
                'Total',
                totalSessions.toString(),
                Colors.blue,
              ),
              _buildSessionMetric(
                'Failed',
                (totalSessions - successfulSessions).toString(),
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
