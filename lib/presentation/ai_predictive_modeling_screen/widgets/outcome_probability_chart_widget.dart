import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Outcome Probability Chart Widget
/// Displays predicted outcome probabilities per candidate
class OutcomeProbabilityChartWidget extends StatelessWidget {
  final Map<String, dynamic> forecast;

  const OutcomeProbabilityChartWidget({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voteDistribution =
        forecast['predicted_vote_distribution'] as Map<String, dynamic>? ?? {};

    if (voteDistribution.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            'No vote distribution data available',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey),
          ),
        ),
      );
    }

    final entries = voteDistribution.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

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
            'Predicted Outcome Probabilities',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          ...entries.map(
            (entry) => _buildProbabilityBar(
              entry.key,
              (entry.value as num).toDouble(),
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityBar(
    String optionId,
    double probability,
    ThemeData theme,
  ) {
    final color = _getColorForProbability(probability);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Option ${optionId.substring(0, 8)}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${probability.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Stack(
            children: [
              Container(
                height: 1.5.h,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              FractionallySizedBox(
                widthFactor: probability / 100,
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
        ],
      ),
    );
  }

  Color _getColorForProbability(double probability) {
    if (probability >= 50) return Colors.green;
    if (probability >= 40) return Colors.blue;
    if (probability >= 30) return Colors.orange;
    return Colors.red;
  }
}
