import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class ViolationCardWidget extends StatelessWidget {
  final Map<String, dynamic> violation;
  final Function(String) onAction;

  const ViolationCardWidget({
    super.key,
    required this.violation,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final severity = violation['severity'] as String;
    final systemName = violation['system_name'] as String;
    final description = violation['description'] as String;
    final detectedAt = DateTime.parse(violation['detected_at']);
    final policy =
        violation['carousel_compliance_policies'] as Map<String, dynamic>?;
    final policyName = policy?['policy_name'] ?? 'Unknown Policy';

    Color severityColor;
    switch (severity) {
      case 'critical':
        severityColor = Colors.red;
        break;
      case 'high':
        severityColor = Colors.orange;
        break;
      case 'medium':
        severityColor = Colors.yellow[700]!;
        break;
      default:
        severityColor = Colors.blue;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: severityColor, width: 2.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policyName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        systemName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(description, style: TextStyle(fontSize: 12.sp)),
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                SizedBox(width: 1.w),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(detectedAt),
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => onAction('investigate'),
                  icon: Icon(Icons.search, size: 16),
                  label: Text('Investigate'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
                SizedBox(width: 2.w),
                TextButton.icon(
                  onPressed: () => onAction('remediate'),
                  icon: Icon(Icons.check, size: 16),
                  label: Text('Remediate'),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
                SizedBox(width: 2.w),
                TextButton.icon(
                  onPressed: () => onAction('dismiss'),
                  icon: Icon(Icons.close, size: 16),
                  label: Text('Dismiss'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
