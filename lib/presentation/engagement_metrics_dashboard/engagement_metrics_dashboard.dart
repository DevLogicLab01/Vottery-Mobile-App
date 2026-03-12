import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class EngagementMetricsDashboard extends StatefulWidget {
  const EngagementMetricsDashboard({super.key});

  @override
  State<EngagementMetricsDashboard> createState() =>
      _EngagementMetricsDashboardState();
}

class _EngagementMetricsDashboardState extends State<EngagementMetricsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _metricsData = {};
  DateTime _selectedStartDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();
  final String _comparisonMode = 'week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _metricsData = {
          'participation_rate': 68.5,
          'vote_funnel': {'views': 10000, 'started': 7500, 'completed': 6850},
          'engagement_score': 82.3,
          'social_reach': 45000,
          'follower_growth_rate': 12.5,
          'fraud_detection_rate': 0.3,
          'campaign_success_rate': 78.9,
          'brand_mentions_volume': 1250,
          'audience_demographics': {
            'age': {
              '18-24': 25,
              '25-34': 35,
              '35-44': 20,
              '45-54': 12,
              '55+': 8,
            },
            'gender': {'male': 52, 'female': 45, 'other': 3},
            'location': {
              'North America': 45,
              'Europe': 30,
              'Asia': 15,
              'Other': 10,
            },
          },
          'social_impressions': 125000,
          'engagement_rate': 8.5,
          'video_views': 45000,
          'watch_time': 125.5,
          'virality_coefficient': 1.8,
          'sentiment_analysis_score': 0.72,
          'audience_growth_rate': 15.3,
          'share_of_voice': 12.8,
          'conversion_rate': 4.2,
          'customer_acquisition_cost': 12.50,
          'presence_score': 85.0,
          'hashtag_performance': 92.0,
          'click_through_rate': 3.8,
          'cost_per_click': 0.85,
          'lead_generation_count': 450,
          'saved_posts_count': 1250,
          'reshare_count': 890,
          'story_completion_rate': 72.5,
          'time_on_platform': 18.5,
          'bounce_rate': 32.5,
          'return_visitor_rate': 58.3,
          'trends': {
            'engagement_trend': 'up',
            'engagement_change': 15.2,
            'virality_trend': 'up',
            'virality_change': 45.8,
          },
          'alerts': [
            {
              'type': 'warning',
              'message': 'Engagement dropped 20% in last 24 hours',
              'timestamp': DateTime.now().subtract(Duration(hours: 2)),
            },
          ],
        };
      });
    } catch (e) {
      debugPrint('Load metrics error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'EngagementMetricsDashboard',
      onRetry: _loadMetrics,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Engagement Metrics',
            variant: CustomAppBarVariant.withBack,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.file_download,
                  color: theme.appBarTheme.foregroundColor,
                ),
                onPressed: _exportReport,
              ),
              IconButton(
                icon: Icon(
                  Icons.date_range,
                  color: theme.appBarTheme.foregroundColor,
                ),
                onPressed: _selectDateRange,
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMetricsOverviewHeader(),
                    TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      indicatorColor: theme.colorScheme.primary,
                      isScrollable: true,
                      labelStyle: TextStyle(fontSize: 12.sp),
                      tabs: [
                        Tab(text: 'Core'),
                        Tab(text: 'Analytics'),
                        Tab(text: 'Social'),
                        Tab(text: 'Business'),
                        Tab(text: 'Insights'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCoreEngagementMetrics(),
                          _buildAdvancedAnalytics(),
                          _buildSocialPerformance(),
                          _buildBusinessIntelligence(),
                          _buildAutomatedInsights(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricsOverviewHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Center(child: Text('Metrics Overview Header')),
    );
  }

  Widget _buildCoreEngagementMetrics() {
    return Center(child: Text('Core Engagement Metrics'));
  }

  Widget _buildAdvancedAnalytics() {
    return Center(child: Text('Advanced Analytics'));
  }

  Widget _buildSocialPerformance() {
    return Center(child: Text('Social Performance'));
  }

  Widget _buildBusinessIntelligence() {
    return Center(child: Text('Business Intelligence'));
  }

  Widget _buildAutomatedInsights() {
    return Center(child: Text('Automated Insights'));
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: null,
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      _loadMetrics();
    }
  }

  Future<void> _exportReport() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                _performExport('pdf');
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart),
              title: Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                _performExport('csv');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performExport(String format) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting report as ${format.toUpperCase()}...'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report exported successfully'),
          backgroundColor: AppTheme.accentLight,
        ),
      );
    }
  }
}