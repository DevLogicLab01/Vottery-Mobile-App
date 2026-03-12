import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class LatencyAnalysisWidget extends StatelessWidget {
  final Map<String, dynamic> latencyMetrics;

  const LatencyAnalysisWidget({
    required this.latencyMetrics,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (latencyMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    final p50 = latencyMetrics['p50'] ?? 0;
    final p95 = latencyMetrics['p95'] ?? 0;
    final p99 = latencyMetrics['p99'] ?? 0;
    final distribution = latencyMetrics['distribution'] as Map<String, int>? ?? {};

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latency Analysis',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPercentileCard('P50', p50),
              _buildPercentileCard('P95', p95),
              _buildPercentileCard('P99', p99),
            ],
          ),
          if (distribution.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text(
              'Latency Distribution',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 25.h,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxValue(distribution).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppTheme.textSecondaryDark,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final labels = distribution.keys.toList();
                          if (value.toInt() >= labels.length) {
                            return const SizedBox();
                          }
                          return Text(
                            labels[value.toInt()],
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppTheme.textSecondaryDark,
                            ),
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
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getMaxValue(distribution) / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withAlpha(51),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(distribution),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPercentileCard(String label, int latencyMs) {
    final latencySeconds = latencyMs / 1000;
    final color = _getLatencyColor(latencyMs);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryDark,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '${latencySeconds.toStringAsFixed(1)}s',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, int> distribution) {
    final groups = <BarChartGroupData>[];
    int index = 0;

    for (final entry in distribution.entries) {
      groups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: entry.value.toDouble(),
              color: AppTheme.primaryColor,
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
      index++;
    }

    return groups;
  }

  int _getMaxValue(Map<String, int> distribution) {
    if (distribution.isEmpty) return 100;
    final max = distribution.values.reduce((a, b) => a > b ? a : b);
    return ((max / 10).ceil() * 10).toInt();
  }

  Color _getLatencyColor(int latencyMs) {
    if (latencyMs < 5000) return Colors.green;
    if (latencyMs < 10000) return Colors.yellow;
    if (latencyMs < 30000) return Colors.orange;
    return Colors.red;
  }
}