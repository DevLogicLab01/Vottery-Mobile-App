import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ClaudeRecommendationCardWidget extends StatelessWidget {
  final Map<String, dynamic> recommendation;
  final VoidCallback onApprove;

  const ClaudeRecommendationCardWidget({
    super.key,
    required this.recommendation,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
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
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: _getCategoryColor(
                    recommendation['type'],
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  _getCategoryIcon(recommendation['type']),
                  color: _getCategoryColor(recommendation['type']),
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation['title'],
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _getCategoryLabel(recommendation['type']),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '${(recommendation['confidence_score'] * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            recommendation['description'],
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: theme.colorScheme.primary,
                  size: 4.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Estimated Impact: ${recommendation['estimated_impact']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 20),
                  SizedBox(width: 2.w),
                  const Text(
                    'Apply Recommendation',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String type) {
    switch (type) {
      case 'performance_optimization':
        return Colors.blue;
      case 'fraud_prevention':
        return Colors.red;
      case 'revenue_enhancement':
        return Colors.green;
      case 'engagement_improvement':
        return Colors.orange;
      case 'content_optimization':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String type) {
    switch (type) {
      case 'performance_optimization':
        return Icons.speed;
      case 'fraud_prevention':
        return Icons.security;
      case 'revenue_enhancement':
        return Icons.attach_money;
      case 'engagement_improvement':
        return Icons.trending_up;
      case 'content_optimization':
        return Icons.auto_awesome;
      default:
        return Icons.lightbulb;
    }
  }

  String _getCategoryLabel(String type) {
    switch (type) {
      case 'performance_optimization':
        return 'Performance Optimization';
      case 'fraud_prevention':
        return 'Fraud Prevention';
      case 'revenue_enhancement':
        return 'Revenue Enhancement';
      case 'engagement_improvement':
        return 'Engagement Improvement';
      case 'content_optimization':
        return 'Content Optimization';
      default:
        return 'General';
    }
  }
}
