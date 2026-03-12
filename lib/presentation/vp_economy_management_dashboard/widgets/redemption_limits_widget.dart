import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class RedemptionLimitsWidget extends StatefulWidget {
  final VoidCallback onRefresh;

  const RedemptionLimitsWidget({super.key, required this.onRefresh});

  @override
  State<RedemptionLimitsWidget> createState() => _RedemptionLimitsWidgetState();
}

class _RedemptionLimitsWidgetState extends State<RedemptionLimitsWidget> {
  final Map<String, Map<String, int>> _limits = {
    'Bronze': {'daily': 500, 'weekly': 2000},
    'Silver': {'daily': 1000, 'weekly': 5000},
    'Gold': {'daily': 2000, 'weekly': 10000},
    'Platinum': {'daily': 5000, 'weekly': 25000},
    'Elite': {'daily': 10000, 'weekly': 50000},
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'account_balance',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Redemption Limits',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Daily/Weekly VP Redemption Caps Per User Tier',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          ..._limits.entries.map((entry) {
            return _buildTierLimitCard(theme, entry.key, entry.value);
          }),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyLimits,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
              child: Text(
                'Apply Redemption Limits',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierLimitCard(
    ThemeData theme,
    String tier,
    Map<String, int> limits,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$tier Tier',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Limit', style: theme.textTheme.bodyMedium),
              Text(
                '${limits['daily']} VP',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Limit', style: theme.textTheme.bodyMedium),
              Text(
                '${limits['weekly']} VP',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyLimits() {
    // TODO: Implement API call to update redemption limits
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redemption limits applied successfully'),
        backgroundColor: Colors.green,
      ),
    );
    widget.onRefresh();
  }
}
