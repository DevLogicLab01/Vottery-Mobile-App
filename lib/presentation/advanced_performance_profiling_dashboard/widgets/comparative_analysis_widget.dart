import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ComparativeAnalysisWidget extends StatelessWidget {
  final String screenName;

  const ComparativeAnalysisWidget({super.key, required this.screenName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before/After Optimization',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildComparisonCard(
            'CPU Usage',
            '78.5%',
            '42.3%',
            Icons.memory,
            Colors.blue,
          ),
          SizedBox(height: 2.h),
          _buildComparisonCard(
            'Memory Usage',
            '645 MB',
            '312 MB',
            Icons.storage,
            Colors.purple,
          ),
          SizedBox(height: 2.h),
          _buildComparisonCard(
            'Network Bandwidth',
            '8.2 MB/s',
            '3.1 MB/s',
            Icons.network_check,
            Colors.orange,
          ),
          SizedBox(height: 2.h),
          _buildComparisonCard(
            'Frame Rate',
            '42 FPS',
            '58 FPS',
            Icons.speed,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    String metric,
    String beforeValue,
    String afterValue,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 6.w, color: color),
                SizedBox(width: 2.w),
                Text(
                  metric,
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildValueColumn('Before', beforeValue, Colors.red),
                ),
                Icon(Icons.arrow_forward, size: 6.w, color: Colors.grey),
                Expanded(
                  child: _buildValueColumn('After', afterValue, Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueColumn(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: google_fonts.GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: google_fonts.GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
