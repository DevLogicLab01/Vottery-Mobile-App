import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class ConversionTrackingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> conversionTimeline;

  const ConversionTrackingWidget({super.key, required this.conversionTimeline});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conversion Tracking',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text('${conversionTimeline.length} data points'),
      ],
    );
  }
}
