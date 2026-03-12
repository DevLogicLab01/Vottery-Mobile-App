import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class SentryDeliveryMetricsWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const SentryDeliveryMetricsWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final deliveryRate = metrics['delivery_success_rate'] ?? 0.0;
    final avgDeliveryTime = metrics['average_delivery_time_ms'] ?? 0.0;
    final totalEvents = metrics['total_events_sent'] ?? 0;
    final successfulDeliveries = metrics['successfully_delivered'] ?? 0;
    final eventsBySeverity =
        metrics['events_by_severity'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricCard(
            'Delivery Success Rate',
            '${deliveryRate.toStringAsFixed(1)}%',
            deliveryRate > 95 ? Colors.green : Colors.red,
            '$successfulDeliveries / $totalEvents delivered',
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Average Delivery Time',
            '${avgDeliveryTime.toStringAsFixed(0)}ms',
            avgDeliveryTime < 200 ? Colors.green : Colors.orange,
            'Target: < 200ms',
          ),
          SizedBox(height: 3.h),
          Text(
            'Events by Severity',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          _buildSeverityBreakdown(eventsBySeverity),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 1.h),
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
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.cloud_upload, color: color, size: 10.w),
        ],
      ),
    );
  }

  Widget _buildSeverityBreakdown(Map<String, dynamic> eventsBySeverity) {
    final severities = ['critical', 'high', 'medium', 'low'];
    final colors = {
      'critical': Colors.red,
      'high': Colors.orange,
      'medium': Colors.yellow.shade700,
      'low': Colors.blue,
    };

    return Column(
      children: severities.map((severity) {
        final count = eventsBySeverity[severity] ?? 0;
        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: colors[severity]!.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 4.w,
                height: 4.w,
                decoration: BoxDecoration(
                  color: colors[severity],
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                count.toString(),
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: colors[severity],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
