import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class TranscriptAnalysisWidget extends StatelessWidget {
  final List<Map<String, dynamic>> analyses;

  const TranscriptAnalysisWidget({super.key, required this.analyses});

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
              Icon(Icons.description, color: Colors.blue[700], size: 18.sp),
              SizedBox(width: 2.w),
              Text(
                'Election Transcript Analysis',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          if (analyses.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Text(
                  'No transcript analyses available',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            ...analyses.take(5).map((analysis) {
              final election = analysis['elections'] as Map<String, dynamic>?;
              final sentimentScore =
                  (analysis['sentiment_score'] as num?)?.toDouble() ?? 0.0;
              final qualityScore =
                  (analysis['content_quality_score'] as num?)?.toDouble() ??
                  0.0;
              final viralScore =
                  (analysis['viral_potential_score'] as num?)?.toDouble() ??
                  0.0;
              final themes = analysis['key_themes'] as List<dynamic>? ?? [];

              return Container(
                margin: EdgeInsets.only(bottom: 1.5.h),
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      election?['title'] ?? 'Unknown Election',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        _buildScoreBadge(
                          'Sentiment',
                          sentimentScore,
                          Colors.blue,
                        ),
                        SizedBox(width: 2.w),
                        _buildScoreBadge('Quality', qualityScore, Colors.green),
                        SizedBox(width: 2.w),
                        _buildScoreBadge('Viral', viralScore, Colors.orange),
                      ],
                    ),
                    if (themes.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Wrap(
                        spacing: 1.w,
                        runSpacing: 0.5.h,
                        children: themes.take(3).map((theme) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              theme.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: Colors.purple[700],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(String label, double score, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 1.w),
          Text(
            score.toStringAsFixed(1),
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
