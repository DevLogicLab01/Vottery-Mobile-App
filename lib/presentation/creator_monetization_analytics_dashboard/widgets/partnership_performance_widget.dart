import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class PartnershipPerformanceWidget extends StatelessWidget {
  final List<Map<String, dynamic>> partnershipPerformance;

  const PartnershipPerformanceWidget({
    super.key,
    required this.partnershipPerformance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Text(
            'Partnership Performance',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
