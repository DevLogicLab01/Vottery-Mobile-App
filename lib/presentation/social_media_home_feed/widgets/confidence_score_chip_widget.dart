import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

/// Confidence score chip for Claude feed recommendations
class ConfidenceScoreChipWidget extends StatelessWidget {
  final double confidenceScore; // 0-100
  final bool showLabel;

  const ConfidenceScoreChipWidget({
    super.key,
    required this.confidenceScore,
    this.showLabel = true,
  });

  Color get _chipColor {
    if (confidenceScore >= 80) return Colors.green;
    if (confidenceScore >= 60) return Colors.orange;
    return Colors.deepOrange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: _chipColor.withAlpha(220),
        borderRadius: BorderRadius.circular(6.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: Colors.white, size: 3.w),
          SizedBox(width: 0.5.w),
          Text(
            '${confidenceScore.toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
