import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

/// Rhythm of 3 Feed Section - groups feed items in sets of 3
/// Section 1: Featured Elections, Section 2: Jolts, Section 3: Groups
class RhythmOf3SectionWidget extends StatelessWidget {
  final int sectionIndex; // 0=Elections, 1=Jolts, 2=Groups
  final List<Widget> children;
  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onSeeAll;

  const RhythmOf3SectionWidget({
    super.key,
    required this.sectionIndex,
    required this.children,
    required this.title,
    required this.icon,
    required this.accentColor,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.0), // 24dp consistent spacing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(1.5.w),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(icon, color: accentColor, size: 4.5.w),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
                if (onSeeAll != null)
                  TextButton(
                    onPressed: onSeeAll,
                    child: Text(
                      'See All',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Section content
          ...children,
          // Visual rhythm divider
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
            child: Divider(color: accentColor.withAlpha(40), thickness: 1.5),
          ),
        ],
      ),
    );
  }
}
