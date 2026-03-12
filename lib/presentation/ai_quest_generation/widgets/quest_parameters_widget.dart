import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class QuestParametersWidget extends StatelessWidget {
  final String selectedQuestType;
  final String selectedDifficulty;
  final int vpReward;
  final int questCount;
  final Function(String) onQuestTypeChanged;
  final Function(String) onDifficultyChanged;
  final Function(double) onVPRewardChanged;
  final Function(double) onQuestCountChanged;

  const QuestParametersWidget({
    super.key,
    required this.selectedQuestType,
    required this.selectedDifficulty,
    required this.vpReward,
    required this.questCount,
    required this.onQuestTypeChanged,
    required this.onDifficultyChanged,
    required this.onVPRewardChanged,
    required this.onQuestCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quest Parameters',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Quest Type',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Daily')),
                ButtonSegment(value: 'weekly', label: Text('Weekly')),
              ],
              selected: {selectedQuestType},
              onSelectionChanged: (Set<String> newSelection) {
                onQuestTypeChanged(newSelection.first);
              },
            ),
            SizedBox(height: 2.h),
            Text(
              'Difficulty Level',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'easy', label: Text('Easy')),
                ButtonSegment(value: 'medium', label: Text('Medium')),
                ButtonSegment(value: 'hard', label: Text('Hard')),
              ],
              selected: {selectedDifficulty},
              onSelectionChanged: (Set<String> newSelection) {
                onDifficultyChanged(newSelection.first);
              },
            ),
            SizedBox(height: 2.h),
            Text(
              'VP Reward: $vpReward',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Slider(
              value: vpReward.toDouble(),
              min: 50,
              max: 500,
              divisions: 45,
              label: vpReward.toString(),
              onChanged: onVPRewardChanged,
            ),
            SizedBox(height: 1.h),
            Text(
              'Number of Quests: $questCount',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Slider(
              value: questCount.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: questCount.toString(),
              onChanged: onQuestCountChanged,
            ),
          ],
        ),
      ),
    );
  }
}
