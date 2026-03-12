import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class AudienceDemographicsWidget extends StatelessWidget {
  final Map<String, dynamic> demographics;

  const AudienceDemographicsWidget({super.key, required this.demographics});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audience Demographics',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text('Age, gender, location distribution'),
      ],
    );
  }
}
