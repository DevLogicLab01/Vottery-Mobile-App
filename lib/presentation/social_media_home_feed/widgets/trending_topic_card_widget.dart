import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


/// Enhanced Trending Topic Card Widget
/// Large hashtag, fire meter, post count, growth indicator, explore CTA
class TrendingTopicCardWidget extends StatelessWidget {
  final Map<String, dynamic> topic;

  const TrendingTopicCardWidget({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final hashtag = topic['hashtag'] as String? ?? '#Trending';
    final trendScore = (topic['trend_score'] as num? ?? 0).toInt();
    final postCount = topic['post_count'] as int? ?? 0;
    final growthPct = (topic['growth_percentage'] as num? ?? 0).toDouble();
    final isGrowing = growthPct >= 0;
    final relatedTopics =
        (topic['related_topics'] as List?)?.cast<String>() ?? [];

    return Padding(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hashtag + fire meter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hashtag.startsWith('#') ? hashtag : '#$hashtag',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(color: Colors.black.withAlpha(100), blurRadius: 4),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.5.h),
              // Fire meter
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Text(
                      i < (trendScore / 20).round() ? '🔥' : '⬜',
                      style: TextStyle(fontSize: 9.sp),
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '$trendScore',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.article_rounded,
                    color: Colors.white.withAlpha(180),
                    size: 3.5.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${_formatCount(postCount)} posts',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(
                    isGrowing
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: isGrowing
                        ? const Color(0xFF2ED573)
                        : const Color(0xFFFF4757),
                    size: 3.5.w,
                  ),
                  SizedBox(width: 0.5.w),
                  Text(
                    '${isGrowing ? '+' : ''}${growthPct.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: isGrowing
                          ? const Color(0xFF2ED573)
                          : const Color(0xFFFF4757),
                    ),
                  ),
                ],
              ),
              if (relatedTopics.isNotEmpty) ...[
                SizedBox(height: 0.5.h),
                Wrap(
                  spacing: 1.w,
                  children: relatedTopics
                      .take(3)
                      .map(
                        (t) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 1.5.w,
                            vertical: 0.2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            t.startsWith('#') ? t : '#$t',
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              SizedBox(height: 0.8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: Colors.white.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Explore →',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
