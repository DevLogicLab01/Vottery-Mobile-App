import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class ContentOptimizationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;

  const ContentOptimizationWidget({super.key, required this.suggestions});

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
              Icon(Icons.lightbulb, color: Colors.amber[700], size: 18.sp),
              SizedBox(width: 2.w),
              Text(
                'Content Optimization Suggestions',
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
            'Claude-powered recommendations for low-performing content',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 1.5.h),
          if (suggestions.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
                    SizedBox(height: 1.h),
                    Text(
                      'All content is performing well!',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...suggestions.take(5).map((suggestion) {
              final election = suggestion['elections'] as Map<String, dynamic>?;
              final qualityScore =
                  (suggestion['content_quality_score'] as num?)?.toDouble() ??
                  0.0;
              final sentimentScore =
                  (suggestion['sentiment_score'] as num?)?.toDouble() ?? 0.0;

              return Container(
                margin: EdgeInsets.only(bottom: 1.5.h),
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            election?['title'] ?? 'Unknown Election',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
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
                            color: _getQualityColor(qualityScore),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            'Quality: ${qualityScore.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💡 Optimization Recommendations:',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            _generateRecommendation(
                              qualityScore,
                              sentimentScore,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _getQualityColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  String _generateRecommendation(double quality, double sentiment) {
    if (quality < 40) {
      return 'Improve candidate descriptions with more specific details and compelling narratives. Consider adding visual elements.';
    } else if (sentiment < 0) {
      return 'Reframe negative sentiment with balanced perspectives. Focus on constructive dialogue and solution-oriented framing.';
    } else {
      return 'Enhance engagement by adding clear voting instructions and highlighting key decision points for voters.';
    }
  }
}
