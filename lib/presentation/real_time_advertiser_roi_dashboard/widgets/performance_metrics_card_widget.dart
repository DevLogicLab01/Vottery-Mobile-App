import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PerformanceMetricsCardWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const PerformanceMetricsCardWidget({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 2,
    );
    final costPerParticipant =
        (analytics['cost_per_participant'] ?? 0.0) as num;
    final conversionRate = (analytics['conversion_rate'] ?? 0.0) as num;
    final reach = (analytics['total_impressions'] ?? 0) as int;
    final engagement = (analytics['engagement_rate'] ?? 0.0) as num;
    final roi = (analytics['roi_percentage'] ?? 0.0) as num;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 3.w,
          mainAxisSpacing: 2.h,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              'Cost/Participant',
              currencyFormat.format(costPerParticipant),
              Icons.attach_money,
              Colors.blue,
            ),
            _buildMetricCard(
              'Conversion Rate',
              '${conversionRate.toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.green,
            ),
            _buildMetricCard(
              'Reach',
              reach.toString(),
              Icons.visibility,
              Colors.purple,
            ),
            _buildMetricCard(
              'Engagement',
              '${engagement.toStringAsFixed(1)}%',
              Icons.favorite,
              Colors.red,
            ),
            _buildMetricCard(
              'ROI',
              '${roi.toStringAsFixed(1)}%',
              Icons.show_chart,
              roi >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
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
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
