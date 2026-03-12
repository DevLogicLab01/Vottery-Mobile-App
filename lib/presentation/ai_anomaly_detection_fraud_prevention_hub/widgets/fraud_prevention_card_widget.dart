import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FraudPreventionCardWidget extends StatelessWidget {
  final Map<String, dynamic> alert;
  final Function(String alertId, String action) onAction;

  const FraudPreventionCardWidget({
    super.key,
    required this.alert,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final severity = alert['severity'] ?? 'low';
    final fraudScore = alert['fraud_score'] ?? 0.0;
    final description = alert['description'] ?? 'Fraud detected';
    final recommendedAction = alert['recommended_action'] ?? 'investigate';

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: _getSeverityColor(severity), width: 2.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(1.5.w),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(severity).withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    _getSeverityIcon(severity),
                    color: _getSeverityColor(severity),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${severity.toUpperCase()} Threat',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: _getSeverityColor(severity),
                        ),
                      ),
                      Text(
                        'Fraud Score: ${fraudScore.toStringAsFixed(0)}',
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
                    color: _getSeverityColor(severity),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${fraudScore.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              description,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onAction(alert['id'], 'investigate'),
                    icon: Icon(Icons.search, size: 16.sp),
                    label: Text(
                      'Investigate',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onAction(alert['id'], recommendedAction),
                    icon: Icon(Icons.auto_fix_high, size: 16.sp),
                    label: Text(
                      _getActionLabel(recommendedAction),
                      style: TextStyle(fontSize: 10.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getSeverityColor(severity),
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.yellow.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.dangerous;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      default:
        return Icons.flag;
    }
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'suspend':
        return 'Suspend';
      case 'flag':
        return 'Flag';
      case 'block':
        return 'Block';
      default:
        return 'Review';
    }
  }
}
