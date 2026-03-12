import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class LiveMetricsHeaderWidget extends StatelessWidget {
  final DateTime lastRefresh;

  const LiveMetricsHeaderWidget({super.key, required this.lastRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withAlpha(179),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_tethering, color: Colors.white, size: 20.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Metrics',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Last updated: ${_formatTime(lastRefresh)}',
                  style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: Colors.white, size: 8.sp),
                SizedBox(width: 1.w),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time).inSeconds;

    if (diff < 60) return '$diff seconds ago';
    return '${diff ~/ 60} minutes ago';
  }
}
