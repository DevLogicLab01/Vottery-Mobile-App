import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ComplianceHealthHeaderWidget extends StatelessWidget {
  final List<Map<String, dynamic>> activeJurisdictions;
  final int pendingFilings;
  final double healthScore;

  const ComplianceHealthHeaderWidget({
    super.key,
    required this.activeJurisdictions,
    required this.pendingFilings,
    required this.healthScore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final healthColor = _getHealthColor(healthScore);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Active Jurisdictions',
                  activeJurisdictions.length.toString(),
                  'public',
                  theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Pending Filings',
                  pendingFilings.toString(),
                  'description',
                  Colors.orange,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Health Score',
                  '${healthScore.toStringAsFixed(0)}%',
                  'health_and_safety',
                  healthColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildJurisdictionChips(context),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    String iconName,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          CustomIconWidget(iconName: iconName, color: color, size: 24),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildJurisdictionChips(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: activeJurisdictions.map((jurisdiction) {
        return Chip(
          avatar: CustomIconWidget(
            iconName: jurisdiction['icon'] ?? 'flag',
            color: theme.colorScheme.primary,
            size: 16,
          ),
          label: Text(
            jurisdiction['code'] ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: theme.colorScheme.primary.withAlpha(26),
        );
      }).toList(),
    );
  }

  Color _getHealthColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}
