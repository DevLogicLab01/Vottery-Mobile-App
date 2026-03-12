import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MlClickPredictionWidget extends StatefulWidget {
  const MlClickPredictionWidget({super.key});

  @override
  State<MlClickPredictionWidget> createState() =>
      _MlClickPredictionWidgetState();
}

class _MlClickPredictionWidgetState extends State<MlClickPredictionWidget> {
  final List<Map<String, dynamic>> _predictions = [
    {
      'screen': 'Vote Casting',
      'predicted_tap_x': 180.5,
      'predicted_tap_y': 420.3,
      'confidence_score': 0.87,
      'element': 'Submit Vote Button',
      'probability': 0.92,
    },
    {
      'screen': 'Election Discovery',
      'predicted_tap_x': 95.2,
      'predicted_tap_y': 310.7,
      'confidence_score': 0.79,
      'element': 'Election Card',
      'probability': 0.85,
    },
    {
      'screen': 'Social Feed',
      'predicted_tap_x': 320.1,
      'predicted_tap_y': 580.4,
      'confidence_score': 0.91,
      'element': 'Like Button',
      'probability': 0.94,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'ML Click Prediction Models',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'TensorFlow Lite on-device predictions',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          ..._predictions.map((prediction) {
            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        prediction['screen'],
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getConfidenceColor(
                            prediction['confidence_score'],
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          '${(prediction['confidence_score'] * 100).toStringAsFixed(0)}% confidence',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getConfidenceColor(
                              prediction['confidence_score'],
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Element: ${prediction['element']}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Predicted Tap: (${prediction['predicted_tap_x'].toStringAsFixed(1)}, ${prediction['predicted_tap_y'].toStringAsFixed(1)})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  LinearProgressIndicator(
                    value: prediction['probability'],
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Tap Probability: ${(prediction['probability'] * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
