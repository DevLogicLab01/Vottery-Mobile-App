import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AIModelComparisonWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recentAnalyses;

  const AIModelComparisonWidget({super.key, required this.recentAnalyses});

  @override
  Widget build(BuildContext context) {
    final claudeAnalyses = recentAnalyses
        .where(
          (a) =>
              a['ai_results']?.any((r) => r['ai_service'] == 'claude') == true,
        )
        .toList();

    final perplexityAnalyses = recentAnalyses
        .where(
          (a) =>
              a['ai_results']?.any((r) => r['ai_service'] == 'perplexity') ==
              true,
        )
        .toList();

    final openaiAnalyses = recentAnalyses
        .where(
          (a) =>
              a['ai_results']?.any((r) => r['ai_service'] == 'openai') == true,
        )
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Model Performance Comparison',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildModelCard(
                  'Claude Sonnet 4.5',
                  claudeAnalyses,
                  Colors.purple,
                  Icons.psychology,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildModelCard(
                  'Perplexity Sonar',
                  perplexityAnalyses,
                  Colors.blue,
                  Icons.search,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildModelCard(
                  'OpenAI GPT-4o',
                  openaiAnalyses,
                  Colors.green,
                  Icons.auto_awesome,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Recent Analyses',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ...recentAnalyses
              .take(10)
              .map((analysis) => _buildAnalysisCard(analysis)),
        ],
      ),
    );
  }

  Widget _buildModelCard(
    String modelName,
    List<Map<String, dynamic>> analyses,
    Color color,
    IconData icon,
  ) {
    final avgConfidence = analyses.isEmpty
        ? 0.0
        : analyses
                  .map(
                    (a) =>
                        (a['consensus']?['average_confidence'] as num?)
                            ?.toDouble() ??
                        0.0,
                  )
                  .reduce((a, b) => a + b) /
              analyses.length;

    final successRate = analyses.isEmpty
        ? 0.0
        : analyses.where((a) => a['execution_status'] == 'automated').length /
              analyses.length;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 1.h),
          Text(
            modelName,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            '${analyses.length} analyses',
            style: TextStyle(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          _buildMetricRow(
            'Avg Confidence',
            '${(avgConfidence * 100).toStringAsFixed(1)}%',
          ),
          _buildMetricRow(
            'Success Rate',
            '${(successRate * 100).toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(Map<String, dynamic> analysis) {
    final analysisType = analysis['analysis_type'] ?? 'Unknown';
    final consensus = analysis['consensus'] ?? {};
    final hasConsensus = consensus['has_consensus'] ?? false;
    final avgConfidence =
        (consensus['average_confidence'] as num?)?.toDouble() ?? 0.0;
    final timestamp = analysis['created_at'] != null
        ? DateFormat(
            'MMM dd, HH:mm',
          ).format(DateTime.parse(analysis['created_at']))
        : 'Unknown';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: hasConsensus
              ? Colors.green.withAlpha(77)
              : Colors.orange.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasConsensus ? Icons.check_circle : Icons.warning,
                color: hasConsensus ? Colors.green : Colors.orange,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  analysisType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Text(
                timestamp,
                style: TextStyle(
                  fontSize: 9.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildBadge(
                hasConsensus ? 'Consensus' : 'No Consensus',
                hasConsensus ? Colors.green : Colors.orange,
              ),
              SizedBox(width: 2.w),
              _buildBadge(
                'Confidence: ${(avgConfidence * 100).toStringAsFixed(0)}%',
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
