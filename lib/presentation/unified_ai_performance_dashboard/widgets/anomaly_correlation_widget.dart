import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AnomalyCorrelationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recentAnalyses;

  const AnomalyCorrelationWidget({super.key, required this.recentAnalyses});

  @override
  Widget build(BuildContext context) {
    final correlatedAnomalies = _detectCorrelatedAnomalies();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automated Anomaly Correlation',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'AI models showing consensus across ${correlatedAnomalies.length} anomaly patterns',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (correlatedAnomalies.isEmpty)
            _buildEmptyState()
          else
            ...correlatedAnomalies.map(
              (correlation) => _buildCorrelationCard(correlation),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _detectCorrelatedAnomalies() {
    final correlations = <Map<String, dynamic>>[];

    // Group analyses by time window (1 hour)
    final timeGroups = <String, List<Map<String, dynamic>>>{};
    for (var analysis in recentAnalyses) {
      if (analysis['created_at'] != null) {
        final timestamp = DateTime.parse(analysis['created_at']);
        final hourKey = DateFormat('yyyy-MM-dd HH').format(timestamp);
        timeGroups[hourKey] = [...(timeGroups[hourKey] ?? []), analysis];
      }
    }

    // Detect correlations within time windows
    for (var entry in timeGroups.entries) {
      final analyses = entry.value;
      if (analyses.length >= 2) {
        final consensusAnalyses = analyses
            .where((a) => a['consensus']?['has_consensus'] == true)
            .toList();

        if (consensusAnalyses.length >= 2) {
          final avgConfidence =
              consensusAnalyses
                  .map(
                    (a) =>
                        (a['consensus']?['average_confidence'] as num?)
                            ?.toDouble() ??
                        0.0,
                  )
                  .reduce((a, b) => a + b) /
              consensusAnalyses.length;

          correlations.add({
            'time_window': entry.key,
            'analyses': consensusAnalyses,
            'correlation_strength': avgConfidence,
            'pattern_count': consensusAnalyses.length,
          });
        }
      }
    }

    // Sort by correlation strength
    correlations.sort(
      (a, b) => (b['correlation_strength'] as double).compareTo(
        a['correlation_strength'] as double,
      ),
    );

    return correlations;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, color: Colors.blue, size: 15.w),
          SizedBox(height: 2.h),
          Text(
            'No Correlated Anomalies',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'No patterns detected across multiple AI models in recent analyses',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationCard(Map<String, dynamic> correlation) {
    final timeWindow = correlation['time_window'] ?? 'Unknown';
    final analyses =
        correlation['analyses'] as List<Map<String, dynamic>>? ?? [];
    final correlationStrength =
        (correlation['correlation_strength'] as num?)?.toDouble() ?? 0.0;
    final patternCount = correlation['pattern_count'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: correlationStrength >= 0.8
              ? Colors.green.withAlpha(77)
              : Colors.orange.withAlpha(77),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 4,
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
                Icons.link,
                color: correlationStrength >= 0.8
                    ? Colors.green
                    : Colors.orange,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correlated Pattern Detected',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      timeWindow,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color:
                      (correlationStrength >= 0.8
                              ? Colors.green
                              : Colors.orange)
                          .withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${(correlationStrength * 100).toStringAsFixed(0)}% Consensus',
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: correlationStrength >= 0.8
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'AI Models in Agreement',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _getUniqueAIServices(
              analyses,
            ).map((service) => _buildAIBadge(service)).toList(),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue, size: 4.w),
              SizedBox(width: 1.w),
              Text(
                '$patternCount related analyses',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Analysis Types: ${_getAnalysisTypes(analyses).join(", ")}',
            style: TextStyle(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getUniqueAIServices(List<Map<String, dynamic>> analyses) {
    final services = <String>{};
    for (var analysis in analyses) {
      final aiResults = analysis['ai_results'] as List<dynamic>? ?? [];
      for (var result in aiResults) {
        if (result is Map<String, dynamic>) {
          final service = result['ai_service'] as String?;
          if (service != null) {
            services.add(service);
          }
        }
      }
    }
    return services.toList();
  }

  List<String> _getAnalysisTypes(List<Map<String, dynamic>> analyses) {
    final types = <String>{};
    for (var analysis in analyses) {
      final type = analysis['analysis_type'] as String?;
      if (type != null) {
        types.add(type);
      }
    }
    return types.toList();
  }

  Widget _buildAIBadge(String service) {
    final colors = {
      'claude': Colors.purple,
      'perplexity': Colors.blue,
      'openai': Colors.green,
    };

    final icons = {
      'claude': Icons.psychology,
      'perplexity': Icons.search,
      'openai': Icons.auto_awesome,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: (colors[service] ?? Colors.grey).withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icons[service] ?? Icons.smart_toy,
            color: colors[service] ?? Colors.grey,
            size: 4.w,
          ),
          SizedBox(width: 1.w),
          Text(
            service.toUpperCase(),
            style: TextStyle(
              fontSize: 8.sp,
              color: colors[service] ?? Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
