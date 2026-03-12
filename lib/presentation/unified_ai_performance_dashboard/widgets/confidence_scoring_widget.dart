import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ConfidenceScoringWidget extends StatelessWidget {
  final Map<String, dynamic> consensusMetrics;
  final List<Map<String, dynamic>> recentAnalyses;

  const ConfidenceScoringWidget({
    super.key,
    required this.consensusMetrics,
    required this.recentAnalyses,
  });

  @override
  Widget build(BuildContext context) {
    final consensusRate = consensusMetrics['consensus_rate'] ?? 0.0;
    final avgConfidence = consensusMetrics['avg_confidence'] ?? 0.0;
    final automatedResolutions = consensusMetrics['automated_resolutions'] ?? 0;
    final manualReviews = consensusMetrics['manual_reviews'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confidence Scoring Metrics',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Consensus Rate',
                  '${(consensusRate * 100).toStringAsFixed(1)}%',
                  Icons.psychology,
                  Colors.purple,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Avg Confidence',
                  '${(avgConfidence * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
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
                  'Automated',
                  automatedResolutions.toString(),
                  Icons.auto_fix_high,
                  Colors.green,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Manual Reviews',
                  manualReviews.toString(),
                  Icons.person,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Confidence Distribution',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildConfidenceChart(),
          SizedBox(height: 3.h),
          Text(
            'Consensus Analysis',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildConsensusChart(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 4,
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
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
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

  Widget _buildConfidenceChart() {
    final confidenceBuckets = <String, int>{
      '0-20%': 0,
      '20-40%': 0,
      '40-60%': 0,
      '60-80%': 0,
      '80-100%': 0,
    };

    for (var analysis in recentAnalyses) {
      final confidence =
          (analysis['consensus']?['average_confidence'] as num?)?.toDouble() ??
          0.0;
      if (confidence < 0.2) {
        confidenceBuckets['0-20%'] = (confidenceBuckets['0-20%'] ?? 0) + 1;
      } else if (confidence < 0.4) {
        confidenceBuckets['20-40%'] = (confidenceBuckets['20-40%'] ?? 0) + 1;
      } else if (confidence < 0.6) {
        confidenceBuckets['40-60%'] = (confidenceBuckets['40-60%'] ?? 0) + 1;
      } else if (confidence < 0.8) {
        confidenceBuckets['60-80%'] = (confidenceBuckets['60-80%'] ?? 0) + 1;
      } else {
        confidenceBuckets['80-100%'] = (confidenceBuckets['80-100%'] ?? 0) + 1;
      }
    }

    return Container(
      height: 30.h,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              confidenceBuckets.values
                  .reduce((a, b) => a > b ? a : b)
                  .toDouble() *
              1.2,
          barGroups: confidenceBuckets.entries.map((entry) {
            final index = confidenceBuckets.keys.toList().indexOf(entry.key);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: _getConfidenceColor(entry.key),
                  width: 8.w,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 10.w,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final labels = confidenceBuckets.keys.toList();
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Text(
                      labels[value.toInt()],
                      style: TextStyle(
                        fontSize: 8.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.withAlpha(51), strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildConsensusChart() {
    final consensusCount = recentAnalyses
        .where((a) => a['consensus']?['has_consensus'] == true)
        .length;
    final noConsensusCount = recentAnalyses.length - consensusCount;

    return Container(
      height: 25.h,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: consensusCount.toDouble(),
                    title: '$consensusCount',
                    color: Colors.green,
                    radius: 15.w,
                    titleStyle: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: noConsensusCount.toDouble(),
                    title: '$noConsensusCount',
                    color: Colors.orange,
                    radius: 15.w,
                    titleStyle: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 8.w,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem('Consensus', Colors.green, consensusCount),
                SizedBox(height: 1.h),
                _buildLegendItem(
                  'No Consensus',
                  Colors.orange,
                  noConsensusCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                '$count analyses',
                style: TextStyle(
                  fontSize: 8.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(String bucket) {
    switch (bucket) {
      case '0-20%':
        return Colors.red;
      case '20-40%':
        return Colors.orange;
      case '40-60%':
        return Colors.yellow;
      case '60-80%':
        return Colors.lightGreen;
      case '80-100%':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
