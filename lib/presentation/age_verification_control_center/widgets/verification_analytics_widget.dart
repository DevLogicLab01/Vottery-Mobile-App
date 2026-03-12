import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class VerificationAnalyticsWidget extends StatelessWidget {
  const VerificationAnalyticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Text(
          'Verification Analytics',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Success Rate',
                '94.2%',
                Colors.green,
                Icons.check_circle,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Avg Time',
                '45s',
                Colors.blue,
                Icons.timer,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Card(
          elevation: 2.0,
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Methods',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                _buildMethodRow('Facial Estimation', '72%', Colors.blue),
                _buildMethodRow('Government ID', '23%', Colors.orange),
                _buildMethodRow('Digital Wallet', '5%', Colors.green),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Card(
          elevation: 2.0,
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failure Reasons',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                _buildFailureRow('Under 18', '3.2%'),
                _buildFailureRow('Poor Image Quality', '1.8%'),
                _buildFailureRow('Document Mismatch', '0.8%'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodRow(String method, String percentage, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Expanded(
            child: Text(method, style: TextStyle(fontSize: 11.sp)),
          ),
          Container(
            width: 50.w,
            height: 2.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: double.parse(percentage.replaceAll('%', '')) / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            percentage,
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureRow(String reason, String percentage) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(reason, style: TextStyle(fontSize: 11.sp)),
          Text(
            percentage,
            style: TextStyle(fontSize: 11.sp, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
