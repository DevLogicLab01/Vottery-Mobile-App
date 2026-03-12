import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/carousel_analytics_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

/// Carousel Analytics Dashboard Screen
/// Displays comprehensive engagement tracking and analytics
class CarouselAnalyticsDashboardScreen extends StatefulWidget {
  const CarouselAnalyticsDashboardScreen({super.key});

  @override
  State<CarouselAnalyticsDashboardScreen> createState() =>
      _CarouselAnalyticsDashboardScreenState();
}

class _CarouselAnalyticsDashboardScreenState
    extends State<CarouselAnalyticsDashboardScreen> {
  final CarouselAnalyticsService _analyticsService =
      CarouselAnalyticsService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _engagementData = [];
  Map<String, int> _swipeDistribution = {};
  List<Map<String, dynamic>> _topContent = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final summary = await _analyticsService.getEngagementSummary();
      final engagement = await _analyticsService.getEngagementOverTime(
        carouselType: 'horizontal_snap',
        days: 7,
      );
      final swipes = await _analyticsService.getSwipeDistribution(
        carouselType: 'horizontal_snap',
      );
      final topContent = await _analyticsService.getTopPerformingContent(
        contentType: 'jolts',
        limit: 10,
      );

      setState(() {
        _summary = summary;
        _engagementData = engagement;
        _swipeDistribution = swipes;
        _topContent = topContent;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Carousel Analytics',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewMetrics(),
                    SizedBox(height: 3.h),
                    _buildEngagementChart(),
                    SizedBox(height: 3.h),
                    _buildSwipeDistributionChart(),
                    SizedBox(height: 3.h),
                    _buildTopContentList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppThemeColors.electricGold,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Swipes',
                value: _summary['total_swipes_today']?.toString() ?? '0',
                icon: Icons.swipe,
                color: AppThemeColors.neonMint,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Views',
                value: _summary['total_views_today']?.toString() ?? '0',
                icon: Icons.visibility,
                color: AppThemeColors.electricGold,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Conversions',
                value: _summary['total_conversions_today']?.toString() ?? '0',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildMetricCard(
                title: 'Avg Duration',
                value:
                    '${(_summary['avg_view_duration'] ?? 0.0).toStringAsFixed(1)}s',
                icon: Icons.timer,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementChart() {
    if (_engagementData.isEmpty) {
      return const SizedBox.shrink();
    }

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
            'Engagement Over Time (7 Days)',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _engagementData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['views'] as int).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppThemeColors.electricGold,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: _engagementData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['swipes'] as int).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppThemeColors.neonMint,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Views', AppThemeColors.electricGold),
              SizedBox(width: 4.w),
              _buildLegendItem('Swipes', AppThemeColors.neonMint),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 2.w),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryDark),
        ),
      ],
    );
  }

  Widget _buildSwipeDistributionChart() {
    if (_swipeDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = _swipeDistribution.values.reduce((a, b) => a + b);

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
            'Swipe Direction Distribution',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          SizedBox(height: 2.h),
          ..._swipeDistribution.entries.map((entry) {
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            return Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppThemeColors.electricGold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  LinearProgressIndicator(
                    value: entry.value / total,
                    backgroundColor: AppTheme.backgroundDark,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppThemeColors.neonMint,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopContentList() {
    if (_topContent.isEmpty) {
      return const SizedBox.shrink();
    }

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
            'Top Performing Content',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          SizedBox(height: 2.h),
          ..._topContent.take(5).map((content) {
            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Content ID: ${content['content_id'].toString().substring(0, 8)}...',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textPrimaryDark,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${content['views']} views • ${content['conversions']} conversions',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppTheme.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppThemeColors.electricGold.withAlpha(51),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '${content['engagement_rate'].toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppThemeColors.electricGold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
