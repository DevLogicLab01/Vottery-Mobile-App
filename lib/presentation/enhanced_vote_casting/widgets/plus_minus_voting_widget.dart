import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Plus-Minus voting widget with thumbs up/down and intensity sliders
class PlusMinusVotingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final Map<String, int> scores;
  final Function(String, int) onScoreChanged;

  const PlusMinusVotingWidget({
    super.key,
    required this.options,
    required this.scores,
    required this.onScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Rate each option (-3 to +3):',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        ...options.map((option) => _buildOptionCard(context, option)),
      ],
    );
  }

  Widget _buildOptionCard(BuildContext context, Map<String, dynamic> option) {
    final theme = Theme.of(context);
    final score = scores[option['id']] ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: score != 0
              ? (score > 0
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.error)
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: score != 0 ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option title
          Text(
            option['title'],
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          if (option['description'] != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              option['description'],
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          SizedBox(height: 2.h),

          // Score controls
          Row(
            children: [
              // Thumbs down button
              GestureDetector(
                onTap: () {
                  final newScore = (score - 1).clamp(-3, 3);
                  onScoreChanged(option['id'], newScore);
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: score < 0
                        ? theme.colorScheme.error.withValues(alpha: 0.1)
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: score < 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.outline,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: CustomIconWidget(
                    iconName: 'thumb_down',
                    color: score < 0
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),

              SizedBox(width: 3.w),

              // Score slider
              Expanded(
                child: Column(
                  children: [
                    // Score display
                    Text(
                      score > 0 ? '+$score' : '$score',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: score > 0
                            ? theme.colorScheme.tertiary
                            : score < 0
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    // Slider
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: score > 0
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.error,
                        inactiveTrackColor: theme.colorScheme.outline
                            .withValues(alpha: 0.3),
                        thumbColor: score != 0
                            ? (score > 0
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.error)
                            : theme.colorScheme.onSurfaceVariant,
                        overlayColor: score > 0
                            ? theme.colorScheme.tertiary.withValues(alpha: 0.2)
                            : theme.colorScheme.error.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: score.toDouble(),
                        min: -3,
                        max: 3,
                        divisions: 6,
                        onChanged: (value) {
                          onScoreChanged(option['id'], value.round());
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 3.w),

              // Thumbs up button
              GestureDetector(
                onTap: () {
                  final newScore = (score + 1).clamp(-3, 3);
                  onScoreChanged(option['id'], newScore);
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: score > 0
                        ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: score > 0
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.outline,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: CustomIconWidget(
                    iconName: 'thumb_up',
                    color: score > 0
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
