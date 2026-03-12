import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class ThresholdStatusCardWidget extends StatelessWidget {
  final String title;
  final String metric;
  final double currentValue;
  final double threshold;
  final bool isBreached;
  final String unit;
  final IconData icon;

  const ThresholdStatusCardWidget({
    super.key,
    required this.title,
    required this.metric,
    required this.currentValue,
    required this.threshold,
    required this.isBreached,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isBreached ? Colors.red : Colors.green;
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: statusColor.withAlpha(80), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: statusColor, size: 5.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  isBreached ? 'BREACHED' : 'OK',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            metric,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current: ${currentValue.toStringAsFixed(1)}$unit',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              Text(
                'Threshold: $threshold$unit',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          LinearProgressIndicator(
            value: isBreached
                ? (currentValue / threshold).clamp(0.0, 1.0)
                : (currentValue / threshold).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.withAlpha(50),
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ],
      ),
    );
  }
}
