import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Confirm prediction card showing summary, crowd comparison, and VP reward preview
class ConfirmPredictionCardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final Map<String, double> userPredictions;
  final Map<String, double> crowdPredictions;
  final int potentialVpReward;
  final bool isLoading;
  final VoidCallback onConfirm;

  const ConfirmPredictionCardWidget({
    super.key,
    required this.options,
    required this.userPredictions,
    required this.crowdPredictions,
    required this.potentialVpReward,
    required this.isLoading,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Lock In Your Prediction',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Your prediction
                Text(
                  'Your Prediction:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 1.h),
                ...options.map((opt) {
                  final optId = opt['id'] as String;
                  final userPct = userPredictions[optId] ?? 0.0;
                  return _buildPredictionRow(
                    context,
                    opt['title'] as String? ?? 'Option',
                    userPct,
                    theme.colorScheme.primary,
                  );
                }),

                SizedBox(height: 2.h),
                Divider(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                SizedBox(height: 1.h),

                // Crowd prediction comparison
                Text(
                  'Crowd Predicts:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                SizedBox(height: 1.h),
                ...options.map((opt) {
                  final optId = opt['id'] as String;
                  final crowdPct = crowdPredictions[optId] ?? 0.0;
                  return _buildPredictionRow(
                    context,
                    opt['title'] as String? ?? 'Option',
                    crowdPct,
                    theme.colorScheme.secondary,
                  );
                }),

                SizedBox(height: 2.h),

                // VP reward preview
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 24),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Potential Reward',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade700,
                              ),
                            ),
                            Text(
                              '$potentialVpReward VP',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Based on accuracy',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade600,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 2.h),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onConfirm,
                    icon: isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.lock),
                    label: Text(
                      isLoading ? 'Submitting...' : 'Lock In Prediction',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(
    BuildContext context,
    String label,
    double percentage,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: LinearProgressIndicator(
                value: percentage / 100.0,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          SizedBox(
            width: 10.w,
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
