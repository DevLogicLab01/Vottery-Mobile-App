import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class CampaignComparisonWidget extends StatelessWidget {
  final List<Map<String, dynamic>> campaigns;
  final int currentIndex;
  final Function(int) onSwipe;

  const CampaignComparisonWidget({
    super.key,
    required this.campaigns,
    required this.currentIndex,
    required this.onSwipe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campaign Comparison',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text('Swipe to compare ${campaigns.length} campaigns'),
      ],
    );
  }
}
