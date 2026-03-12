import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ScreenLoadMetricsWidget extends StatelessWidget {
  const ScreenLoadMetricsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screens = [
      {'name': 'Vote Casting', 'load_time': 2345, 'status': 'slow'},
      {'name': 'Social Feed', 'load_time': 1876, 'status': 'ok'},
      {'name': 'Profile', 'load_time': 1234, 'status': 'fast'},
    ];

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Screen Load Time Tracking',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        ...screens.map(
          (screen) => Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  screen['name'].toString(),
                  style: GoogleFonts.inter(fontSize: 12.sp),
                ),
                Text(
                  '${screen['load_time']}ms',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: (screen['load_time'] as int) > 2000
                        ? Colors.red
                        : Colors.green,
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
