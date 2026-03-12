import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AnomalyDetectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> anomalies;

  const AnomalyDetectionWidget({super.key, required this.anomalies});

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
              Icon(Icons.warning_amber, color: Colors.red[700], size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Anomaly Detection',
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
            'Metrics with >25% degradation from 7-day baseline',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          if (anomalies.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 32.sp),
                    SizedBox(height: 1.h),
                    Text(
                      'No anomalies detected',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...anomalies.map((anomaly) => _buildAnomalyCard(anomaly)),
        ],
      ),
    );
  }

  Widget _buildAnomalyCard(Map<String, dynamic> anomaly) {
    final metricName = anomaly['metric_name'] ?? 'Unknown';
    final currentValue = anomaly['current_value'] ?? 0.0;
    final baselineValue = anomaly['baseline_value'] ?? 0.0;
    final degradationPercentage = anomaly['degradation_percentage'] ?? 0.0;
    final detectedAt = anomaly['detected_at'] as DateTime?;

    Color severityColor = Colors.orange;
    if (degradationPercentage > 100) severityColor = Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: severityColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: severityColor.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: severityColor, size: 18.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  metricName,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '+${degradationPercentage.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: severityColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current: ${currentValue.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Baseline: ${baselineValue.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (detectedAt != null)
                Text(
                  DateFormat('MMM dd, HH:mm').format(detectedAt),
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
