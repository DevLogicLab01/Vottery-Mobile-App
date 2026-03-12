import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class HistoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> vote;
  final VoidCallback onViewResults;
  final VoidCallback onShare;
  final VoidCallback onRemove;
  final VoidCallback? onVoteAgain;
  final String searchQuery;

  const HistoryCardWidget({
    super.key,
    required this.vote,
    required this.onViewResults,
    required this.onShare,
    required this.onRemove,
    this.onVoteAgain,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey(vote['id']),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onViewResults(),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.bar_chart,
            label: 'Results',
          ),
          SlidableAction(
            onPressed: (_) => onShare(),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            icon: Icons.share,
            label: 'Share',
          ),
          SlidableAction(
            onPressed: (_) => onRemove(),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete,
            label: 'Remove',
          ),
        ],
      ),
      child: InkWell(
        onTap: onViewResults,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildHighlightedText(
                      vote['title'] as String,
                      theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      theme,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  _buildOutcomeChip(theme),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'calendar_today',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _formatDate(vote['date'] as DateTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  CustomIconWidget(
                    iconName: 'how_to_vote',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _formatVoteType(vote['voteType'] as String),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            'Your Selection',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      vote['userSelection'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Votes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          _formatNumber(vote['totalVotes'] as int),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Choice',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${(vote['userVotePercentage'] as double).toStringAsFixed(1)}%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getOutcomeColor(theme),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (vote['isRecurring'] == true) ...[
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'repeat',
                        color: theme.colorScheme.secondary,
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Recurring Vote',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, TextStyle style, ThemeData theme) {
    if (searchQuery.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = searchQuery.toLowerCase();
    final matches = <TextSpan>[];
    int lastMatchEnd = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, lastMatchEnd);
      if (index == -1) {
        if (lastMatchEnd < text.length) {
          matches.add(TextSpan(text: text.substring(lastMatchEnd)));
        }
        break;
      }

      if (index > lastMatchEnd) {
        matches.add(TextSpan(text: text.substring(lastMatchEnd, index)));
      }

      matches.add(
        TextSpan(
          text: text.substring(index, index + searchQuery.length),
          style: style.copyWith(
            backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.3),
            fontWeight: FontWeight.w700,
          ),
        ),
      );

      lastMatchEnd = index + searchQuery.length;
    }

    return RichText(
      text: TextSpan(style: style, children: matches),
    );
  }

  Widget _buildOutcomeChip(ThemeData theme) {
    final outcome = vote['outcome'] as String;
    final color = _getOutcomeColor(theme);
    final icon = outcome == 'won'
        ? 'emoji_events'
        : outcome == 'lost'
        ? 'cancel'
        : 'remove';
    final label = outcome == 'won'
        ? 'Won'
        : outcome == 'lost'
        ? 'Lost'
        : 'Tied';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 14),
          SizedBox(width: 1.w),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getOutcomeColor(ThemeData theme) {
    final outcome = vote['outcome'] as String;
    return outcome == 'won'
        ? const Color(0xFF10B981)
        : outcome == 'lost'
        ? theme.colorScheme.error
        : const Color(0xFFF59E0B);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  String _formatVoteType(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  void _showContextMenu(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 1.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'bar_chart',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('View Results', style: theme.textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  onViewResults();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'share',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('Share', style: theme.textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  onShare();
                },
              ),
              if (onVoteAgain != null)
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'repeat',
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                  title: Text('Vote Again', style: theme.textTheme.bodyLarge),
                  onTap: () {
                    Navigator.pop(context);
                    onVoteAgain!();
                  },
                ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'delete',
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                title: Text(
                  'Remove from History',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onRemove();
                },
              ),
              SizedBox(height: 1.h),
            ],
          ),
        );
      },
    );
  }
}
