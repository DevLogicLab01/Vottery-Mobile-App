import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TrafficDistributionWidget extends StatelessWidget {
  final Map<String, dynamic> trafficStats;
  final Map<String, dynamic> serviceHealth;

  const TrafficDistributionWidget({
    super.key,
    required this.trafficStats,
    required this.serviceHealth,
  });

  @override
  Widget build(BuildContext context) {
    final totalRequests = trafficStats['total_requests'] ?? 0;
    final geminiRequests = trafficStats['gemini_requests'] ?? 0;
    final primaryRequests = trafficStats['primary_requests'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Traffic Distribution Panel',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              'Partial failure handling: 70% Gemini, 30% Primary',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTrafficMetric(
                  'Total Requests',
                  totalRequests.toString(),
                  Colors.blue,
                ),
                _buildTrafficMetric(
                  'Gemini',
                  geminiRequests.toString(),
                  Colors.green,
                ),
                _buildTrafficMetric(
                  'Primary',
                  primaryRequests.toString(),
                  Colors.orange,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (totalRequests > 0)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: geminiRequests / totalRequests,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 1.h,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Gemini: ${(geminiRequests / totalRequests * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
