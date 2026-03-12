import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class ErrorStatusHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> errorStats;

  const ErrorStatusHeaderWidget({super.key, required this.errorStats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalIncidents = errorStats['total_incidents'] ?? 0;
    final criticalCount = errorStats['critical_count'] ?? 0;
    final openCount = errorStats['open_count'] ?? 0;
    final errorRate = (errorStats['error_rate'] ?? 0.0) as double;

    final errorRateColor = errorRate > 10
        ? Colors.red
        : errorRate > 5
        ? Colors.orange
        : Colors.green;

    return Container(
      padding: EdgeInsets.all(4.w),
      color: theme.cardColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'Total Errors',
                totalIncidents.toString(),
                theme.colorScheme.primary,
              ),
              _buildStatColumn(
                'Critical',
                criticalCount.toString(),
                Colors.red,
              ),
              _buildStatColumn('Open', openCount.toString(), Colors.orange),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: errorRateColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.speed, color: errorRateColor, size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Error Rate: ${errorRate.toStringAsFixed(2)} errors/hour',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: errorRateColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey),
        ),
      ],
    );
  }
}
