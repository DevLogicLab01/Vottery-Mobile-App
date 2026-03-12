import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

class PerformanceMetricsWidget extends StatelessWidget {
  final Map<String, dynamic>? metrics;

  const PerformanceMetricsWidget({super.key, this.metrics});

  @override
  Widget build(BuildContext context) {
    if (metrics == null || metrics!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, color: Colors.grey, size: 48.sp),
            SizedBox(height: 2.h),
            Text(
              'No metrics available',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(),
          SizedBox(height: 2.h),
          _buildSuccessRateChart(),
          SizedBox(height: 2.h),
          _buildCategoryBreakdown(),
          SizedBox(height: 2.h),
          _buildImpactSummary(),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final totalRecommendations = metrics!['total_recommendations'] ?? 0;
    final appliedCount = metrics!['applied_count'] ?? 0;
    final successRate = metrics!['success_rate'] ?? 0.0;
    final avgImpact = metrics!['avg_impact'] ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total',
            totalRecommendations.toString(),
            Icons.lightbulb,
            Colors.blue,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildMetricCard(
            'Applied',
            appliedCount.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRateChart() {
    final successRate = (metrics!['success_rate'] ?? 0.0).toDouble();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Success Rate',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 20.h,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: successRate,
                      color: Colors.green,
                      title: '${successRate.toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: (100 - successRate).toDouble(),
                      color: Colors.grey.shade300,
                      title: '',
                      radius: 50,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final categories =
        metrics!['category_breakdown'] as Map<String, dynamic>? ?? {};

    if (categories.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.5.h),
            ...categories.entries.map((entry) {
              final count = entry.value as int;
              final total = metrics!['total_recommendations'] as int;
              final percentage = (count / total * 100).toStringAsFixed(0);

              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatCategoryName(entry.key),
                          style: TextStyle(fontSize: 11.sp),
                        ),
                        Text(
                          '$count ($percentage%)',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    LinearProgressIndicator(
                      value: count / total,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        _getCategoryColor(entry.key),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactSummary() {
    final impactMetrics =
        metrics!['impact_metrics'] as Map<String, dynamic>? ?? {};

    if (impactMetrics.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Impact',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.5.h),
            ...impactMetrics.entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatMetricKey(entry.key),
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    Text(
                      _formatImpactValue(entry.value),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: _getImpactColor(entry.value),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatCategoryName(String category) {
    return category
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatMetricKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatImpactValue(dynamic value) {
    if (value is num) {
      if (value >= 0) {
        return '+${value.toStringAsFixed(1)}%';
      } else {
        return '${value.toStringAsFixed(1)}%';
      }
    }
    return value.toString();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'performance':
        return Colors.blue;
      case 'fraud':
        return Colors.red;
      case 'revenue':
        return Colors.green;
      case 'engagement':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getImpactColor(dynamic value) {
    if (value is num) {
      if (value >= 10) return Colors.green;
      if (value >= 5) return Colors.lightGreen;
      if (value >= 0) return Colors.orange;
      return Colors.red;
    }
    return Colors.grey;
  }
}
