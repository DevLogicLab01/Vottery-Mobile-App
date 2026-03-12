import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/claude_decision_reasoning_service.dart';
import './reasoning_chain_visualization_widget.dart';
import './confidence_score_gauge_widget.dart';

class DisputeAnalysisResultPanel extends StatelessWidget {
  final DisputeAnalysisResult result;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onManualReview;

  const DisputeAnalysisResultPanel({
    super.key,
    required this.result,
    this.onApprove,
    this.onReject,
    this.onManualReview,
  });

  Color _getResolutionColor(String resolution) {
    switch (resolution) {
      case 'approve':
        return Colors.green.shade600;
      case 'deny':
        return Colors.red.shade600;
      case 'partial_refund':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'low':
        return Colors.green.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'high':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConfidenceScoreGaugeWidget(
            userFavor: result.confidence,
            merchantFavor: 100 - result.confidence,
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: _getResolutionColor(
                result.recommendedResolution,
              ).withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: _getResolutionColor(result.recommendedResolution),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.gavel,
                      color: _getResolutionColor(result.recommendedResolution),
                      size: 16.sp,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Recommended Resolution',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  result.recommendedResolution
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: _getResolutionColor(result.recommendedResolution),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  result.justification,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          ReasoningChainVisualizationWidget(
            reasoningChain: result.reasoningChain.map((step) => {'step': step}).toList(),
          ),
          SizedBox(height: 2.h),
          if (result.policyCitations.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.policy, color: Colors.blue.shade600, size: 16.sp),
                SizedBox(width: 2.w),
                Text(
                  'Policy Citations',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            ...result.policyCitations.map(
              (citation) => Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (citation['policy_id']?.toString() ?? ''),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      (citation['policy_text']?.toString() ?? ''),
                      style: GoogleFonts.inter(fontSize: 11.sp),
                    ),
                    Text(
                      'Relevance: ${(citation['relevance_to_case']?.toString() ?? 'N/A')}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 1.h),
          ],
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: _getRiskColor(result.appealRisk),
                size: 16.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Appeal Risk: ',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                result.appealRisk.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: _getRiskColor(result.appealRisk),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              if (result.confidence > 90 && onApprove != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: Icon(Icons.check_circle, size: 14.sp),
                    label: Text(
                      'Auto Approve',
                      style: GoogleFonts.inter(fontSize: 11.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              if (result.confidence >= 60 &&
                  result.confidence <= 90 &&
                  onManualReview != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onManualReview,
                    icon: Icon(Icons.person_search, size: 14.sp),
                    label: Text(
                      'Manual Review',
                      style: GoogleFonts.inter(fontSize: 11.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              if (result.confidence < 40 && onReject != null) ...[
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReject,
                    icon: Icon(Icons.cancel, size: 14.sp),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.inter(fontSize: 11.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class FraudInvestigationResultPanel extends StatelessWidget {
  final dynamic result;

  const FraudInvestigationResultPanel({super.key, required this.result});

  Color _getProbabilityColor(double prob) {
    if (prob > 80) return Colors.red.shade600;
    if (prob > 60) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: _getProbabilityColor(
                result.fraudProbability,
              ).withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: _getProbabilityColor(result.fraudProbability),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(
                        value: result.fraudProbability / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProbabilityColor(result.fraudProbability),
                        ),
                      ),
                    ),
                    Text(
                      '${result.fraudProbability.toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fraud Probability',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        result.recommendedAction
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: _getProbabilityColor(result.fraudProbability),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          ReasoningChainVisualizationWidget(
            reasoningChain: result.investigationSteps,
            title: 'Investigation Chain',
          ),
          if (result.evidenceGaps.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(
                  Icons.search_off,
                  color: Colors.orange.shade600,
                  size: 16.sp,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Evidence Gaps',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            ...result.evidenceGaps.map<Widget>(
              (gap) => Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8.sp,
                      color: Colors.orange.shade600,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        gap.toString(),
                        style: GoogleFonts.inter(fontSize: 11.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}