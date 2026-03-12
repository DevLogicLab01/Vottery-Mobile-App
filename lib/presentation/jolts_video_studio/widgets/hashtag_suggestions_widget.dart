import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class HashtagSuggestionsWidget extends StatelessWidget {
  final List<String> suggestedHashtags;
  final List<String> selectedHashtags;
  final Function(String) onHashtagToggled;
  final VoidCallback? onRefresh;

  const HashtagSuggestionsWidget({
    super.key,
    required this.suggestedHashtags,
    required this.selectedHashtags,
    required this.onHashtagToggled,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tag, color: AppTheme.primaryLight, size: 5.w),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'AI Hashtag Suggestions',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ),
            if (onRefresh != null)
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: AppTheme.primaryLight,
                  size: 5.w,
                ),
                onPressed: onRefresh,
              ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'Tap to add hashtags to your Jolt',
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        SizedBox(height: 1.5.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: suggestedHashtags
              .map((hashtag) => _buildHashtagChip(hashtag))
              .toList(),
        ),
        if (selectedHashtags.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            'Selected (${selectedHashtags.length})',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: selectedHashtags
                .map(
                  (h) => Chip(
                    label: Text(
                      h,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppTheme.primaryLight,
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                    onDeleted: () => onHashtagToggled(h),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildHashtagChip(String hashtag) {
    final isSelected = selectedHashtags.contains(hashtag);
    return GestureDetector(
      onTap: () => onHashtagToggled(hashtag),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight
              : AppTheme.primaryLight.withAlpha(20),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryLight
                : AppTheme.primaryLight.withAlpha(80),
          ),
        ),
        child: Text(
          hashtag,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: isSelected ? Colors.white : AppTheme.primaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
