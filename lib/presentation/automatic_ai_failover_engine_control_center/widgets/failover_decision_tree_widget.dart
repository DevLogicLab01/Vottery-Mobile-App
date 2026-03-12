import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FailoverDecisionTreeWidget extends StatelessWidget {
  final Map<String, dynamic> serviceHealth;

  const FailoverDecisionTreeWidget({super.key, required this.serviceHealth});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Failover Decision Tree',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              'Automated switching criteria',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            _buildDecisionRule(
              'Response Time > 10s',
              'Switch to fallback',
              Colors.red,
              Icons.timer_off,
            ),
            SizedBox(height: 1.h),
            _buildDecisionRule(
              'Error Rate > 25%',
              'Switch to fallback',
              Colors.orange,
              Icons.error_outline,
            ),
            SizedBox(height: 1.h),
            _buildDecisionRule(
              '3 Consecutive Failures',
              'Switch to fallback',
              Colors.deepOrange,
              Icons.warning,
            ),
            SizedBox(height: 1.h),
            _buildDecisionRule(
              'Partial Failure',
              '70% Gemini, 30% Primary',
              Colors.blue,
              Icons.pie_chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionRule(
    String condition,
    String action,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  condition,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  action,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: color, size: 18.sp),
        ],
      ),
    );
  }
}
