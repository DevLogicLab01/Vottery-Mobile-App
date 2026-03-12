import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AccessibilityImpactWidget extends StatelessWidget {
  final Map<String, dynamic> impactData;

  const AccessibilityImpactWidget({super.key, required this.impactData});

  @override
  Widget build(BuildContext context) {
    final engagementIncrease = impactData['engagement_increase'] ?? 0.0;
    final sessionDurationIncrease =
        impactData['session_duration_increase'] ?? 0.0;
    final retentionImprovement = impactData['retention_improvement'] ?? 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accessibility Impact on Engagement',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Measure accessibility impact on user engagement and retention',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 3.h),
          _buildImpactCard(
            'Engagement Increase',
            '+${engagementIncrease.toStringAsFixed(1)}%',
            'Users with accessibility features enabled',
            Icons.trending_up,
            Colors.green,
          ),
          SizedBox(height: 2.h),
          _buildImpactCard(
            'Session Duration Increase',
            '+${sessionDurationIncrease.toStringAsFixed(1)}%',
            'Average time spent in app',
            Icons.timer,
            Colors.blue,
          ),
          SizedBox(height: 2.h),
          _buildImpactCard(
            'Retention Improvement',
            '+${retentionImprovement.toStringAsFixed(1)}%',
            '30-day retention rate',
            Icons.people,
            Colors.purple,
          ),
          SizedBox(height: 3.h),
          _buildABTestingSection(),
        ],
      ),
    );
  }

  Widget _buildImpactCard(
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: color, size: 32.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildABTestingSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, size: 20.sp, color: Colors.orange),
                SizedBox(width: 2.w),
                Text(
                  'A/B Testing for Accessibility',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Automated A/B testing to optimize accessibility features',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 2.h),
            _buildTestRow(
              'Font Scaling Default',
              'Testing 1.0x vs 1.1x',
              'Running',
            ),
            Divider(height: 2.h),
            _buildTestRow(
              'Theme Auto-Detection',
              'Testing auto vs manual',
              'Completed',
            ),
            Divider(height: 2.h),
            _buildTestRow(
              'Contrast Levels',
              'Testing 3 contrast ratios',
              'Planned',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestRow(String testName, String description, String status) {
    Color statusColor;
    switch (status) {
      case 'Running':
        statusColor = Colors.blue;
        break;
      case 'Completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                testName,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            status,
            style: TextStyle(fontSize: 10.sp, color: statusColor),
          ),
        ),
      ],
    );
  }
}
