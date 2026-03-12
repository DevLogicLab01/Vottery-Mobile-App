import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Story-style horizontal scroll for active prediction pools
class StoryScrollWidget extends StatelessWidget {
  final List<Map<String, dynamic>> predictionPools;
  final Function(String) onPoolTap;

  const StoryScrollWidget({
    super.key,
    required this.predictionPools,
    required this.onPoolTap,
  });

  @override
  Widget build(BuildContext context) {
    if (predictionPools.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 15.h,
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: predictionPools.length,
        itemBuilder: (context, index) {
          final pool = predictionPools[index];
          final title = pool['title'] as String? ?? 'Prediction Pool';
          final prizePool = pool['prize_pool_vp'] as int? ?? 0;
          final closesAt = pool['closes_at'] as String?;

          return GestureDetector(
            onTap: () => onPoolTap(pool['id'] as String),
            child: Container(
              width: 35.w,
              margin: EdgeInsets.only(right: 3.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryLight, AppTheme.secondaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomIconWidget(
                    iconName: 'trending_up',
                    size: 6.w,
                    color: Colors.white,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '$prizePool VP Prize',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
