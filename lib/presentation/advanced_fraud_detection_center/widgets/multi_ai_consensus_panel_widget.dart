import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MultiAIConsensusPanelWidget extends StatelessWidget {
  final Map<String, dynamic> consensusData;

  const MultiAIConsensusPanelWidget({super.key, required this.consensusData});

  @override
  Widget build(BuildContext context) {
    final aiResults = consensusData['ai_results'] as List? ?? [];
    final consensus = consensusData['consensus'] as Map? ?? {};
    final recommendation = consensusData['recommendation'] as Map? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConsensusHeader(consensus),
        SizedBox(height: 2.h),
        Text(
          'AI Service Results',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        ...aiResults.map((result) => _buildAIResultCard(result)),
        SizedBox(height: 2.h),
        _buildRecommendationCard(recommendation),
      ],
    );
  }

  Widget _buildConsensusHeader(Map consensus) {
    final hasConsensus = consensus['has_consensus'] == true;
    final agreementLevel =
        (consensus['agreement_level'] as double? ?? 0.0) * 100;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasConsensus
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: hasConsensus ? 'check_circle' : 'warning',
            color: Colors.white,
            size: 8.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasConsensus ? 'Consensus Detected' : 'No Consensus',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${agreementLevel.toStringAsFixed(1)}% AI Agreement',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIResultCard(Map result) {
    final aiService = result['ai_service'] as String? ?? 'unknown';
    final confidence = (result['confidence'] as double? ?? 0.0) * 100;
    final model = result['model'] as String? ?? 'N/A';

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: _getAIServiceColor(aiService).withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: CustomIconWidget(
              iconName: 'psychology',
              color: _getAIServiceColor(aiService),
              size: 6.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aiService.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  'Model: $model',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${confidence.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: _getConfidenceColor(confidence),
                ),
              ),
              Text(
                'Confidence',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map recommendation) {
    final action = recommendation['action'] as String? ?? 'manual_review';
    final confidence = (recommendation['confidence'] as double? ?? 0.0) * 100;
    final reasoning = recommendation['reasoning'] as String? ?? 'N/A';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'lightbulb',
                color: Colors.blue.shade700,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Recommended Action',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              action.toUpperCase().replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            reasoning,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: confidence / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getConfidenceColor(confidence),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Confidence: ${confidence.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAIServiceColor(String service) {
    switch (service.toLowerCase()) {
      case 'openai':
        return Color(0xFF10A37F);
      case 'claude':
        return Color(0xFFD97757);
      case 'perplexity':
        return Color(0xFF1FB6FF);
      default:
        return Colors.grey;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }
}
