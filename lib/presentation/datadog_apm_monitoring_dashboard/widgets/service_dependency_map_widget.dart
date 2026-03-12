import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ServiceDependencyMapWidget extends StatelessWidget {
  const ServiceDependencyMapWidget({super.key});

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
                Icons.account_tree,
                color: const Color(0xFF632CA6),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Service Dependency Map',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          _buildDependencyGraph(),
          SizedBox(height: 3.h),
          _buildServicesList(),
        ],
      ),
    );
  }

  Widget _buildDependencyGraph() {
    return Container(
      height: 30.h,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildServiceNode('Flutter App', Colors.blue, true),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    _buildConnectionLine(),
                    _buildServiceNode('Supabase', Colors.green, false),
                  ],
                ),
                Column(
                  children: [
                    _buildConnectionLine(),
                    _buildServiceNode('Edge Functions', Colors.orange, false),
                  ],
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    _buildConnectionLine(),
                    _buildServiceNode('Stripe', Colors.purple, false),
                  ],
                ),
                Column(
                  children: [
                    _buildConnectionLine(),
                    _buildServiceNode('Twilio', Colors.red, false),
                  ],
                ),
                Column(
                  children: [
                    _buildConnectionLine(),
                    _buildServiceNode('OpenAI', Colors.teal, false),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceNode(String name, Color color, bool isRoot) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: isRoot ? 13.sp : 11.sp,
          fontWeight: isRoot ? FontWeight.w700 : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildConnectionLine() {
    return Container(width: 2, height: 2.h, color: Colors.grey[400]);
  }

  Widget _buildServicesList() {
    final services = [
      {
        'name': 'Supabase Database',
        'status': 'healthy',
        'latency': '45ms',
        'requests': '1.2K/min',
      },
      {
        'name': 'Stripe API',
        'status': 'healthy',
        'latency': '120ms',
        'requests': '85/min',
      },
      {
        'name': 'Twilio SMS',
        'status': 'degraded',
        'latency': '350ms',
        'requests': '42/min',
      },
      {
        'name': 'OpenAI API',
        'status': 'healthy',
        'latency': '890ms',
        'requests': '120/min',
      },
      {
        'name': 'Anthropic Claude',
        'status': 'healthy',
        'latency': '750ms',
        'requests': '95/min',
      },
      {
        'name': 'Perplexity AI',
        'status': 'healthy',
        'latency': '680ms',
        'requests': '78/min',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Health',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 1.h),
        ...services.map((service) => _buildServiceItem(service)),
      ],
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    Color statusColor = service['status'] == 'healthy'
        ? Colors.green
        : service['status'] == 'degraded'
        ? Colors.orange
        : Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
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
              service['name'],
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Text(
            service['latency'],
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(width: 2.w),
          Text(
            service['requests'],
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
