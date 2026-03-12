import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class PerformancePreviewWidget extends StatelessWidget {
  final int estimatedViews;
  final double watchTimePrediction;
  final int hashtagCount;
  final bool hasSound;
  final bool hasCaptions;

  const PerformancePreviewWidget({
    super.key,
    required this.estimatedViews,
    required this.watchTimePrediction,
    required this.hashtagCount,
    required this.hasSound,
    required this.hasCaptions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Preview',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          'ML-powered prediction based on your content',
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Views (24h)',
                _formatCount(estimatedViews),
                Icons.visibility,
                Colors.blue,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildMetricCard(
                'Watch Time',
                '${(watchTimePrediction * 100).toStringAsFixed(0)}%',
                Icons.timer,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'Optimization Checklist',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        _buildCheckItem(
          'Hashtags added',
          hashtagCount > 0,
          '$hashtagCount tags',
        ),
        _buildCheckItem(
          'Trending sound',
          hasSound,
          hasSound ? 'Sound attached' : 'Add a sound +15%',
        ),
        _buildCheckItem(
          'AI captions',
          hasCaptions,
          hasCaptions ? 'Captions ready' : 'Generate captions +10%',
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(20),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.amber.withAlpha(80)),
          ),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates, color: Colors.amber, size: 5.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Post between 6-8 PM for maximum engagement based on your audience activity',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool isComplete, String detail) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isComplete ? Colors.green : Colors.grey,
            size: 4.5.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textPrimaryLight,
                fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            detail,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: isComplete ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return count.toString();
  }
}
