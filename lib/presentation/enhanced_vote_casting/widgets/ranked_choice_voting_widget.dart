import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Ranked choice voting widget with drag-to-reorder candidate list
class RankedChoiceVotingWidget extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final List<String> rankedChoices;
  final Function(List<String>) onRankingChanged;

  const RankedChoiceVotingWidget({
    super.key,
    required this.options,
    required this.rankedChoices,
    required this.onRankingChanged,
  });

  @override
  State<RankedChoiceVotingWidget> createState() =>
      _RankedChoiceVotingWidgetState();
}

class _RankedChoiceVotingWidgetState extends State<RankedChoiceVotingWidget> {
  late List<String> _rankedChoices;

  @override
  void initState() {
    super.initState();
    _rankedChoices = List.from(widget.rankedChoices);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unrankedOptions = widget.options
        .where((opt) => !_rankedChoices.contains(opt['id']))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Rank your preferences (drag to reorder):',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: 2.h),

        // Ranked options
        if (_rankedChoices.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rankedChoices.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _rankedChoices.removeAt(oldIndex);
                _rankedChoices.insert(newIndex, item);
                widget.onRankingChanged(_rankedChoices);
              });
            },
            itemBuilder: (context, index) {
              final optionId = _rankedChoices[index];
              final option = widget.options.firstWhere(
                (opt) => opt['id'] == optionId,
              );
              return _buildRankedCard(
                context,
                option,
                index + 1,
                key: ValueKey(optionId),
              );
            },
          ),

        // Unranked options
        if (unrankedOptions.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Tap to add to ranking:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          ...unrankedOptions.map(
            (option) => _buildUnrankedCard(context, option),
          ),
        ],
      ],
    );
  }

  Widget _buildRankedCard(
    BuildContext context,
    Map<String, dynamic> option,
    int rank, {
    Key? key,
  }) {
    final theme = Theme.of(context);

    return Container(
      key: key,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        border: Border.all(color: theme.colorScheme.primary, width: 2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          // Rank number
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          SizedBox(width: 3.w),

          // Option content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            ),
          ),

          SizedBox(width: 2.w),

          // Drag handle
          CustomIconWidget(
            iconName: 'drag_handle',
            color: theme.colorScheme.primary,
            size: 24,
          ),

          SizedBox(width: 2.w),

          // Remove button
          GestureDetector(
            onTap: () {
              setState(() {
                _rankedChoices.remove(option['id']);
                widget.onRankingChanged(_rankedChoices);
              });
            },
            child: CustomIconWidget(
              iconName: 'close',
              color: theme.colorScheme.error,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnrankedCard(BuildContext context, Map<String, dynamic> option) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _rankedChoices.add(option['id']);
          widget.onRankingChanged(_rankedChoices);
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'add_circle_outline',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                option['title'],
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
