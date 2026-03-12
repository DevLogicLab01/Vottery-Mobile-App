import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class TrendingEngineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> trendingElections;

  const TrendingEngineWidget({super.key, required this.trendingElections});

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
              Icon(
                Icons.local_fire_department,
                color: Colors.orange[700],
                size: 18.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Content Trending Engine',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          if (trendingElections.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Text(
                  'No trending elections found',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            ...trendingElections.take(8).map((election) {
              final title = election['title'] ?? 'Unknown';
              final trendingScore =
                  (election['trending_score'] as num?)?.toDouble() ?? 0.0;
              final voteVelocity =
                  (election['vote_velocity'] as num?)?.toDouble() ?? 0.0;
              final commentEngagement =
                  (election['comment_engagement'] as num?)?.toDouble() ?? 0.0;
              final semanticRelevance =
                  (election['semantic_relevance'] as num?)?.toDouble() ?? 0.0;

              return Container(
                margin: EdgeInsets.only(bottom: 1.5.h),
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[50]!, Colors.red[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[700],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: Colors.white,
                                size: 12.sp,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                trendingScore.toStringAsFixed(0),
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        _buildMetric('Velocity', voteVelocity, Icons.speed),
                        SizedBox(width: 3.w),
                        _buildMetric(
                          'Engagement',
                          commentEngagement,
                          Icons.comment,
                        ),
                        SizedBox(width: 3.w),
                        _buildMetric(
                          'Relevance',
                          semanticRelevance,
                          Icons.psychology,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, double value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.sp, color: Colors.grey[600]),
        SizedBox(width: 1.w),
        Text(
          value.toStringAsFixed(1),
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
