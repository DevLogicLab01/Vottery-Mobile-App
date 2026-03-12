import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/carousel_analytics_service.dart';
import '../../services/carousel_performance_monitor.dart';
import '../../theme/app_theme.dart';

/// Carousel Analytics Intelligence Center
/// Comprehensive engagement tracking and performance analysis dashboard
class CarouselAnalyticsIntelligenceCenter extends StatefulWidget {
  const CarouselAnalyticsIntelligenceCenter({super.key});

  @override
  State<CarouselAnalyticsIntelligenceCenter> createState() =>
      _CarouselAnalyticsIntelligenceCenterState();
}

class _CarouselAnalyticsIntelligenceCenterState
    extends State<CarouselAnalyticsIntelligenceCenter>
    with SingleTickerProviderStateMixin {
  final CarouselAnalyticsService _analyticsService =
      CarouselAnalyticsService.instance;
  final CarouselPerformanceMonitor _performanceMonitor =
      CarouselPerformanceMonitor.instance;

  late TabController _tabController;
  Map<String, dynamic> _engagementSummary = {};
  Map<String, int> _swipeDistribution = {};
  List<Map<String, dynamic>> _engagementOverTime = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final summary = await _analyticsService.getEngagementSummary();
      final swipes = await _analyticsService.getSwipeDistribution(
        carouselType: 'horizontal_snap',
      );
      final timeline = await _analyticsService.getEngagementOverTime(
        carouselType: 'horizontal_snap',
        days: 7,
      );

      setState(() {
        _engagementSummary = summary;
        _swipeDistribution = swipes;
        _engagementOverTime = timeline;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carousel Analytics'),
        backgroundColor: AppTheme.backgroundDark,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Performance'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPerformanceTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview metrics
            Text(
              'Today\'s Metrics',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppThemeColors.electricGold,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Swipes',
                    _engagementSummary['total_swipes']?.toString() ?? '0',
                    Icons.swipe,
                    AppThemeColors.electricGold,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildMetricCard(
                    'Avg Duration',
                    '${(_engagementSummary['avg_view_duration'] ?? 0.0).toStringAsFixed(1)}s',
                    Icons.timer,
                    AppThemeColors.neonMint,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Conversions',
                    _engagementSummary['total_conversions']?.toString() ?? '0',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildMetricCard(
                    'Conv. Rate',
                    '${(_engagementSummary['conversion_rate'] ?? 0.0).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    AppThemeColors.deepPurple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Swipe direction chart
            Text(
              'Swipe Direction Distribution',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),
            _buildSwipeDirectionChart(),
            SizedBox(height: 3.h),

            // Engagement timeline
            Text(
              'Engagement Over Time',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),
            _buildEngagementTimelineChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance metrics
          Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.electricGold,
            ),
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Current FPS',
            _performanceMonitor.currentFPS.toStringAsFixed(1),
            Icons.speed,
            _performanceMonitor.currentFPS >= 55
                ? Colors.green
                : _performanceMonitor.currentFPS >= 45
                ? Colors.orange
                : Colors.red,
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Frame Drops',
            _performanceMonitor.frameDrops.toString(),
            Icons.warning,
            _performanceMonitor.frameDrops < 5
                ? Colors.green
                : _performanceMonitor.frameDrops < 15
                ? Colors.orange
                : Colors.red,
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Quality Level',
            _performanceMonitor.currentQuality.name.toUpperCase(),
            Icons.high_quality,
            AppThemeColors.neonMint,
          ),
          SizedBox(height: 3.h),

          // Device info
          Text(
            'Device Information',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Low-End Device',
                  _performanceMonitor.isLowEndDevice ? 'Yes' : 'No',
                ),
                SizedBox(height: 1.h),
                _buildInfoRow(
                  'Thermal Throttling',
                  _performanceMonitor.isThermalThrottling ? 'Active' : 'Normal',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optimization Insights',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.electricGold,
            ),
          ),
          SizedBox(height: 2.h),
          _buildInsightCard(
            'High Engagement',
            'Jolts carousel has 40% higher engagement than average',
            Icons.trending_up,
            Colors.green,
          ),
          SizedBox(height: 2.h),
          _buildInsightCard(
            'Swipe Pattern',
            'Users prefer right swipes (65%) indicating positive content reception',
            Icons.swipe_right,
            AppThemeColors.neonMint,
          ),
          SizedBox(height: 2.h),
          _buildInsightCard(
            'Performance',
            'Average FPS is ${_performanceMonitor.currentFPS.toStringAsFixed(0)} - ${_performanceMonitor.currentFPS >= 55 ? "Excellent" : "Needs optimization"}',
            Icons.speed,
            _performanceMonitor.currentFPS >= 55 ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeDirectionChart() {
    if (_swipeDistribution.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('No swipe data available'),
      );
    }

    final total = _swipeDistribution.values.fold<int>(
      0,
      (sum, val) => sum + val,
    );

    return Container(
      height: 200,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: PieChart(
        PieChartData(
          sections: _swipeDistribution.entries.map((entry) {
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            return PieChartSectionData(
              value: entry.value.toDouble(),
              title: '${entry.key}\n$percentage%',
              color: _getColorForDirection(entry.key),
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEngagementTimelineChart() {
    if (_engagementOverTime.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('No timeline data available'),
      );
    }

    return Container(
      height: 200,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _engagementOverTime.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  (entry.value['total_views'] ?? 0).toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: AppThemeColors.electricGold,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Color _getColorForDirection(String direction) {
    switch (direction.toLowerCase()) {
      case 'left':
        return Colors.red;
      case 'right':
        return Colors.green;
      case 'up':
        return Colors.blue;
      case 'down':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
