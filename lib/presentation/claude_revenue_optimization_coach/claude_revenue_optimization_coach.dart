import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../services/creator_coaching_service.dart';

/// Mobile Creator Coaching Hub
///
/// Lightweight, touch-optimized view that surfaces:
/// - Key creator revenue metrics (from Supabase snapshots)
/// - Anthropic Claude coaching summary
/// - 3–5 prioritized recommendations and concrete next steps
///
/// This screen intentionally mirrors the spirit of the Web
/// Creator Earnings Command Center + Claude coaching, but
/// in a simplified mobile format.
class ClaudeRevenueOptimizationCoachScreen extends StatefulWidget {
  const ClaudeRevenueOptimizationCoachScreen({super.key});

  @override
  State<ClaudeRevenueOptimizationCoachScreen> createState() =>
      _ClaudeRevenueOptimizationCoachScreenState();
}

class _ClaudeRevenueOptimizationCoachScreenState
    extends State<ClaudeRevenueOptimizationCoachScreen> {
  final _service = CreatorCoachingService.instance;

  bool _loading = true;
  String? _error;
  CreatorCoachingResult? _result;

  @override
  void initState() {
    super.initState();
    _loadCoaching();
  }

  Future<void> _loadCoaching() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getCoachingSummary();
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'ClaudeRevenueOptimizationCoach',
      onRetry: _loadCoaching,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Creator Coaching',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadCoaching,
          child: _buildBody(theme),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const SkeletonDashboard();
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 32.sp, color: theme.colorScheme.error),
              SizedBox(height: 2.h),
              Text(
                'We could not load your coaching insights right now.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                _error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: _loadCoaching,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_result == null) {
      return EnhancedEmptyStateWidget(
        title: 'No insights yet',
        description:
            'Start running elections and campaigns to unlock personalized coaching.',
        primaryActionLabel: 'Refresh',
        onPrimaryAction: _loadCoaching,
      );
    }

    final result = _result!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(result, theme),
          SizedBox(height: 2.5.h),
          _buildInsightsSection(result, theme),
          SizedBox(height: 2.5.h),
          _buildNextStepsSection(result, theme),
          SizedBox(height: 3.h),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CreatorCoachingResult result, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.4.w),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_graph,
                    color: AppTheme.accentLight,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Claude Revenue Coach',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.6.h),
            Text(
              result.summary.isNotEmpty
                  ? result.summary
                  : 'Claude will help you optimize your earnings, content, and pacing based on your recent performance.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(
      CreatorCoachingResult result, ThemeData theme) {
    final insights = result.priorityInsights;
    if (insights.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Priority insights',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 0.8.h),
          Text(
            'We will surface specific insights here as more data accumulates.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority insights',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.2.h),
        ...insights.map((insight) {
          final title = (insight['title'] as String?) ?? 'Insight';
          final description =
              (insight['description'] as String?) ?? 'No description provided.';
          final impact = (insight['impact'] as String?) ?? 'medium';
          final timeframe = (insight['timeframe'] as String?) ?? 'this month';

          final impactLower = impact.toLowerCase();
          final impactColor = switch (impactLower) {
            'high' => Colors.redAccent,
            'medium' => AppTheme.accentLight,
            _ => AppTheme.primaryLight,
          };
          final impactLabelColor = switch (impactLower) {
            'high' => Colors.red.shade900,
            'medium' => Colors.teal.shade900,
            _ => Colors.blue.shade900,
          };

          return Container(
            margin: EdgeInsets.only(bottom: 1.6.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.15),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(3.2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: impactColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.8.h),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.8.h),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          'Impact: ${impact[0].toUpperCase()}${impact.substring(1)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: impactLabelColor,
                          ),
                        ),
                        backgroundColor: impactColor.withOpacity(0.12),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      SizedBox(width: 2.w),
                      Chip(
                        label: Text(
                          timeframe,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNextStepsSection(
      CreatorCoachingResult result, ThemeData theme) {
    final steps = result.nextSteps;
    if (steps.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next steps',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 0.8.h),
          Text(
            'As Claude gathers more data, actionable next steps will appear here.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next steps',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.0.h),
        ...steps.map((step) {
          return Padding(
            padding: EdgeInsets.only(bottom: 0.8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 14.sp,
                  color: AppTheme.primaryLight,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    step,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
