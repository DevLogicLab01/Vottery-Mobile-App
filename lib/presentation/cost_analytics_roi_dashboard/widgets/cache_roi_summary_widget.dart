import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/infrastructure_cost_tracking_service.dart';

class CacheRoiSummaryWidget extends StatelessWidget {
  final CacheRoiMetrics metrics;

  const CacheRoiSummaryWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.teal.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cached, color: Colors.white, size: 22),
                    SizedBox(width: 2.w),
                    Text(
                      'Redis Cache ROI',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        '${metrics.roiPercentage.toStringAsFixed(0)}% ROI',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                Text(
                  'Save \$${metrics.costSavings.toStringAsFixed(0)}/month for \$${metrics.investmentCost.toStringAsFixed(0)} Redis cost',
                  style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                ),
                SizedBox(height: 1.5.h),
                Row(
                  children: [
                    Expanded(
                      child: _RoiStat(
                        label: 'Queries Eliminated',
                        value: _formatNumber(metrics.queriesEliminated),
                      ),
                    ),
                    Expanded(
                      child: _RoiStat(
                        label: 'Cache Hit Rate',
                        value:
                            '${(metrics.cacheHitRate * 100).toStringAsFixed(0)}%',
                      ),
                    ),
                    Expanded(
                      child: _RoiStat(
                        label: 'Payback Period',
                        value:
                            '${metrics.paybackPeriodMonths.toStringAsFixed(1)} mo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Query Elimination Metrics',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 1.5.h),
                _ComparisonRow(
                  label: 'Before Caching',
                  value:
                      '${_formatNumber(metrics.cacheHits + metrics.cacheMisses)} queries/day',
                  color: Colors.red.shade600,
                  icon: Icons.trending_up,
                ),
                SizedBox(height: 1.h),
                _ComparisonRow(
                  label: 'After Caching',
                  value: '${_formatNumber(metrics.cacheMisses)} queries/day',
                  color: Colors.green.shade600,
                  icon: Icons.trending_down,
                ),
                SizedBox(height: 1.h),
                _ComparisonRow(
                  label: 'Reduction',
                  value:
                      '${((metrics.queriesEliminated / (metrics.cacheHits + metrics.cacheMisses)) * 100).toStringAsFixed(0)}% fewer DB hits',
                  color: Colors.blue.shade600,
                  icon: Icons.savings,
                ),
                SizedBox(height: 1.h),
                _ComparisonRow(
                  label: 'Monthly Savings',
                  value: '\$${metrics.costSavings.toStringAsFixed(0)}/month',
                  color: Colors.teal.shade600,
                  icon: Icons.attach_money,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }
}

class _RoiStat extends StatelessWidget {
  final String label;
  final String value;

  const _RoiStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9.sp, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ComparisonRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
