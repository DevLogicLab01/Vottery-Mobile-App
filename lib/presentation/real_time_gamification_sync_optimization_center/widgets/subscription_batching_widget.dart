import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SubscriptionBatchingWidget extends StatelessWidget {
  final int pendingUpdates;
  final int batchSize;

  const SubscriptionBatchingWidget({
    super.key,
    required this.pendingUpdates,
    required this.batchSize,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Supabase Subscription Batching',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Updates',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '$pendingUpdates / $batchSize',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                LinearProgressIndicator(
                  value: pendingUpdates / batchSize,
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Icon(Icons.trending_down, color: Colors.green, size: 8.w),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '90% Network Reduction',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Batching 10 updates into single payload',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
