import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AlertAnalyticsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;

  const AlertAnalyticsWidget({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    final deliveryRate = _calculateDeliveryRate();
    final avgResponseTime = _calculateAvgResponseTime();
    final alertsByType = _groupAlertsByType();

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alert Analytics',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          // Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Delivery Rate',
                  '${deliveryRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Avg Response',
                  '${avgResponseTime.toStringAsFixed(1)}m',
                  Icons.timer,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          // Alerts by Type Chart
          Text(
            'Alerts by Type',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: PieChart(
              PieChartData(
                sections: alertsByType.entries.map((entry) {
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '${entry.key}\n${entry.value}',
                    color: _getColorForType(entry.key),
                    radius: 15.w,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2.0,
                centerSpaceRadius: 8.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Icon(icon, size: 8.w, color: color),
            SizedBox(height: 1.h),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDeliveryRate() {
    if (alerts.isEmpty) return 0.0;
    final delivered = alerts
        .where((a) => a['delivery_status'] == 'delivered')
        .length;
    return (delivered / alerts.length) * 100;
  }

  double _calculateAvgResponseTime() {
    final withResponseTime = alerts.where(
      (a) => a['response_time_minutes'] != null,
    );
    if (withResponseTime.isEmpty) return 0.0;
    final total = withResponseTime
        .map((a) => a['response_time_minutes'] as int)
        .reduce((a, b) => a + b);
    return total / withResponseTime.length;
  }

  Map<String, int> _groupAlertsByType() {
    final grouped = <String, int>{};
    for (final alert in alerts) {
      final type = alert['alert_type'] as String;
      grouped[type] = (grouped[type] ?? 0) + 1;
    }
    return grouped;
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'fraud':
        return Colors.red;
      case 'failover':
        return Colors.orange;
      case 'security':
        return Colors.purple;
      case 'performance':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
