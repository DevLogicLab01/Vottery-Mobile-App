import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class OutcomePredictionsWidget extends StatelessWidget {
  final Map<String, dynamic>? predictions;
  final VoidCallback onGenerate;
  final bool isGenerating;

  const OutcomePredictionsWidget({
    super.key,
    required this.predictions,
    required this.onGenerate,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: theme.colorScheme.primary),
                SizedBox(width: 2.w),
                Text(
                  'AI Outcome Predictions',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isGenerating)
                  SizedBox(
                    width: 5.w,
                    height: 5.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onGenerate,
                    tooltip: 'Generate Predictions',
                  ),
              ],
            ),
            SizedBox(height: 2.h),

            if (predictions == null)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 10.w,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'No predictions yet',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                    SizedBox(height: 1.h),
                    ElevatedButton.icon(
                      onPressed: isGenerating ? null : onGenerate,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate with AI'),
                    ),
                  ],
                ),
              )
            else ...[
              // Confidence Score
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 6.w),
                    SizedBox(width: 2.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confidence Score',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${(predictions!['confidence_score'] ?? 0.0).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),

              // Prediction Data
              if (predictions!['prediction_data'] != null)
                _buildPredictionData(
                  predictions!['prediction_data'] as Map<String, dynamic>,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionData(Map<String, dynamic> data) {
    final probabilities =
        data['outcome_probabilities'] as Map<String, dynamic>?;

    if (probabilities == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outcome Probabilities',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 1.h),
        ...probabilities.entries.map((entry) {
          final probability = (entry.value as num).toDouble() * 100;

          return Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    Text(
                      '${probability.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: LinearProgressIndicator(
                    value: probability / 100,
                    minHeight: 1.h,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getColorForProbability(probability),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getColorForProbability(double probability) {
    if (probability >= 50) return Colors.green;
    if (probability >= 30) return Colors.orange;
    return Colors.red;
  }
}
