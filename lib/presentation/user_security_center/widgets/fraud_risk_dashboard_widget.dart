import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FraudRiskDashboardWidget extends StatelessWidget {
  final Map<String, dynamic>? fraudRiskScore;
  final VoidCallback onRefresh;

  const FraudRiskDashboardWidget({
    super.key,
    required this.fraudRiskScore,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (fraudRiskScore == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 30.sp, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No fraud risk data available',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            ElevatedButton(onPressed: onRefresh, child: const Text('Refresh')),
          ],
        ),
      );
    }

    final contributingFactors =
        fraudRiskScore!['contributing_factors'] as List? ?? [];
    final recommendations = fraudRiskScore!['recommendations'] as List? ?? [];
    final previousScore = fraudRiskScore!['previous_score'];
    final scoreTrend = fraudRiskScore!['score_trend'] ?? 'stable';

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score trend
          if (previousScore != null)
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    scoreTrend == 'decreasing'
                        ? Icons.trending_down
                        : scoreTrend == 'increasing'
                        ? Icons.trending_up
                        : Icons.trending_flat,
                    color: scoreTrend == 'decreasing'
                        ? Colors.green
                        : scoreTrend == 'increasing'
                        ? Colors.red
                        : Colors.grey,
                    size: 20.sp,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Score Trend: ${scoreTrend.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Previous score: $previousScore',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 2.h),

          // Contributing factors
          Text(
            'Contributing Factors',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          contributingFactors.isEmpty
              ? Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'No risk factors detected',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: contributingFactors.map((factor) {
                    final factorName = factor['factor'] ?? '';
                    final weight = factor['weight'] ?? 0;

                    return Card(
                      margin: EdgeInsets.only(bottom: 1.h),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.withAlpha(51),
                          child: Text(
                            '$weight',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        title: Text(
                          factorName,
                          style: TextStyle(fontSize: 13.sp),
                        ),
                        subtitle: LinearProgressIndicator(
                          value: weight / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
          SizedBox(height: 3.h),

          // Recommendations
          Text(
            'Security Recommendations',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          recommendations.isEmpty
              ? Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'No recommendations at this time',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: recommendations.map((rec) {
                    final action = rec['action'] ?? '';
                    final priority = rec['priority'] ?? 'low';

                    Color priorityColor;
                    switch (priority) {
                      case 'high':
                        priorityColor = Colors.red;
                        break;
                      case 'medium':
                        priorityColor = Colors.orange;
                        break;
                      default:
                        priorityColor = Colors.blue;
                    }

                    return Card(
                      margin: EdgeInsets.only(bottom: 1.h),
                      child: ListTile(
                        leading: Icon(
                          Icons.lightbulb_outline,
                          color: priorityColor,
                        ),
                        title: Text(action, style: TextStyle(fontSize: 13.sp)),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withAlpha(51),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
