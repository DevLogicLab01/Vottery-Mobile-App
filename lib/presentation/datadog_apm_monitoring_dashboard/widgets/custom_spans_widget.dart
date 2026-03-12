import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CustomSpansWidget extends StatelessWidget {
  const CustomSpansWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final customSpans = [
      {
        'journey': 'Vote Casting with Blockchain',
        'avgDuration': '2.4s',
        'p95': '3.8s',
        'successRate': '99.2%',
        'icon': Icons.how_to_vote,
        'color': Colors.blue,
      },
      {
        'journey': 'Payment Processing (Stripe)',
        'avgDuration': '1.8s',
        'p95': '2.9s',
        'successRate': '97.8%',
        'icon': Icons.payment,
        'color': Colors.purple,
      },
      {
        'journey': 'Election Creation Workflow',
        'avgDuration': '890ms',
        'p95': '1.5s',
        'successRate': '99.8%',
        'icon': Icons.create,
        'color': Colors.green,
      },
      {
        'journey': 'Prize Distribution',
        'avgDuration': '1.2s',
        'p95': '2.1s',
        'successRate': '98.5%',
        'icon': Icons.card_giftcard,
        'color': Colors.orange,
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
              Icon(Icons.route, color: const Color(0xFF632CA6), size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Critical User Journeys',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...customSpans.map((span) => _buildSpanItem(span)),
        ],
      ),
    );
  }

  Widget _buildSpanItem(Map<String, dynamic> span) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: (span['color'] as Color).withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: (span['color'] as Color).withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.5.w),
                decoration: BoxDecoration(
                  color: span['color'],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(span['icon'], color: Colors.white, size: 18.sp),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  span['journey'],
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricChip(
                  'Avg',
                  span['avgDuration'],
                  Icons.timer,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricChip('P95', span['p95'], Icons.trending_up),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricChip(
                  'Success',
                  span['successRate'],
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14.sp, color: Colors.grey[600]),
          SizedBox(height: 0.3.h),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
