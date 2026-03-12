import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class VPSupplyAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> economyStats;

  const VPSupplyAnalyticsWidget({super.key, required this.economyStats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalVP = economyStats['total_vp_circulation'] ?? 0;
    final totalEarned = economyStats['total_vp_earned'] ?? 0;
    final totalSpent = economyStats['total_vp_spent'] ?? 0;

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
                iconName: 'analytics',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'VP Supply & Demand Analytics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildSupplyDemandChart(theme, totalEarned, totalSpent),
          SizedBox(height: 2.h),
          _buildTrendAnalysis(theme, totalVP, totalEarned, totalSpent),
        ],
      ),
    );
  }

  Widget _buildSupplyDemandChart(
    ThemeData theme,
    int totalEarned,
    int totalSpent,
  ) {
    final supplyPercentage = totalEarned > 0
        ? (totalEarned / (totalEarned + totalSpent) * 100)
        : 50.0;
    final demandPercentage = 100 - supplyPercentage;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supply vs Demand',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                flex: supplyPercentage.toInt(),
                child: Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Supply ${supplyPercentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: demandPercentage.toInt(),
                child: Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Demand ${demandPercentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(theme, 'Total Earned', totalEarned, Colors.green),
              _buildStatItem(theme, 'Total Spent', totalSpent, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '$value VP',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis(
    ThemeData theme,
    int totalVP,
    int totalEarned,
    int totalSpent,
  ) {
    final circulationRate = totalEarned > 0
        ? (totalVP / totalEarned * 100)
        : 0.0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Analysis',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Circulation Rate: ${circulationRate.toStringAsFixed(2)}%',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'Economic Health: ${circulationRate > 50 ? "Healthy" : "Needs Attention"}',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'Demand Forecasting: ${totalSpent > totalEarned * 0.7 ? "High demand" : "Moderate demand"}',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
