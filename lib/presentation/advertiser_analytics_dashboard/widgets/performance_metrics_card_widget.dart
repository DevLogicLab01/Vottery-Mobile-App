import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PerformanceMetricsCardWidget extends StatelessWidget {
  final int totalImpressions;
  final int totalClicks;
  final int totalParticipants;
  final num costPerParticipant;
  final num conversionRate;
  final num engagementRate;
  final num roiPercentage;

  const PerformanceMetricsCardWidget({
    super.key,
    required this.totalImpressions,
    required this.totalClicks,
    required this.totalParticipants,
    required this.costPerParticipant,
    required this.conversionRate,
    required this.engagementRate,
    required this.roiPercentage,
  });

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
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 2.0,
            children: [
              _buildMetricTile(
                'Total Impressions',
                _formatNumber(totalImpressions),
                Icons.visibility,
                Colors.blue,
              ),
              _buildMetricTile(
                'Total Clicks',
                _formatNumber(totalClicks),
                Icons.touch_app,
                Colors.purple,
              ),
              _buildMetricTile(
                'Participants',
                _formatNumber(totalParticipants),
                Icons.people,
                Colors.green,
              ),
              _buildMetricTile(
                'Cost/Participant',
                '\\\$${costPerParticipant.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.orange,
              ),
              _buildMetricTile(
                'Conversion Rate',
                '${conversionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.teal,
              ),
              _buildMetricTile(
                'Engagement Rate',
                '${engagementRate.toStringAsFixed(1)}%',
                Icons.favorite,
                Colors.pink,
              ),
              _buildMetricTile(
                'ROI',
                '${roiPercentage >= 0 ? '+' : ''}${roiPercentage.toStringAsFixed(1)}%',
                Icons.show_chart,
                roiPercentage >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 5.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
