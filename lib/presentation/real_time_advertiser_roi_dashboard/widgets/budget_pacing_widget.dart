import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class BudgetPacingWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final Map<String, dynamic> campaign;

  const BudgetPacingWidget({
    super.key,
    required this.analytics,
    required this.campaign,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Pacing',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text('Daily spend tracking'),
      ],
    );
  }
}
