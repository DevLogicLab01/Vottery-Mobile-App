import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class WebsocketPerformanceWidget extends StatelessWidget {
  const WebsocketPerformanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'WebSocket Performance Monitoring',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Connections: 47',
                style: GoogleFonts.inter(fontSize: 12.sp),
              ),
              SizedBox(height: 1.h),
              Text(
                'Message Latency P95: 125ms',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Connection Health: 94/100',
                style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
