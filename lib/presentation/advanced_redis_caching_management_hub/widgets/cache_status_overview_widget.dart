import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CacheStatusOverviewWidget extends StatelessWidget {
  const CacheStatusOverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: const BoxDecoration(
        color: Color(0xFF632CA6),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              'Hit Ratio',
              '94.2%',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatusCard(
              'Memory',
              '2.4 GB',
              Icons.memory,
              Colors.blue,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatusCard(
              'Performance',
              '+68%',
              Icons.trending_up,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
