import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EndpointConfigurationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> endpointStats;

  const EndpointConfigurationWidget({super.key, required this.endpointStats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Text(
          'REST API Endpoints',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        _buildEndpointCard(
          '/api/v1/lottery/cast-vote',
          'POST',
          'Cast vote in lottery election',
          Colors.green,
        ),
        SizedBox(height: 1.h),
        _buildEndpointCard(
          '/api/v1/lottery/verify',
          'GET',
          'Verify lottery ticket',
          Colors.blue,
        ),
        SizedBox(height: 1.h),
        _buildEndpointCard(
          '/api/v1/lottery/results',
          'GET',
          'Get lottery draw results',
          Colors.blue,
        ),
        SizedBox(height: 1.h),
        _buildEndpointCard(
          '/api/v1/audit/logs',
          'GET',
          'Retrieve audit logs',
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildEndpointCard(
    String endpoint,
    String method,
    String description,
    Color methodColor,
  ) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: methodColor,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    method,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    endpoint,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              description,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Avg Response: 120ms',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
                Text(
                  'Success: 99.2%',
                  style: TextStyle(fontSize: 10.sp, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
