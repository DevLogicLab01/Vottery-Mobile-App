import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PerformanceBudgetAlertsWidget extends StatelessWidget {
  const PerformanceBudgetAlertsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Budget Alerts',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Warnings when screens exceed 2-second load threshold',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 3.h),
          _buildBudgetCard('Vote Dashboard', 1847, 2000, false),
          SizedBox(height: 2.h),
          _buildBudgetCard('Creator Marketplace', 2345, 2000, true),
          SizedBox(height: 2.h),
          _buildBudgetCard('Tax Compliance Dashboard', 2187, 2000, true),
          SizedBox(height: 2.h),
          _buildBudgetCard('Social Media Home Feed', 1654, 2000, false),
          SizedBox(height: 3.h),
          _buildBudgetConfiguration(),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    String screenName,
    int loadTime,
    int threshold,
    bool exceedsThreshold,
  ) {
    return Card(
      elevation: 2,
      color: exceedsThreshold ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  exceedsThreshold ? Icons.error : Icons.check_circle,
                  color: exceedsThreshold ? Colors.red : Colors.green,
                  size: 24.sp,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    screenName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${loadTime}ms',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: exceedsThreshold ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: loadTime / threshold,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                exceedsThreshold ? Colors.red : Colors.green,
              ),
              minHeight: 0.8.h,
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Budget: ${threshold}ms',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey),
            ),
            if (exceedsThreshold) ...[
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16.sp, color: Colors.red),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Exceeds budget by ${loadTime - threshold}ms',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetConfiguration() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, size: 20.sp, color: Colors.blue),
                SizedBox(width: 2.w),
                Text(
                  'Budget Configuration',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildConfigRow('Screen Load Threshold', '2000ms'),
            Divider(height: 2.h),
            _buildConfigRow('API Response Threshold', '500ms'),
            Divider(height: 2.h),
            _buildConfigRow('Memory Usage Threshold', '200MB'),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.edit, size: 16.sp),
                label: Text(
                  'Adjust Budgets',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
