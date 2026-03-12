import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/unified_analytics_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Unified Analytics Dashboard
/// Comprehensive insights platform with marketplace, groups, and moderation analytics
class UnifiedAnalyticsDashboard extends StatefulWidget {
  const UnifiedAnalyticsDashboard({super.key});

  @override
  State<UnifiedAnalyticsDashboard> createState() =>
      _UnifiedAnalyticsDashboardState();
}

class _UnifiedAnalyticsDashboardState extends State<UnifiedAnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  final UnifiedAnalyticsService _analyticsService =
      UnifiedAnalyticsService.instance;

  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic> _marketplaceAnalytics = {};
  Map<String, dynamic> _groupsAnalytics = {};
  Map<String, dynamic> _moderationAnalytics = {};
  Map<String, dynamic> _unifiedInsights = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final results = await Future.wait([
        _analyticsService.getMarketplaceAnalytics(),
        _analyticsService.getGroupsAnalytics(),
        _analyticsService.getModerationAnalytics(),
        _analyticsService.getUnifiedInsights(),
      ]);

      if (mounted) {
        setState(() {
          _marketplaceAnalytics = results[0];
          _groupsAnalytics = results[1];
          _moderationAnalytics = results[2];
          _unifiedInsights = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load analytics data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'UnifiedAnalyticsDashboard',
      onRetry: _loadAnalyticsData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Analytics Dashboard',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadAnalyticsData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMarketplaceTab(),
                        _buildGroupsTab(),
                        _buildModerationTab(),
                        _buildUnifiedInsightsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Marketplace'),
          Tab(text: 'Groups'),
          Tab(text: 'Moderation'),
          Tab(text: 'Unified Insights'),
        ],
      ),
    );
  }

  Widget _buildMarketplaceTab() {
    final topServices = _marketplaceAnalytics['top_services'] as List? ?? [];
    final categoryBreakdown =
        _marketplaceAnalytics['category_breakdown'] as Map<String, dynamic>? ??
        {};
    final conversionFunnel =
        _marketplaceAnalytics['conversion_funnel'] as Map<String, dynamic>? ??
        {};

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildSectionHeader('Service Performance'),
        SizedBox(height: 2.h),
        _buildConversionFunnelCard(conversionFunnel),
        SizedBox(height: 3.h),
        _buildSectionHeader('Category Distribution'),
        SizedBox(height: 2.h),
        _buildCategoryPieChart(categoryBreakdown),
        SizedBox(height: 3.h),
        _buildSectionHeader('Top Performing Services'),
        SizedBox(height: 2.h),
        ...topServices.take(5).map((service) => _buildServiceCard(service)),
      ],
    );
  }

  Widget _buildGroupsTab() {
    final memberGrowth = _groupsAnalytics['member_growth'] as List? ?? [];
    final activeGroups = _groupsAnalytics['active_groups'] as List? ?? [];
    final avgPostsPerDay = _groupsAnalytics['avg_posts_per_day'] ?? 0.0;
    final avgCommentsPerPost = _groupsAnalytics['avg_comments_per_post'] ?? 0.0;

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildSectionHeader('Engagement Metrics'),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Avg Posts/Day',
                avgPostsPerDay.toStringAsFixed(1),
                Icons.post_add,
                Colors.blue,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Avg Comments/Post',
                avgCommentsPerPost.toStringAsFixed(1),
                Icons.comment,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        _buildSectionHeader('Member Growth'),
        SizedBox(height: 2.h),
        _buildMemberGrowthChart(memberGrowth),
        SizedBox(height: 3.h),
        _buildSectionHeader('Active Groups'),
        SizedBox(height: 2.h),
        ...activeGroups.take(5).map((group) => _buildGroupCard(group)),
      ],
    );
  }

  Widget _buildModerationTab() {
    final violationsByCategory =
        _moderationAnalytics['violations_by_category']
            as Map<String, dynamic>? ??
        {};
    final totalViolations = _moderationAnalytics['total_violations'] ?? 0;
    final autoRemovalRate = _moderationAnalytics['auto_removal_rate'] ?? 0.0;
    final falsePositiveRate =
        _moderationAnalytics['false_positive_rate'] ?? 0.0;

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildSectionHeader('Moderation Effectiveness'),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Violations',
                totalViolations.toString(),
                Icons.warning,
                Colors.red,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Auto-Removal',
                '${autoRemovalRate.toStringAsFixed(1)}%',
                Icons.auto_fix_high,
                Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _buildMetricCard(
          'False Positive Rate',
          '${falsePositiveRate.toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.green,
        ),
        SizedBox(height: 3.h),
        _buildSectionHeader('Violations by Category'),
        SizedBox(height: 2.h),
        _buildViolationsBarChart(violationsByCategory),
      ],
    );
  }

  Widget _buildUnifiedInsightsTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildSectionHeader('Cross-Platform Analytics'),
        SizedBox(height: 2.h),
        _buildInsightCard(
          'User Journey Tracking',
          'Marketplace users who join groups',
          Icons.timeline,
          Colors.purple,
        ),
        SizedBox(height: 2.h),
        _buildInsightCard(
          'Revenue Correlation',
          'Groups with high marketplace activity',
          Icons.trending_up,
          Colors.green,
        ),
        SizedBox(height: 2.h),
        _buildInsightCard(
          'Moderation Impact',
          'Effect of strict moderation on sales',
          Icons.security,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
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
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
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
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversionFunnelCard(Map<String, dynamic> funnel) {
    final totalOrders = funnel['total_orders'] ?? 0;
    final inProgress = funnel['in_progress'] ?? 0;
    final completed = funnel['completed'] ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversion Funnel',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          _buildFunnelRow('Total Orders', totalOrders, totalOrders),
          _buildFunnelRow('In Progress', inProgress, totalOrders),
          _buildFunnelRow('Completed', completed, totalOrders),
        ],
      ),
    );
  }

  Widget _buildFunnelRow(String label, int value, int total) {
    final percentage = total > 0 ? (value / total) * 100 : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 11.sp)),
              Text(
                '$value (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart(Map<String, dynamic> categories) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 40.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: categories.entries.map((entry) {
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '${entry.value}',
                    color: _getColorForIndex(
                      categories.keys.toList().indexOf(entry.key),
                    ),
                    radius: 50,
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: categories.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 3.w,
                    height: 3.w,
                    decoration: BoxDecoration(
                      color: _getColorForIndex(
                        categories.keys.toList().indexOf(entry.key),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Text(entry.key, style: TextStyle(fontSize: 10.sp)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberGrowthChart(List<dynamic> growthData) {
    if (growthData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 30.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: growthData.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  (entry.value['new_members'] ?? 0).toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: AppTheme.primaryLight,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationsBarChart(Map<String, dynamic> violations) {
    if (violations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 30.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          barGroups: violations.entries.toList().asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  color: Colors.red,
                  width: 20,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final title = service['title'] ?? 'Unknown Service';
    final totalOrders = service['total_orders'] ?? 0;
    final totalRevenue = service['total_revenue'] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 12.sp)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalOrders orders',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
              ),
              Text(
                '\$${totalRevenue.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final groupData = group['user_groups'] ?? {};
    final name = groupData['name'] ?? 'Unknown Group';
    final memberCount = group['member_count'] ?? 0;
    final engagementRate = group['engagement_rate'] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(name, style: TextStyle(fontSize: 12.sp)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$memberCount members',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
              ),
              Text(
                '${engagementRate.toStringAsFixed(1)}% engagement',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 8.w),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
}
