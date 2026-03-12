import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';
import '../../../services/claude_feed_curation_service.dart';
import './confidence_score_chip_widget.dart';

/// Recommendation sidebar showing live Claude confidence scores
/// Accepts both FeedRecommendation objects and legacy Map<String, dynamic>
class RecommendationSidebarWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;
  final List<FeedRecommendation>? liveRecommendations;
  final VoidCallback? onClose;

  const RecommendationSidebarWidget({
    super.key,
    required this.recommendations,
    this.liveRecommendations,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final hasLive =
        liveRecommendations != null && liveRecommendations!.isNotEmpty;
    final itemCount = hasLive
        ? liveRecommendations!.length
        : recommendations.length;

    return Container(
      width: 70.w,
      height: double.infinity,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Why you\'re seeing this',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                        if (hasLive)
                          Row(
                            children: [
                              Container(
                                width: 2.w,
                                height: 2.w,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                'Live Claude AI',
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(4.w),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (hasLive) {
                    return _buildLiveRecommendationItem(
                      liveRecommendations![index],
                    );
                  }
                  return _buildRecommendationItem(recommendations[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveRecommendationItem(FeedRecommendation rec) {
    final confidence = rec.confidenceScore;
    final title =
        rec.feedItem['title'] as String? ??
        rec.feedItem['content'] as String? ??
        'Recommended Content';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.withAlpha(40)),
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
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              SizedBox(width: 2.w),
              ConfidenceScoreChipWidget(confidenceScore: confidence),
            ],
          ),
          SizedBox(height: 1.h),
          _buildSignalRow(
            Icons.interests,
            'Interest match',
            rec.interestAlignment,
            Colors.blue,
          ),
          _buildSignalRow(
            Icons.people,
            'Social proof',
            rec.socialProof,
            Colors.purple,
          ),
          // Reasoning tooltip
          GestureDetector(
            onTap: () {},
            child: _buildSignalRow(
              Icons.auto_awesome,
              'AI reasoning',
              rec.reasoning,
              confidence >= 80
                  ? Colors.green
                  : confidence >= 60
                  ? Colors.orange
                  : Colors.deepOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> rec) {
    final confidence = (rec['confidence_score'] ?? 75.0).toDouble();
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rec['title'] ?? 'Recommended Content',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              SizedBox(width: 2.w),
              ConfidenceScoreChipWidget(confidenceScore: confidence),
            ],
          ),
          SizedBox(height: 1.h),
          if (rec['interest_alignment'] != null)
            _buildSignalRow(
              Icons.interests,
              'Interest match',
              rec['interest_alignment'],
              Colors.blue,
            ),
          if (rec['social_proof'] != null)
            _buildSignalRow(
              Icons.people,
              'Social proof',
              rec['social_proof'],
              Colors.purple,
            ),
          _buildSignalRow(
            Icons.auto_awesome,
            'AI confidence',
            '${confidence.toStringAsFixed(0)}%',
            confidence >= 80
                ? Colors.green
                : confidence >= 60
                ? Colors.orange
                : Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildSignalRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          Icon(icon, color: color, size: 3.5.w),
          SizedBox(width: 1.5.w),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
