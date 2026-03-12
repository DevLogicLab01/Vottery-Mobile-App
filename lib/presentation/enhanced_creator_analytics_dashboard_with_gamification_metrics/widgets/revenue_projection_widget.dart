import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class RevenueProjectionWidget extends StatelessWidget {
  final Map<String, dynamic> projectionData;

  const RevenueProjectionWidget({super.key, required this.projectionData});

  @override
  Widget build(BuildContext context) {
    final next30Days =
        projectionData['next_30_days'] as Map<String, dynamic>? ?? {};
    final next60Days =
        projectionData['next_60_days'] as Map<String, dynamic>? ?? {};
    final next90Days =
        projectionData['next_90_days'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-powered header
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.deepPurple],
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 6.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Revenue Forecast',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Powered by OpenAI GPT-4',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Projection chart
          Text(
            'VP Earnings Projection',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return Text(
                              '30d',
                              style: GoogleFonts.inter(fontSize: 10.sp),
                            );
                          case 1:
                            return Text(
                              '60d',
                              style: GoogleFonts.inter(fontSize: 10.sp),
                            );
                          case 2:
                            return Text(
                              '90d',
                              style: GoogleFonts.inter(fontSize: 10.sp),
                            );
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  // Forecast line
                  LineChartBarData(
                    spots: [
                      FlSpot(
                        0,
                        (next30Days['forecast'] as num?)?.toDouble() ?? 0,
                      ),
                      FlSpot(
                        1,
                        (next60Days['forecast'] as num?)?.toDouble() ?? 0,
                      ),
                      FlSpot(
                        2,
                        (next90Days['forecast'] as num?)?.toDouble() ?? 0,
                      ),
                    ],
                    isCurved: true,
                    color: AppTheme.primaryLight,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  // Confidence high
                  LineChartBarData(
                    spots: [
                      FlSpot(
                        0,
                        (next30Days['confidence_high'] as num?)?.toDouble() ??
                            0,
                      ),
                      FlSpot(
                        1,
                        (next60Days['confidence_high'] as num?)?.toDouble() ??
                            0,
                      ),
                      FlSpot(
                        2,
                        (next90Days['confidence_high'] as num?)?.toDouble() ??
                            0,
                      ),
                    ],
                    isCurved: true,
                    color: Colors.green.withAlpha(77),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                  // Confidence low
                  LineChartBarData(
                    spots: [
                      FlSpot(
                        0,
                        (next30Days['confidence_low'] as num?)?.toDouble() ?? 0,
                      ),
                      FlSpot(
                        1,
                        (next60Days['confidence_low'] as num?)?.toDouble() ?? 0,
                      ),
                      FlSpot(
                        2,
                        (next90Days['confidence_low'] as num?)?.toDouble() ?? 0,
                      ),
                    ],
                    isCurved: true,
                    color: Colors.red.withAlpha(77),
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 3.h),

          // Projection cards
          _buildProjectionCard(
            '30 Days',
            next30Days['forecast'] as num? ?? 0,
            next30Days['confidence_low'] as num? ?? 0,
            next30Days['confidence_high'] as num? ?? 0,
            AppTheme.primaryLight,
          ),
          SizedBox(height: 2.h),
          _buildProjectionCard(
            '60 Days',
            next60Days['forecast'] as num? ?? 0,
            next60Days['confidence_low'] as num? ?? 0,
            next60Days['confidence_high'] as num? ?? 0,
            Colors.orange,
          ),
          SizedBox(height: 2.h),
          _buildProjectionCard(
            '90 Days',
            next90Days['forecast'] as num? ?? 0,
            next90Days['confidence_low'] as num? ?? 0,
            next90Days['confidence_high'] as num? ?? 0,
            Colors.green,
          ),
          SizedBox(height: 3.h),

          // Disclaimer
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.textSecondaryLight,
                  size: 5.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Projections are based on historical patterns and AI analysis. Actual results may vary.',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionCard(
    String period,
    num forecast,
    num confidenceLow,
    num confidenceHigh,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                period,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                '${forecast.toInt()} VP',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confidence Range',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              Text(
                '${confidenceLow.toInt()} - ${confidenceHigh.toInt()} VP',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
