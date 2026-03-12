import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RankingExplanationWidget extends StatelessWidget {
  final Map<String, dynamic> item;

  const RankingExplanationWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final rankingExplanation = item['ranking_explanation'] ?? {};
    final reasonTags = List<String>.from(
      rankingExplanation['reason_tags'] ?? [],
    );
    final finalScore = item['final_ranking_score'] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['title'] ?? item['name'] ?? 'Content Item',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getScoreColor(finalScore).withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  finalScore.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: _getScoreColor(finalScore),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          if (reasonTags.isNotEmpty)
            Wrap(
              spacing: 1.w,
              runSpacing: 0.5.h,
              children: reasonTags.map((tag) => _buildReasonTag(tag)).toList(),
            ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildScoreBar(
                  'Semantic',
                  rankingExplanation['semantic_similarity'] ?? 0.0,
                  Colors.purple,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildScoreBar(
                  'Collaborative',
                  rankingExplanation['collaborative_filtering'] ?? 0.0,
                  Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildScoreBar(
                  'Recency',
                  rankingExplanation['recency_boost'] ?? 0.0,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildScoreBar(
                  'Popularity',
                  rankingExplanation['popularity_boost'] ?? 0.0,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonTag(String tag) {
    final displayText = tag.replaceAll('_', ' ').toUpperCase();
    final tagColor = _getTagColor(tag);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: tagColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: tagColor.withAlpha(77)),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w500,
          color: tagColor,
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
            ),
            Text(
              score.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: score.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getTagColor(String tag) {
    if (tag.contains('similar')) return Colors.purple;
    if (tag.contains('popular')) return Colors.blue;
    if (tag.contains('trending')) return Colors.orange;
    return Colors.grey;
  }
}
