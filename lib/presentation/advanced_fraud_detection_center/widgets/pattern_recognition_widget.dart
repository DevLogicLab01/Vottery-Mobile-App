import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PatternRecognitionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> patterns;

  const PatternRecognitionWidget({super.key, required this.patterns});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: patterns.map((pattern) => _buildPatternCard(pattern)).toList(),
    );
  }

  Widget _buildPatternCard(Map<String, dynamic> pattern) {
    final confidence = ((pattern['confidence'] as double) * 100);
    final trend = pattern['trend'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: CustomIconWidget(
                  iconName: 'pattern',
                  color: AppTheme.primaryLight,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern['pattern'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '${pattern['occurrences']} occurrences detected',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              CustomIconWidget(
                iconName: _getTrendIcon(trend),
                color: _getTrendColor(trend),
                size: 6.w,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    LinearProgressIndicator(
                      value: confidence / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getConfidenceColor(confidence),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${confidence.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _getConfidenceColor(confidence),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: _getTrendColor(trend).withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: [
                    Text(
                      'Trend',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      trend.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: _getTrendColor(trend),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'increasing':
        return 'trending_up';
      case 'decreasing':
        return 'trending_down';
      case 'stable':
        return 'trending_flat';
      default:
        return 'remove';
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'increasing':
        return Colors.red;
      case 'decreasing':
        return Colors.green;
      case 'stable':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }
}
