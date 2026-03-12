import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class ZoneRoiBreakdownWidget extends StatelessWidget {
  final Map<String, int> zoneReach;
  final Map<String, int> zoneConversions;

  const ZoneRoiBreakdownWidget({
    super.key,
    required this.zoneReach,
    required this.zoneConversions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zone ROI Breakdown',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text('${zoneReach.length} zones tracked'),
      ],
    );
  }
}
