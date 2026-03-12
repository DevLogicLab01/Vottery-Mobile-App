import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class TrendingThemesHeatmapWidget extends StatelessWidget {
  final List<Map<String, dynamic>> themes;

  const TrendingThemesHeatmapWidget({super.key, required this.themes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bubble_chart, color: Colors.indigo[700], size: 18.sp),
              SizedBox(width: 2.w),
              Text(
                'Trending Themes Heatmap',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Most discussed topics across analyzed elections',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 1.5.h),
          if (themes.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Text(
                  'No trending themes available',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: themes.map((themeData) {
                final theme = themeData['theme'] ?? 'Unknown';
                final count = themeData['count'] ?? 0;
                final maxCount = themes.isNotEmpty
                    ? themes
                          .map((e) => e['count'] as int)
                          .reduce((a, b) => a > b ? a : b)
                    : 1;
                final intensity = count / maxCount;

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo.withOpacity(0.3 + (intensity * 0.7)),
                        Colors.purple.withOpacity(0.3 + (intensity * 0.7)),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: Colors.indigo.withOpacity(0.5 + (intensity * 0.5)),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        theme,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w,
                          vertical: 0.3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(204),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          '$count mentions',
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
