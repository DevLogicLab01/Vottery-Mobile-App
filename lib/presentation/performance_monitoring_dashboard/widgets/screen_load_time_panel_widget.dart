import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ScreenLoadTimePanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> screenMetrics;
  final int threshold;

  const ScreenLoadTimePanelWidget({
    super.key,
    required this.screenMetrics,
    this.threshold = 2000,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<Map<String, dynamic>>.from(screenMetrics)
      ..sort(
        (a, b) => ((b['avg_load_time'] as num?) ?? 0).compareTo(
          (a['avg_load_time'] as num?) ?? 0,
        ),
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
                const Icon(Icons.speed, color: Color(0xFF6C63FF), size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Screen Load Times',
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
                    'Threshold: ${threshold}ms',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6C63FF),
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (sorted.isEmpty)
              Center(
                child: Text(
                  'No screen metrics available',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12.sp,
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF2A2A3E),
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF6C63FF).withAlpha(20);
                    }
                    return const Color(0xFF1E1E2E);
                  }),
                  columnSpacing: 3.w,
                  columns: [
                    DataColumn(
                      label: Text(
                        'Screen',
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
                        'P50',
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
                  rows: sorted.take(15).map((screen) {
                    final avg = (screen['avg_load_time'] as num?)?.toInt() ?? 0;
                    final p50 = (screen['p50'] as num?)?.toInt() ?? 0;
                    final p95 = (screen['p95'] as num?)?.toInt() ?? 0;
                    final p99 = (screen['p99'] as num?)?.toInt() ?? 0;
                    final isSlowAvg = avg > threshold;
                    final isSlowP95 = p95 > threshold;

                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 25.w,
                            child: Text(
                              screen['screen_name']?.toString() ?? 'Unknown',
                              style: GoogleFonts.inter(
                                color: isSlowAvg
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
                              color: isSlowAvg
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.white70,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${p50}ms',
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
                              color: isSlowP95
                                  ? const Color(0xFFFFB347)
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
                              color: isSlowAvg
                                  ? const Color(0xFFFF6B6B).withAlpha(30)
                                  : const Color(0xFF4CAF50).withAlpha(30),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              isSlowAvg ? 'SLOW' : 'OK',
                              style: GoogleFonts.inter(
                                color: isSlowAvg
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
            if (sorted.any(
              (s) => ((s['avg_load_time'] as num?)?.toInt() ?? 0) > threshold,
            )) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withAlpha(15),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: const Color(0xFFFF6B6B).withAlpha(50),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Color(0xFFFF6B6B),
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        '${sorted.where((s) => ((s['avg_load_time'] as num?)?.toInt() ?? 0) > threshold).length} screens exceed ${threshold}ms threshold. Consider lazy loading and code splitting.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFF6B6B),
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
