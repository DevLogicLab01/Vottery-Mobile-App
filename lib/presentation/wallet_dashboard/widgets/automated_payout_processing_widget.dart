import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AutomatedPayoutProcessingWidget extends StatelessWidget {
  final int pendingPayouts;
  final int processingPayouts;

  const AutomatedPayoutProcessingWidget({
    super.key,
    required this.pendingPayouts,
    required this.processingPayouts,
  });

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
              'Automated Payout Processing',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              'Request → KYC → Processing → Completed',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPayoutStatus(
                  'Pending',
                  pendingPayouts,
                  Icons.pending_actions,
                  Colors.orange,
                ),
                _buildPayoutStatus(
                  'Processing',
                  processingPayouts,
                  Icons.sync,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutStatus(
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32.sp),
        SizedBox(height: 0.5.h),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
