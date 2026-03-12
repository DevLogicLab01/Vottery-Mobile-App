import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PredictiveFraudScoringWidget extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const PredictiveFraudScoringWidget({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    final detectionRate = statistics['detection_rate'] ?? 0.92;
    final suspiciousClusters = statistics['suspicious_clusters'] ?? 3;
    final coordinatedPatterns = statistics['coordinated_patterns'] ?? 7;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: Colors.blue.shade700,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Predictive Fraud Scoring',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'OpenAI Semantic Analysis',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Detection Rate',
                    '${(detectionRate * 100).toStringAsFixed(1)}%',
                    Icons.radar,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    'Suspicious Clusters',
                    suspiciousClusters.toString(),
                    Icons.group_work,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    'Coordinated Patterns',
                    coordinatedPatterns.toString(),
                    Icons.timeline,
                    Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 16.sp,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'AI analyzes voting patterns for coordinated manipulation attempts with 0-100 risk scores',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
