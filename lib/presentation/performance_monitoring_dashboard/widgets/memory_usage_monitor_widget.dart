import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class MemoryUsageMonitorWidget extends StatelessWidget {
  final int currentMemoryMb;
  final int memoryThresholdMb;
  final List<Map<String, dynamic>> memoryTrend;
  final List<Map<String, dynamic>> leakSuspects;

  const MemoryUsageMonitorWidget({
    super.key,
    required this.currentMemoryMb,
    this.memoryThresholdMb = 500,
    required this.memoryTrend,
    required this.leakSuspects,
  });

  @override
  Widget build(BuildContext context) {
    final usagePercent = (currentMemoryMb / memoryThresholdMb).clamp(0.0, 1.0);
    final isOverThreshold = currentMemoryMb > memoryThresholdMb;
    final gaugeColor = isOverThreshold
        ? const Color(0xFFFF6B6B)
        : usagePercent > 0.8
        ? const Color(0xFFFFB347)
        : const Color(0xFF4CAF50);

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
                const Icon(Icons.memory, color: Color(0xFF6C63FF), size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Memory Usage',
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
                                value: usagePercent,
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
                                  '${currentMemoryMb}MB',
                                  style: GoogleFonts.inter(
                                    color: gaugeColor,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '/ ${memoryThresholdMb}MB',
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
                        isOverThreshold
                            ? '⚠️ Over Threshold'
                            : '✓ Within Limit',
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
                        '24h Memory Trend',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      SizedBox(
                        height: 12.h,
                        child: memoryTrend.isEmpty
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
                                      spots: memoryTrend
                                          .asMap()
                                          .entries
                                          .map(
                                            (e) => FlSpot(
                                              e.key.toDouble(),
                                              (e.value['memory_mb'] as num? ??
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
            if (leakSuspects.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                'Potential Memory Leaks',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFB347),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              ...leakSuspects
                  .take(3)
                  .map(
                    (leak) => Padding(
                      padding: EdgeInsets.only(bottom: 0.5.h),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.leak_add,
                            color: Color(0xFFFFB347),
                            size: 14,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              leak['screen_name']?.toString() ?? 'Unknown',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '+${leak['growth_mb'] ?? 0}MB/hr',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFFB347),
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
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
