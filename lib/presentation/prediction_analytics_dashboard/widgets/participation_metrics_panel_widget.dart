import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ParticipationMetricsPanelWidget extends StatelessWidget {
  final int totalPredictions;
  final int uniquePredictors;
  final double avgPredictionsPerUser;
  final double participationRate;
  final List<Map<String, dynamic>> dailyTrend;

  const ParticipationMetricsPanelWidget({
    super.key,
    required this.totalPredictions,
    required this.uniquePredictors,
    required this.avgPredictionsPerUser,
    required this.participationRate,
    required this.dailyTrend,
  });

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.people, color: Color(0xFF6C63FF), size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Participation Metrics',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Predictions',
                    totalPredictions.toString(),
                    Icons.how_to_vote,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    'Unique Predictors',
                    uniquePredictors.toString(),
                    Icons.person,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Avg per User',
                    avgPredictionsPerUser.toStringAsFixed(1),
                    Icons.trending_up,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    'Participation Rate',
                    '${participationRate.toStringAsFixed(1)}%',
                    Icons.percent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Daily Participation (30 days)',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.sp),
            ),
            SizedBox(height: 1.h),
            SizedBox(
              height: 12.h,
              child: dailyTrend.isEmpty
                  ? Center(
                      child: Text(
                        'No trend data',
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
                            spots: dailyTrend
                                .asMap()
                                .entries
                                .map(
                                  (e) => FlSpot(
                                    e.key.toDouble(),
                                    (e.value['count'] as num? ?? 0).toDouble(),
                                  ),
                                )
                                .toList(),
                            isCurved: true,
                            color: const Color(0xFF6C63FF),
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF6C63FF).withAlpha(30),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 16),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}
