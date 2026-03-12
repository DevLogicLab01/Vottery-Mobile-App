import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class ApiLatencyMonitoringWidget extends StatelessWidget {
  final List<Map<String, dynamic>> apiLatencyMetrics;

  const ApiLatencyMonitoringWidget({
    super.key,
    required this.apiLatencyMetrics,
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
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: Colors.blue[700], size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'API Latency Monitoring',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'P95 latency across all services (High alert: >3s)',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          ...apiLatencyMetrics.map((metric) => _buildLatencyCard(metric)),
        ],
      ),
    );
  }

  Widget _buildLatencyCard(Map<String, dynamic> metric) {
    final serviceName = metric['service_name'] ?? 'Unknown';
    final latency = metric['average_latency_p95'] ?? 0.0;
    final severity = metric['severity'] ?? 'low';
    final status = metric['status'] ?? 'unknown';

    Color severityColor = Colors.green;
    if (severity == 'medium') severityColor = Colors.orange;
    if (severity == 'high') severityColor = Colors.red;

    IconData statusIcon = Icons.check_circle;
    Color statusColor = Colors.green;
    if (status == 'degraded') {
      statusIcon = Icons.warning;
      statusColor = Colors.orange;
    } else if (status == 'down') {
      statusIcon = Icons.error;
      statusColor = Colors.red;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Status: ${status.toUpperCase()}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${latency.toStringAsFixed(2)}s',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: severityColor,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'P95 Latency',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
