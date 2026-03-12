import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DistributedTracingWidget extends StatelessWidget {
  const DistributedTracingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final traces = [
      {
        'id': 'trace-001',
        'operation': 'POST /api/vote/cast',
        'duration': '245ms',
        'spans': 12,
        'status': 'success',
        'timestamp': '2 min ago',
      },
      {
        'id': 'trace-002',
        'operation': 'GET /api/elections/list',
        'duration': '89ms',
        'spans': 8,
        'status': 'success',
        'timestamp': '5 min ago',
      },
      {
        'id': 'trace-003',
        'operation': 'POST /api/payment/process',
        'duration': '1.2s',
        'spans': 15,
        'status': 'slow',
        'timestamp': '8 min ago',
      },
      {
        'id': 'trace-004',
        'operation': 'GET /api/user/profile',
        'duration': '3.5s',
        'spans': 10,
        'status': 'error',
        'timestamp': '12 min ago',
      },
    ];

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: const Color(0xFF632CA6), size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Recent Traces',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...traces.map((trace) => _buildTraceItem(context, trace)),
        ],
      ),
    );
  }

  Widget _buildTraceItem(BuildContext context, Map<String, dynamic> trace) {
    Color statusColor;
    switch (trace['status']) {
      case 'success':
        statusColor = Colors.green;
        break;
      case 'slow':
        statusColor = Colors.orange;
        break;
      case 'error':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  trace['operation'],
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                trace['timestamp'],
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildInfoChip('Duration', trace['duration'], Icons.timer),
              SizedBox(width: 2.w),
              _buildInfoChip('Spans', '${trace['spans']}', Icons.layers),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF632CA6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: Colors.grey[600]),
          SizedBox(width: 1.w),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
