import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RegressionAlertsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> regressions;
  final VoidCallback onRefresh;

  const RegressionAlertsWidget({
    super.key,
    required this.regressions,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: regressions.isEmpty
          ? _buildNoRegressions()
          : ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: regressions.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Regression Alerts',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Automated detection of performance regressions',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                      SizedBox(height: 2.h),
                    ],
                  );
                }
                return _buildRegressionCard(regressions[index - 1]);
              },
            ),
    );
  }

  Widget _buildNoRegressions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 60.sp, color: Colors.green),
          SizedBox(height: 2.h),
          Text(
            'No Regressions Detected',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'All performance metrics are within acceptable ranges',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegressionCard(Map<String, dynamic> regression) {
    final type = regression['type'] ?? '';
    final metric = regression['metric'] ?? '';
    final severity = regression['severity'] ?? 'medium';

    Color severityColor;
    switch (severity) {
      case 'critical':
        severityColor = Colors.red;
        break;
      case 'high':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.yellow;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: severityColor, size: 24.sp),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    metric,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(fontSize: 10.sp, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Type: $type',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
