import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PerformanceMetricsTabWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const PerformanceMetricsTabWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by parent
      },
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildAIServiceLatency(),
          SizedBox(height: 2.h),
          _buildConsensusExecutionTimes(),
          SizedBox(height: 2.h),
          _buildCacheHitRates(),
          SizedBox(height: 2.h),
          _buildDatabasePerformance(),
        ],
      ),
    );
  }

  Widget _buildAIServiceLatency() {
    final latency = data['ai_service_latency'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Service Latency',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            ...latency.entries.map((entry) {
              final serviceName = entry.key;
              final metrics = entry.value as Map<String, dynamic>;
              return _buildLatencyCard(serviceName, metrics);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLatencyCard(String serviceName, Map<String, dynamic> metrics) {
    final avg = metrics['avg'] as int;
    final p95 = metrics['p95'] as int;
    final p99 = metrics['p99'] as int;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _getServiceColor(serviceName).withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: _getServiceColor(serviceName).withAlpha(77),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: _getServiceColor(serviceName),
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                serviceName.toUpperCase(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getLatencyStatusColor(avg),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  _getLatencyStatus(avg),
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn('Avg', '${avg}ms', AppTheme.primaryLight),
              _buildMetricColumn(
                'P95',
                '${p95}ms',
                p95 > 1000 ? AppTheme.warningLight : AppTheme.accentLight,
              ),
              _buildMetricColumn(
                'P99',
                '${p99}ms',
                p99 > 2000 ? AppTheme.errorLight : AppTheme.secondaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildConsensusExecutionTimes() {
    final consensus =
        data['consensus_execution_times'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consensus Execution Times',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (consensus['p99'] as int? ?? 2500).toDouble() * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String label;
                        switch (groupIndex) {
                          case 0:
                            label = 'Average';
                            break;
                          case 1:
                            label = 'P50';
                            break;
                          case 2:
                            label = 'P95';
                            break;
                          case 3:
                            label = 'P99';
                            break;
                          default:
                            label = '';
                        }
                        return BarTooltipItem(
                          '$label\n${rod.toY.toInt()}ms',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          String text;
                          switch (value.toInt()) {
                            case 0:
                              text = 'Avg';
                              break;
                            case 1:
                              text = 'P50';
                              break;
                            case 2:
                              text = 'P95';
                              break;
                            case 3:
                              text = 'P99';
                              break;
                            default:
                              text = '';
                          }
                          return Padding(
                            padding: EdgeInsets.only(top: 1.h),
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppTheme.textSecondaryLight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}ms',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.borderLight,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: (consensus['avg'] as int? ?? 0).toDouble(),
                          color: AppTheme.primaryLight,
                          width: 12.w,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: (consensus['p50'] as int? ?? 0).toDouble(),
                          color: AppTheme.accentLight,
                          width: 12.w,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: (consensus['p95'] as int? ?? 0).toDouble(),
                          color: AppTheme.warningLight,
                          width: 12.w,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(
                          toY: (consensus['p99'] as int? ?? 0).toDouble(),
                          color: AppTheme.errorLight,
                          width: 12.w,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheHitRates() {
    final cacheRates = data['cache_hit_rates'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache Hit Rates',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            ...cacheRates.entries.map((entry) {
              final cacheName = entry.key;
              final hitRate = entry.value as double;
              return _buildCacheRateBar(cacheName, hitRate);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheRateBar(String cacheName, double hitRate) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatCacheName(cacheName),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                '${(hitRate * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: _getCacheRateColor(hitRate),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: hitRate,
            backgroundColor: AppTheme.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getCacheRateColor(hitRate),
            ),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildDatabasePerformance() {
    final dbPerf = data['database_performance'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Performance',
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
                  child: _buildDBMetricCard(
                    'Query Time',
                    '${dbPerf['avg_query_time_ms'] ?? 0}ms',
                    Icons.speed,
                    AppTheme.primaryLight,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildDBMetricCard(
                    'Connections',
                    '${dbPerf['active_connections'] ?? 0}',
                    Icons.link,
                    AppTheme.accentLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildDBMetricCard(
                    'Cache Size',
                    '${dbPerf['cache_size_mb'] ?? 0}MB',
                    Icons.storage,
                    AppTheme.secondaryLight,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildDBMetricCard(
                    'Uptime',
                    '${((dbPerf['uptime_percentage'] ?? 0) * 100).toStringAsFixed(1)}%',
                    Icons.check_circle,
                    AppTheme.accentLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDBMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
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

  Color _getServiceColor(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'openai':
        return AppTheme.primaryLight;
      case 'anthropic':
        return AppTheme.secondaryLight;
      case 'gemini':
        return AppTheme.accentLight;
      case 'perplexity':
        return AppTheme.warningLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }

  Color _getLatencyStatusColor(int latency) {
    if (latency < 500) return AppTheme.accentLight;
    if (latency < 1000) return AppTheme.warningLight;
    return AppTheme.errorLight;
  }

  String _getLatencyStatus(int latency) {
    if (latency < 500) return 'EXCELLENT';
    if (latency < 1000) return 'GOOD';
    return 'SLOW';
  }

  Color _getCacheRateColor(double rate) {
    if (rate >= 0.8) return AppTheme.accentLight;
    if (rate >= 0.6) return AppTheme.warningLight;
    return AppTheme.errorLight;
  }

  String _formatCacheName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
