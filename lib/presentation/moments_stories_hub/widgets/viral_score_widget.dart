import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

/// Viral score display widget for Moments
class ViralScoreWidget extends StatelessWidget {
  final double viralScore; // 0-100
  final String? message;

  const ViralScoreWidget({super.key, required this.viralScore, this.message});

  Color get _scoreColor {
    if (viralScore >= 70) return Colors.green;
    if (viralScore >= 40) return Colors.orange;
    return Colors.red;
  }

  String get _scoreLabel {
    if (viralScore >= 70) return 'High engagement expected';
    if (viralScore >= 40) return 'Moderate engagement expected';
    return 'Low engagement expected';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _scoreColor.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _scoreColor.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: _scoreColor, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Viral Score',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              const Spacer(),
              Text(
                '${viralScore.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: _scoreColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: viralScore / 100,
              backgroundColor: Colors.grey.withAlpha(50),
              valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            message ?? _scoreLabel,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: _scoreColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
