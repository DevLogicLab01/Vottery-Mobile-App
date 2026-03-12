import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class CrashRateMonitorWidget extends StatelessWidget {
  final double crashesPerThousand;
  final double crashThreshold;
  final List<Map<String, dynamic>> crashTrend;
  final List<Map<String, dynamic>> topCrashCauses;

  const CrashRateMonitorWidget({
    super.key,
    required this.crashesPerThousand,
    this.crashThreshold = 10.0,
    required this.crashTrend,
    required this.topCrashCauses,
  });

  @override
  Widget build(BuildContext context) {
    final isOverThreshold = crashesPerThousand > crashThreshold;
    final gaugeColor = isOverThreshold
        ? const Color(0xFFFF6B6B)
        : crashesPerThousand > crashThreshold * 0.7
        ? const Color(0xFFFFB347)
        : const Color(0xFF4CAF50);
    final gaugeValue = (crashesPerThousand / (crashThreshold * 2)).clamp(
      0.0,
      1.0,
    );

    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bug_report,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Crash Rate Monitor',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 12.h,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 12.h,
                              width: 12.h,
                              child: CircularProgressIndicator(
                                value: gaugeValue,
                                strokeWidth: 10,
                                backgroundColor: const Color(0xFF2A2A3E),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  gaugeColor,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  crashesPerThousand.toStringAsFixed(2),
                                  style: GoogleFonts.inter(
                                    color: gaugeColor,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'per 1k',
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        isOverThreshold ? '⚠️ Critical' : '✓ Healthy',
                        style: GoogleFonts.inter(
                          color: gaugeColor,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '30-Day Crash Trend',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      SizedBox(
                        height: 12.h,
                        child: crashTrend.isEmpty
                            ? Center(
                                child: Text(
                                  'No data',
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              )
                            : LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: const FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: crashTrend
                                          .asMap()
                                          .entries
                                          .map(
                                            (e) => FlSpot(
                                              e.key.toDouble(),
                                              (e.value['crash_rate'] as num? ??
                                                      0)
                                                  .toDouble(),
                                            ),
                                          )
                                          .toList(),
                                      isCurved: true,
                                      color: gaugeColor,
                                      barWidth: 2,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: gaugeColor.withAlpha(30),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (topCrashCauses.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                'Top Crash Causes',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              ...topCrashCauses
                  .take(5)
                  .map(
                    (cause) => Padding(
                      padding: EdgeInsets.only(bottom: 1.h),
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cause['crash_type']?.toString() ??
                                        'Unknown Error',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFFF6B6B),
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${cause['occurrence_count'] ?? 0}x',
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                            if (cause['affected_screens'] != null) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                'Screens: ${cause['affected_screens']}',
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 10.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (cause['stack_trace_preview'] != null) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                cause['stack_trace_preview'].toString(),
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 9.sp,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}