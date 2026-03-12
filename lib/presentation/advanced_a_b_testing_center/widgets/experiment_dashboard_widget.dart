import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/ab_testing_service.dart';

class ExperimentDashboardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> experiments;
  final VoidCallback onRefresh;

  const ExperimentDashboardWidget({
    super.key,
    required this.experiments,
    required this.onRefresh,
  });

  Future<void> _promoteWinner(BuildContext context, String experimentId) async {
    final significance = await ABTestingService.instance
        .calculateStatisticalSignificance(experimentId);

    if (significance == null || !context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to determine winner'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final winnerId = significance['winner_id'] as String;
    final result = await ABTestingService.instance.promoteWinner(
      experimentId,
      winnerId,
    );

    if (context.mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Winner promoted: $winnerId with ${(significance['conversion_rates'][winnerId] * 100).toStringAsFixed(1)}% conversion rate',
            ),
            backgroundColor: Colors.green,
          ),
        );
        onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to promote winner'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (experiments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science, size: 80, color: theme.colorScheme.outline),
            SizedBox(height: 2.h),
            Text(
              'No Active Experiments',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Create your first A/B test to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: experiments.length,
      itemBuilder: (context, index) {
        final experiment = experiments[index];
        final name = experiment['name'] as String;
        final experimentType = experiment['experiment_type'] as String;
        final variants = List<Map<String, dynamic>>.from(
          experiment['variants'] ?? [],
        );
        final status = experiment['status'] as String;
        final startDate = DateTime.parse(experiment['start_date'] as String);
        final endDate = DateTime.parse(experiment['end_date'] as String);

        final daysRemaining = endDate.difference(DateTime.now()).inDays;

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                experimentType,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              '${variants.length} variants',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Time remaining
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    daysRemaining > 0
                        ? '$daysRemaining days remaining'
                        : 'Ended',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Variants preview
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: variants.map((variant) {
                  final variantName = variant['name'] as String;
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(variantName, style: theme.textTheme.bodySmall),
                  );
                }).toList(),
              ),

              SizedBox(height: 2.h),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showExperimentDetails(
                        context,
                        experiment['id'] as String,
                      ),
                      icon: const Icon(Icons.analytics, size: 18),
                      label: const Text('View Results'),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _promoteWinner(context, experiment['id'] as String),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Promote Winner'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showExperimentDetails(
    BuildContext context,
    String experimentId,
  ) async {
    final theme = Theme.of(context);
    final details = await ABTestingService.instance.getExperimentDetails(
      experimentId,
    );

    if (details == null || !context.mounted) return;

    final significance = await ABTestingService.instance
        .calculateStatisticalSignificance(experimentId);

    if (!context.mounted || significance == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        padding: EdgeInsets.all(6.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),

            SizedBox(height: 3.h),

            // Title
            Text(
              details['name'] as String,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 2.h),

            // Statistical significance
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: (significance['is_significant'] as bool)
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        (significance['is_significant'] as bool)
                            ? Icons.check_circle
                            : Icons.info,
                        color: (significance['is_significant'] as bool)
                            ? Colors.green
                            : Colors.orange,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        (significance['is_significant'] as bool)
                            ? 'Statistically Significant'
                            : 'Not Yet Significant',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Confidence: ${(significance['confidence_level'] as int).toString()}%',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    'p-value: ${(significance['p_value'] as double).toStringAsFixed(4)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),

            // Variant metrics
            Text(
              'Variant Performance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 1.h),

            Expanded(
              child: ListView.builder(
                itemCount: (details['variant_metrics'] as List).length,
                itemBuilder: (context, index) {
                  final metric = (details['variant_metrics'] as List)[index];
                  final variantName = metric['variant_name'] as String;
                  final impressions = metric['impressions'] as int;
                  final conversions = metric['conversions'] as int;
                  final conversionRate = metric['conversion_rate'] as double;

                  return Container(
                    margin: EdgeInsets.only(bottom: 1.h),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variantName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Impressions: $impressions',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Conversions: $conversions',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Conversion Rate: ${(conversionRate * 100).toStringAsFixed(2)}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
