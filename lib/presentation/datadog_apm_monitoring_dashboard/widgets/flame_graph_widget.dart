import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FlameGraphWidget extends StatelessWidget {
  const FlameGraphWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
              Icon(
                Icons.local_fire_department,
                color: const Color(0xFF632CA6),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Flame Graph Visualization',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.zoom_in, size: 18.sp),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildFlameGraphVisualization(),
          SizedBox(height: 2.h),
          _buildBottleneckDetection(),
        ],
      ),
    );
  }

  Widget _buildFlameGraphVisualization() {
    return Container(
      height: 35.h,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildFlameGraphLayer('POST /api/vote/cast', 100, Colors.blue, 0),
          _buildFlameGraphLayer('Supabase Query', 60, Colors.green.shade700, 1),
          _buildFlameGraphLayer(
            'Blockchain Verification',
            40,
            Colors.orange,
            2,
          ),
          _buildFlameGraphLayer('Database Write', 30, Colors.red, 3),
          _buildFlameGraphLayer('Edge Function Call', 25, Colors.purple, 4),
        ],
      ),
    );
  }

  Widget _buildFlameGraphLayer(
    String label,
    double width,
    Color color,
    int level,
  ) {
    return Container(
      margin: EdgeInsets.only(
        left: (level * 5).toDouble(),
        top: 1.h,
        right: 3.w,
      ),
      height: 5.h,
      width: width.w,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${(width * 2.45).toInt()}ms',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottleneckDetection() {
    final bottlenecks = [
      {
        'operation': 'Database Query: SELECT * FROM votes',
        'duration': '1.2s',
        'severity': 'high',
        'recommendation': 'Add index on user_id column',
      },
      {
        'operation': 'Stripe Payment API Call',
        'duration': '890ms',
        'severity': 'medium',
        'recommendation': 'Implement retry logic with exponential backoff',
      },
      {
        'operation': 'Claude AI Analysis',
        'duration': '750ms',
        'severity': 'low',
        'recommendation': 'Cache frequent analysis results',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 18.sp),
            SizedBox(width: 2.w),
            Text(
              'Detected Bottlenecks',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ...bottlenecks.map((bottleneck) => _buildBottleneckItem(bottleneck)),
      ],
    );
  }

  Widget _buildBottleneckItem(Map<String, dynamic> bottleneck) {
    Color severityColor;
    switch (bottleneck['severity']) {
      case 'high':
        severityColor = Colors.red;
        break;
      case 'medium':
        severityColor = Colors.orange;
        break;
      case 'low':
        severityColor = Colors.yellow.shade700;
        break;
      default:
        severityColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: severityColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: severityColor.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  bottleneck['severity'].toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  bottleneck['operation'],
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                bottleneck['duration'],
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: severityColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 14.sp,
                color: Colors.grey[600],
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  bottleneck['recommendation'],
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
