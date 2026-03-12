import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DisputeAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const DisputeAnalyticsWidget({required this.analytics, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Dispute Analytics'),
        backgroundColor: AppTheme.primaryLight,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsCards(),
            SizedBox(height: 3.h),
            _buildDisputeTrendsChart(),
            SizedBox(height: 3.h),
            _buildResolutionDistribution(),
            SizedBox(height: 3.h),
            _buildDisputeReasonsChart(),
            SizedBox(height: 3.h),
            _buildPerformanceMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCards() {
    final totalDisputes = analytics['total_disputes'] ?? 0;
    final resolutionTime = analytics['avg_resolution_hours'] ?? 0.0;
    final buyerWinRate = analytics['buyer_win_rate'] ?? 0.0;
    final sellerWinRate = analytics['seller_win_rate'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Disputes',
                totalDisputes.toString(),
                Icons.gavel,
                Colors.orange,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Avg Resolution',
                '${resolutionTime.toStringAsFixed(1)}h',
                Icons.timer,
                Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Buyer Win Rate',
                '${(buyerWinRate * 100).toStringAsFixed(0)}%',
                Icons.person,
                Colors.green,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Seller Win Rate',
                '${(sellerWinRate * 100).toStringAsFixed(0)}%',
                Icons.store,
                Colors.purple,
              ),
            ),
          ],
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
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeTrendsChart() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dispute Trends (Last 30 Days)',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'Day ${value.toInt()}',
                          style: TextStyle(fontSize: 9.sp),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateTrendData(),
                    isCurved: true,
                    color: AppTheme.primaryLight,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateTrendData() {
    final trendData = analytics['dispute_trends'] as List?;
    if (trendData == null || trendData.isEmpty) {
      return List.generate(
        30,
        (index) => FlSpot(index.toDouble(), (index % 5).toDouble()),
      );
    }
    return trendData
        .asMap()
        .entries
        .map(
          (e) => FlSpot(e.key.toDouble(), (e.value['count'] ?? 0).toDouble()),
        )
        .toList();
  }

  Widget _buildResolutionDistribution() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resolution Distribution',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: PieChart(
              PieChartData(
                sections: _generateResolutionSections(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateResolutionSections() {
    final distribution =
        analytics['resolution_distribution'] as Map<String, dynamic>? ?? {};
    final fullRefund = (distribution['full_refund'] ?? 0).toDouble();
    final partialRefund = (distribution['partial_refund'] ?? 0).toDouble();
    final releaseToSeller = (distribution['release_to_seller'] ?? 0).toDouble();
    final mediation = (distribution['mediation'] ?? 0).toDouble();

    return [
      PieChartSectionData(
        value: fullRefund,
        title: 'Full Refund',
        color: Colors.red,
        radius: 50,
      ),
      PieChartSectionData(
        value: partialRefund,
        title: 'Partial',
        color: Colors.orange,
        radius: 50,
      ),
      PieChartSectionData(
        value: releaseToSeller,
        title: 'Seller',
        color: Colors.green,
        radius: 50,
      ),
      PieChartSectionData(
        value: mediation,
        title: 'Mediation',
        color: Colors.blue,
        radius: 50,
      ),
    ];
  }

  Widget _buildDisputeReasonsChart() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Dispute Reasons',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: _generateReasonBars(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final reasons = ['Late', 'Quality', 'Desc', 'Other'];
                        if (value.toInt() < reasons.length) {
                          return Text(
                            reasons[value.toInt()],
                            style: TextStyle(fontSize: 9.sp),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _generateReasonBars() {
    final reasons = analytics['dispute_reasons'] as Map<String, dynamic>? ?? {};
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: (reasons['late_delivery'] ?? 0).toDouble(),
            color: Colors.red,
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: (reasons['poor_quality'] ?? 0).toDouble(),
            color: Colors.orange,
          ),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(
            toY: (reasons['not_as_described'] ?? 0).toDouble(),
            color: Colors.blue,
          ),
        ],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [
          BarChartRodData(
            toY: (reasons['other'] ?? 0).toDouble(),
            color: Colors.grey,
          ),
        ],
      ),
    ];
  }

  Widget _buildPerformanceMetrics() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildMetricRow(
            'Service-Level Dispute Rate',
            '${((analytics['service_dispute_rate'] ?? 0.0) * 100).toStringAsFixed(1)}%',
          ),
          _buildMetricRow(
            'Creator Dispute History',
            '${analytics['high_dispute_creators'] ?? 0} creators',
          ),
          _buildMetricRow(
            'AI Agreement Rate',
            '${((analytics['ai_agreement_rate'] ?? 0.0) * 100).toStringAsFixed(0)}%',
          ),
          _buildMetricRow(
            'Auto-Resolution Rate',
            '${((analytics['auto_resolution_rate'] ?? 0.0) * 100).toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
