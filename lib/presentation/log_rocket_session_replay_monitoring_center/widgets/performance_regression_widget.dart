import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class PerformanceRegressionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> regressions;

  const PerformanceRegressionWidget({super.key, required this.regressions});

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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_down,
                color: const Color(0xFFEF4444),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Performance Regression Detection',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (regressions.isEmpty)
            _buildEmptyState()
          else
            ...regressions.map(
              (regression) => _buildRegressionCard(regression),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 20.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'No performance regressions detected',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegressionCard(Map<String, dynamic> regression) {
    final severity = regression['severity'] as String;
    final isCritical = severity == 'critical';
    final baselineValue = regression['baseline_value'] as double;
    final currentValue = regression['current_value'] as double;
    final percentageIncrease =
        ((currentValue - baselineValue) / baselineValue * 100).toStringAsFixed(
          1,
        );

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isCritical ? Colors.red[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: isCritical ? Colors.red[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: isCritical ? Colors.red[700] : Colors.orange[700],
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  regression['screen_name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: isCritical ? Colors.red[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '+$percentageIncrease%',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isCritical ? Colors.red[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Metric: ${regression['metric']}',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              _buildMetricValue(
                'Baseline',
                '${baselineValue.toStringAsFixed(2)}s',
                Colors.green,
              ),
              SizedBox(width: 4.w),
              Icon(Icons.arrow_forward, color: Colors.grey[400], size: 14.sp),
              SizedBox(width: 4.w),
              _buildMetricValue(
                'Current',
                '${currentValue.toStringAsFixed(2)}s',
                isCritical ? Colors.red : Colors.orange,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Detected ${timeago.format(regression['detected_at'] as DateTime)}',
            style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricValue(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
