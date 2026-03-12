import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/election_reaction_service.dart';

/// Election reactions panel widget with emoji reactions
class ElectionReactionsWidget extends StatefulWidget {
  final String electionId;

  const ElectionReactionsWidget({super.key, required this.electionId});

  @override
  State<ElectionReactionsWidget> createState() =>
      _ElectionReactionsWidgetState();
}

class _ElectionReactionsWidgetState extends State<ElectionReactionsWidget> {
  final ElectionReactionService _reactionService =
      ElectionReactionService.instance;

  Map<String, int> _reactionCounts = {};
  String? _userReaction;
  bool _isLoading = true;
  RealtimeChannel? _reactionsChannel;
  bool _showReactionPicker = false;

  @override
  void initState() {
    super.initState();
    _loadReactions();
    _subscribeToReactions();
  }

  @override
  void dispose() {
    _reactionsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadReactions() async {
    setState(() => _isLoading = true);

    try {
      final counts = await _reactionService.getReactionCounts(
        widget.electionId,
      );
      final userReaction = await _reactionService.getUserReaction(
        widget.electionId,
      );

      if (mounted) {
        setState(() {
          _reactionCounts = {
            'like': counts?['like_count'] as int? ?? 0,
            'love': counts?['love_count'] as int? ?? 0,
            'wow': counts?['wow_count'] as int? ?? 0,
            'angry': counts?['angry_count'] as int? ?? 0,
            'sad': counts?['sad_count'] as int? ?? 0,
            'celebrate': counts?['celebrate_count'] as int? ?? 0,
          };
          _userReaction = userReaction;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load reactions error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToReactions() {
    _reactionsChannel = _reactionService.subscribeToReactions(
      electionId: widget.electionId,
      onReactionChanged: () {
        _loadReactions();
      },
    );
  }

  Future<void> _handleReaction(String reactionType) async {
    try {
      final success = await _reactionService.reactToElection(
        electionId: widget.electionId,
        reactionType: reactionType,
      );

      if (success) {
        setState(() => _showReactionPicker = false);
        await _loadReactions();
      }
    } catch (e) {
      debugPrint('Handle reaction error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return SizedBox(
        height: 8.h,
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    final totalReactions = _reactionCounts.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reactions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (totalReactions > 0)
                Text(
                  '$totalReactions total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),

          // Reaction buttons
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: ElectionReactionService.availableReactions.map((
              reaction,
            ) {
              final reactionType = reaction['type']!;
              final emoji = reaction['emoji']!;
              final count = _reactionCounts[reactionType] ?? 0;
              final isSelected = _userReaction == reactionType;

              return GestureDetector(
                onTap: () => _handleReaction(reactionType),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: TextStyle(fontSize: 20.sp)),
                      if (count > 0) ...[
                        SizedBox(width: 1.w),
                        Text(
                          '$count',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Show who reacted
          if (_userReaction != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 4.w,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'You reacted with ${ElectionReactionService.availableReactions.firstWhere((r) => r['type'] == _userReaction)['emoji']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
