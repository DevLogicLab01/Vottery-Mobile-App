import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class PayoutHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> payoutHistory;
  final Function(Map<String, dynamic>) onFilterApplied;

  const PayoutHistoryWidget({
    super.key,
    required this.payoutHistory,
    required this.onFilterApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payout History',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text('${payoutHistory.length} payouts'),
      ],
    );
  }
}
