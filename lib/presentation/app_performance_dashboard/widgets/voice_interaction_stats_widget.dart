import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class VoiceInteractionStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const VoiceInteractionStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recognitionAccuracy =
        (stats['recognition_accuracy'] ?? 0.0) as double;
    final avgResponseTime = (stats['avg_response_time_ms'] ?? 0) as int;
    final totalInteractions = (stats['total_interactions'] ?? 0) as int;
    final successRate = (stats['success_rate'] ?? 0.0) as double;
    final errorCount = (stats['error_count'] ?? 0) as int;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Voice Interaction Performance',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Icon(Icons.mic, color: theme.colorScheme.primary, size: 6.w),
            ],
          ),
          SizedBox(height: 2.h),
          _buildMetricRow(
            'Recognition Accuracy',
            '${recognitionAccuracy.toStringAsFixed(1)}%',
            recognitionAccuracy > 90
                ? AppTheme.accentLight
                : AppTheme.warningLight,
            theme,
          ),
          SizedBox(height: 1.h),
          _buildMetricRow(
            'Avg Response Time',
            '${avgResponseTime}ms',
            avgResponseTime < 1000
                ? AppTheme.accentLight
                : AppTheme.warningLight,
            theme,
          ),
          SizedBox(height: 1.h),
          _buildMetricRow(
            'Total Interactions',
            totalInteractions.toString(),
            theme.colorScheme.primary,
            theme,
          ),
          SizedBox(height: 1.h),
          _buildMetricRow(
            'Success Rate',
            '${successRate.toStringAsFixed(1)}%',
            successRate > 90 ? AppTheme.accentLight : AppTheme.warningLight,
            theme,
          ),
          SizedBox(height: 1.h),
          _buildMetricRow(
            'Error Count',
            errorCount.toString(),
            errorCount < 20 ? AppTheme.accentLight : AppTheme.errorLight,
            theme,
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Accuracy',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    LinearProgressIndicator(
                      value: recognitionAccuracy / 100,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        recognitionAccuracy > 90
                            ? AppTheme.accentLight
                            : AppTheme.warningLight,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Success',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    LinearProgressIndicator(
                      value: successRate / 100,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        successRate > 90
                            ? AppTheme.accentLight
                            : AppTheme.warningLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    Color valueColor,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
