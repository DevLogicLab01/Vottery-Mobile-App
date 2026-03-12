import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class AiCaptionsPanelWidget extends StatelessWidget {
  final bool isGenerating;
  final String? captionsSrt;
  final VoidCallback? onRegenerate;

  const AiCaptionsPanelWidget({
    super.key,
    required this.isGenerating,
    this.captionsSrt,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.purple.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.purple.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.closed_caption, color: Colors.purple, size: 5.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'AI Auto-Captions',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              if (onRegenerate != null)
                TextButton(
                  onPressed: isGenerating ? null : onRegenerate,
                  child: Text(
                    'Regenerate',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.purple,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          if (isGenerating)
            Row(
              children: [
                SizedBox(
                  width: 4.w,
                  height: 4.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'Generating captions with Claude AI...',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.purple,
                  ),
                ),
              ],
            )
          else if (captionsSrt != null)
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                captionsSrt!.length > 200
                    ? '${captionsSrt!.substring(0, 200)}...'
                    : captionsSrt!,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            )
          else
            Text(
              'Upload a video to generate AI captions',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
        ],
      ),
    );
  }
}