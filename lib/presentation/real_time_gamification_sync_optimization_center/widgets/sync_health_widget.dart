import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SyncHealthWidget extends StatelessWidget {
  final String status;
  final bool isOnline;
  final int reconnectAttempts;

  const SyncHealthWidget({
    super.key,
    required this.status,
    required this.isOnline,
    required this.reconnectAttempts,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Real-Time Sync Health Monitoring',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        Card(
          color: isOnline ? Colors.green.shade50 : Colors.red.shade50,
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Icon(
                  isOnline ? Icons.check_circle : Icons.error,
                  color: isOnline ? Colors.green : Colors.red,
                  size: 10.w,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isOnline
                            ? 'All systems operational'
                            : 'Offline mode active',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        if (!isOnline)
          Card(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-Recovery',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Reconnect attempts: $reconnectAttempts',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Exponential backoff: 1s, 2s, 4s, 8s, 16s',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: 2.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection Status Indicators',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                _buildStatusRow('WebSocket', isOnline),
                _buildStatusRow('Supabase Realtime', isOnline),
                _buildStatusRow('Offline Queue', true),
                _buildStatusRow('Blockchain Verification', isOnline),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String service, bool isActive) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(service, style: TextStyle(fontSize: 11.sp)),
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? Colors.green : Colors.red,
            size: 5.w,
          ),
        ],
      ),
    );
  }
}
