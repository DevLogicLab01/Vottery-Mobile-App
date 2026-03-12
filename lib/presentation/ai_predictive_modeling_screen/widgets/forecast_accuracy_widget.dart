import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Forecast Accuracy Widget
/// Displays model accuracy metrics and confidence calibration
class ForecastAccuracyWidget extends StatelessWidget {
  final Map<String, dynamic> forecast;

  const ForecastAccuracyWidget({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracyScore = forecast['accuracy_score'] ?? 0.0;
    final trendAnalysis =
        forecast['trend_analysis'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Analysis',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildTrendRow(
            'Momentum',
            trendAnalysis['momentum']?.toString() ?? 'Unknown',
            Icons.trending_up,
            theme,
          ),
          SizedBox(height: 1.h),
          _buildTrendRow(
            'Velocity',
            trendAnalysis['velocity']?.toString() ?? 'N/A',
            Icons.speed,
            theme,
          ),
          SizedBox(height: 1.h),
          _buildTrendRow(
            'Confidence Interval',
            trendAnalysis['confidence_interval']?.toString() ?? 'N/A',
            Icons.show_chart,
            theme,
          ),
          if (accuracyScore > 0) ...[
            SizedBox(height: 2.h),
            Divider(color: theme.colorScheme.outline.withAlpha(51)),
            SizedBox(height: 2.h),
            _buildAccuracyIndicator(accuracyScore, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 5.w, color: theme.colorScheme.primary),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyIndicator(double accuracy, ThemeData theme) {
    final color = accuracy >= 80
        ? Colors.green
        : accuracy >= 60
        ? Colors.orange
        : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Model Accuracy',
          style: TextStyle(
            fontSize: 13.sp,
            color: theme.colorScheme.onSurface.withAlpha(179),
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 1.5.h,
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: accuracy / 100,
                    child: Container(
                      height: 1.5.h,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              '${accuracy.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
