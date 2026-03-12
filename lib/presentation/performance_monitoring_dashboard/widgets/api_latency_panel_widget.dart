import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ApiLatencyPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> endpoints;
  final int latencyThreshold;

  const ApiLatencyPanelWidget({
    super.key,
    required this.endpoints,
    this.latencyThreshold = 3000,
  });

  @override
  Widget build(BuildContext context) {
    // Build histogram buckets: 0-500, 500-1000, 1000-2000, 2000-3000, >3000
    final buckets = [0, 0, 0, 0, 0];
    for (final ep in endpoints) {
      final avg = (ep['avg_latency'] as num?)?.toInt() ?? 0;
      if (avg <= 500) {
        buckets[0]++;
      } else if (avg <= 1000)
        buckets[1]++;
      else if (avg <= 2000)
        buckets[2]++;
      else if (avg <= 3000)
        buckets[3]++;
      else
        buckets[4]++;
    }
    final maxBucket = buckets.reduce((a, b) => a > b ? a : b);
    final bucketLabels = ['<500ms', '500-1s', '1-2s', '2-3s', '>3s'];
    final bucketColors = [
      const Color(0xFF4CAF50),
      const Color(0xFF8BC34A),
      const Color(0xFFFFB347),
      const Color(0xFFFF8C00),
      const Color(0xFFFF6B6B),
    ];

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
                  Icons.network_check,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'API Latency',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withAlpha(30),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'P95 < ${latencyThreshold}ms',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6C63FF),
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            // Histogram
            Text(
              'Latency Distribution',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.sp),
            ),
            SizedBox(height: 1.h),
            SizedBox(
              height: 10.h,
              child: maxBucket == 0
                  ? Center(
                      child: Text(
                        'No data',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 11.sp,
                        ),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxBucket.toDouble() + 1,
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= bucketLabels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  bucketLabels[idx],
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 8.sp,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          5,
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: buckets[i].toDouble(),
                                color: bucketColors[i],
                                width: 6.w,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 2.h),
            // Endpoints table
            if (endpoints.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF2A2A3E),
                  ),
                  columnSpacing: 3.w,
                  columns: [
                    DataColumn(
                      label: Text(
                        'Endpoint',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Avg',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'P95',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'P99',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                  rows: endpoints.take(10).map((ep) {
                    final avg = (ep['avg_latency'] as num?)?.toInt() ?? 0;
                    final p95 = (ep['p95'] as num?)?.toInt() ?? 0;
                    final p99 = (ep['p99'] as num?)?.toInt() ?? 0;
                    final isSlow = p95 > latencyThreshold;

                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 30.w,
                            child: Text(
                              ep['endpoint_name']?.toString() ?? 'Unknown',
                              style: GoogleFonts.inter(
                                color: isSlow
                                    ? const Color(0xFFFF6B6B)
                                    : Colors.white,
                                fontSize: 11.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${avg}ms',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${p95}ms',
                            style: GoogleFonts.inter(
                              color: isSlow
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.white70,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${p99}ms',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSlow
                                  ? const Color(0xFFFF6B6B).withAlpha(30)
                                  : const Color(0xFF4CAF50).withAlpha(30),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              isSlow ? 'SLOW' : 'OK',
                              style: GoogleFonts.inter(
                                color: isSlow
                                    ? const Color(0xFFFF6B6B)
                                    : const Color(0xFF4CAF50),
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
