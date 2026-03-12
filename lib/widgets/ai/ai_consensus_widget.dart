import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/ai_orchestrator_service.dart';
import '../../models/ai_consensus_result.dart';

class AIConsensusWidget extends StatelessWidget {
  final String analysisType;
  final Map<String, dynamic> context;

  const AIConsensusWidget({
    super.key,
    required this.analysisType,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AIConsensusResult>(
      future: AIOrchestratorService.analyzeWithConsensus(
        context: jsonEncode(this.context),
        analysisType: analysisType,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final result = snapshot.data!;
        return _buildConsensusResult(result, context);
      },
    );
  }

  Widget _buildLoadingState() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 2.h),
            Text(
              'AI Consensus Analysis in Progress',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            SizedBox(height: 1.h),
            Text(
              'Analyzing with multiple AI providers...',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Card(
      elevation: 4,
      color: Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 2.h),
            Text(
              'Analysis Failed',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Colors.red[900],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Unable to complete AI consensus analysis',
              style: TextStyle(fontSize: 12.sp, color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsensusResult(AIConsensusResult result, BuildContext context) {
    final theme = Theme.of(context);
    final hasConsensus = result.confidenceScore >= 0.8;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.blue),
                SizedBox(width: 2.w),
                Text(
                  'AI Consensus Analysis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                const Spacer(),
                _buildConfidenceIndicator(result.confidenceScore, theme),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              result.finalRecommendation,
              style: TextStyle(
                fontSize: 13.sp,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2.h),
            _buildAIProviderResults(result.providerResponses, theme),
            if (hasConsensus) ...[
              SizedBox(height: 2.h),
              _buildActionButton(result, context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence, ThemeData theme) {
    final percentage = (confidence * 100).round();
    Color indicatorColor;

    if (confidence >= 0.8) {
      indicatorColor = Colors.green;
    } else if (confidence >= 0.6) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: indicatorColor),
      ),
      child: Text(
        '$percentage% Confidence',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: indicatorColor,
        ),
      ),
    );
  }

  Widget _buildAIProviderResults(
    List<AIProviderResponse> results,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provider Results',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
        ),
        SizedBox(height: 1.h),
        ...results.map(
          (provider) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: _getProviderColor(provider.provider),
              child: Text(
                provider.provider[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              provider.provider.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
            ),
            subtitle: Text(
              provider.response['recommendation']?.toString() ??
                  'No recommendation',
              style: TextStyle(fontSize: 11.sp),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              '${(provider.confidence * 100).round()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                color: _getConfidenceColor(provider.confidence),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getProviderColor(String providerName) {
    switch (providerName.toLowerCase()) {
      case 'openai':
        return Colors.green;
      case 'anthropic':
        return Colors.purple;
      case 'perplexity':
        return Colors.blue;
      case 'gemini':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildActionButton(AIConsensusResult result, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Action handler for consensus result
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Consensus action: ${result.finalRecommendation}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.check_circle),
        label: const Text('Apply Recommendation'),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
