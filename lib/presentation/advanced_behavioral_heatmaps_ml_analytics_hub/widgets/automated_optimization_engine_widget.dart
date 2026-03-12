import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AutomatedOptimizationEngineWidget extends StatelessWidget {
  const AutomatedOptimizationEngineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final recommendations = [
      {
        'title': 'Button Repositioning',
        'description':
            'Move Submit button 50px higher for 23% better accessibility',
        'impact': 'High',
        'confidence': 0.89,
        'screen': 'Vote Casting',
      },
      {
        'title': 'Content Reordering',
        'description':
            'Place Featured Elections at top for 31% more engagement',
        'impact': 'High',
        'confidence': 0.92,
        'screen': 'Election Discovery',
      },
      {
        'title': 'Color Contrast Improvement',
        'description':
            'Increase CTA button contrast by 15% for better visibility',
        'impact': 'Medium',
        'confidence': 0.76,
        'screen': 'Social Feed',
      },
      {
        'title': 'Font Size Adjustment',
        'description':
            'Increase body text from 14sp to 16sp for 18% better readability',
        'impact': 'Medium',
        'confidence': 0.81,
        'screen': 'All Screens',
      },
    ];

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
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Automated Optimization Engine',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'AI-generated UI/UX recommendations',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          ...recommendations.map((rec) {
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
                      Expanded(
                        child: Text(
                          rec['title'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getImpactColor(
                            rec['impact'] as String,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          rec['impact'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getImpactColor(rec['impact'] as String),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    rec['description'] as String,
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Screen: ${rec['screen']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Confidence: ${((rec['confidence'] as double) * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getImpactColor(String impact) {
    switch (impact) {
      case 'High':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
