import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class ComplianceStatusWidget extends StatelessWidget {
  final Map<String, String> complianceStatus;

  const ComplianceStatusWidget({super.key, required this.complianceStatus});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compliance Status',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text('${complianceStatus.length} zones tracked'),
      ],
    );
  }
}
