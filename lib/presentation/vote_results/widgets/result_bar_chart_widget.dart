import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ResultBarChartWidget extends StatefulWidget {
  final Map<String, dynamic> option;
  final bool showDemographics;
  final VoidCallback onLongPress;

  const ResultBarChartWidget({
    super.key,
    required this.option,
    required this.showDemographics,
    required this.onLongPress,
  });

  @override
  State<ResultBarChartWidget> createState() => _ResultBarChartWidgetState();
}

class _ResultBarChartWidgetState extends State<ResultBarChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation =
        Tween<double>(
          begin: 0.0,
          end: (widget.option["percentage"] as double) / 100,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTrending = widget.option["trending"] as bool;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.option["title"] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isTrending) ...[
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: 'trending_up',
                          color: theme.colorScheme.tertiary,
                          size: 14,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Trending',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Text(
                  '${widget.option["votes"]} votes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.option["percentage"]}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Color(widget.option["color"] as int),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(widget.option["color"] as int),
                              Color(
                                widget.option["color"] as int,
                              ).withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Color(
                                widget.option["color"] as int,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (widget.showDemographics) ...[
              SizedBox(height: 2.h),
              _buildDemographicBreakdown(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDemographicBreakdown(ThemeData theme) {
    final demographics = widget.option["demographics"] as Map<String, dynamic>;
    final totalVotes = widget.option["votes"] as int;

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Age Demographics',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDemographicChip(
                theme,
                '18-30',
                demographics["age_18_30"] as int,
                totalVotes,
              ),
              _buildDemographicChip(
                theme,
                '31-45',
                demographics["age_31_45"] as int,
                totalVotes,
              ),
              _buildDemographicChip(
                theme,
                '46-60',
                demographics["age_46_60"] as int,
                totalVotes,
              ),
              _buildDemographicChip(
                theme,
                '60+',
                demographics["age_60_plus"] as int,
                totalVotes,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicChip(
    ThemeData theme,
    String label,
    int votes,
    int totalVotes,
  ) {
    final percentage = (votes / totalVotes * 100).toStringAsFixed(0);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          '$percentage%',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
