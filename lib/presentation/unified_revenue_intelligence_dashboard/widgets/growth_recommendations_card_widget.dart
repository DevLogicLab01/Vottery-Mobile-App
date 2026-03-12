import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class GrowthRecommendationsCardWidget extends StatefulWidget {
  final List<Map<String, dynamic>> recommendations;
  final Function(Map<String, dynamic>)? onImplement;
  final Function(Map<String, dynamic>)? onAnalyze;
  final Function(Map<String, dynamic>)? onDismiss;

  const GrowthRecommendationsCardWidget({
    super.key,
    required this.recommendations,
    this.onImplement,
    this.onAnalyze,
    this.onDismiss,
  });

  @override
  State<GrowthRecommendationsCardWidget> createState() =>
      _GrowthRecommendationsCardWidgetState();
}

class _GrowthRecommendationsCardWidgetState
    extends State<GrowthRecommendationsCardWidget> {
  final Set<int> _dismissedIndices = {};

  @override
  Widget build(BuildContext context) {
    final visibleRecs = widget.recommendations
        .asMap()
        .entries
        .where((e) => !_dismissedIndices.contains(e.key))
        .toList();

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF313244)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBA6F7).withAlpha(38),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFCBA6F7),
                  size: 16,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Growth Recommendations',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Powered by Claude AI',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          if (visibleRecs.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Text(
                  'All recommendations reviewed',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white38,
                  ),
                ),
              ),
            )
          else
            ...visibleRecs.map(
              (entry) => _buildRecommendationCard(entry.key, entry.value),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(int index, Map<String, dynamic> rec) {
    final impact = rec['impact'] as String? ?? 'medium';
    final impactColor = impact == 'high'
        ? const Color(0xFFA6E3A1)
        : impact == 'medium'
        ? const Color(0xFFF9E2AF)
        : const Color(0xFF89B4FA);

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: const Color(0xFF181825),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF313244)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: impactColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  impact.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    color: impactColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                rec['projected_gain'] as String? ?? '',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFA6E3A1),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          Text(
            rec['recommendation'] as String? ?? '',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            rec['rationale'] as String? ?? '',
            style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white54),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Implement',
                  const Color(0xFFA6E3A1),
                  () => widget.onImplement?.call(rec),
                ),
              ),
              SizedBox(width: 1.5.w),
              Expanded(
                child: _buildActionButton(
                  'Analyze',
                  const Color(0xFF89B4FA),
                  () => widget.onAnalyze?.call(rec),
                ),
              ),
              SizedBox(width: 1.5.w),
              Expanded(
                child: _buildActionButton('Dismiss', Colors.white38, () {
                  setState(() => _dismissedIndices.add(index));
                  widget.onDismiss?.call(rec);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 0.8.h),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
