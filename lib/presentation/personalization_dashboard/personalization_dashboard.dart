import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/carousel_personalization_service.dart';
import '../../theme/app_theme.dart';

/// Personalization Dashboard Screen
/// Displays user segments, ML model performance, device tiers, and personalization analytics
class PersonalizationDashboardScreen extends StatefulWidget {
  const PersonalizationDashboardScreen({super.key});

  @override
  State<PersonalizationDashboardScreen> createState() =>
      _PersonalizationDashboardScreenState();
}

class _PersonalizationDashboardScreenState
    extends State<PersonalizationDashboardScreen>
    with SingleTickerProviderStateMixin {
  final CarouselPersonalizationService _personalizationService =
      CarouselPersonalizationService.instance;

  late TabController _tabController;
  bool _isLoading = true;

  Map<String, int> _segmentDistribution = {};
  Map<String, dynamic> _mlPerformance = {};
  List<String> _userSegments = [];
  List<String> _personalizedSequence = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _personalizationService.getSegmentDistribution(),
        _personalizationService.getMLModelPerformance(),
        _personalizationService.assignUserSegments(),
        _personalizationService.getPersonalizedCarouselSequence(),
      ]);

      setState(() {
        _segmentDistribution = results[0] as Map<String, int>;
        _mlPerformance = results[1] as Map<String, dynamic>;
        _userSegments = results[2] as List<String>;
        _personalizedSequence = results[3] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load data error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Personalization Dashboard',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondaryLight,
          indicatorColor: AppTheme.primaryLight,
          tabs: const [
            Tab(text: 'Segments'),
            Tab(text: 'ML Performance'),
            Tab(text: 'My Profile'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSegmentsTab(),
                _buildMLPerformanceTab(),
                _buildMyProfileTab(),
              ],
            ),
    );
  }

  Widget _buildSegmentsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Segments Overview',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            SizedBox(height: 2.h),
            _buildSegmentDistributionChart(),
            SizedBox(height: 3.h),
            Text(
              'Segment Details',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            SizedBox(height: 2.h),
            ..._buildSegmentCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentDistributionChart() {
    if (_segmentDistribution.isEmpty) {
      return Container(
        height: 30.h,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            'No segment data available',
            style: TextStyle(
              color: AppTheme.textSecondaryLight,
              fontSize: 14.sp,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 30.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: PieChart(
        PieChartData(
          sections: _segmentDistribution.entries.map((entry) {
            final color = _getSegmentColor(entry.key);
            return PieChartSectionData(
              value: entry.value.toDouble(),
              title: '${entry.value}',
              color: color,
              radius: 50,
              titleStyle: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Color _getSegmentColor(String segment) {
    final colors = {
      'high_engagement': Colors.green,
      'content_creators': Colors.blue,
      'price_sensitive': Colors.orange,
      'early_adopters': Colors.purple,
      'power_users': Colors.red,
      'casual_browsers': Colors.grey,
    };
    return colors[segment] ?? Colors.grey;
  }

  List<Widget> _buildSegmentCards() {
    return _segmentDistribution.entries.map((entry) {
      return Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: _getSegmentColor(entry.key),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${entry.value} users',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildMLPerformanceTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ML Model Performance',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            SizedBox(height: 2.h),
            _buildMetricCard(
              'Total Predictions',
              '${_mlPerformance['total_predictions'] ?? 0}',
              Icons.analytics,
              Colors.blue,
            ),
            SizedBox(height: 2.h),
            _buildMetricCard(
              'Prediction Accuracy',
              '${(_mlPerformance['accuracy'] ?? 0.0).toStringAsFixed(1)}%',
              Icons.check_circle,
              Colors.green,
            ),
            SizedBox(height: 2.h),
            _buildMetricCard(
              'Average Confidence',
              '${(_mlPerformance['confidence_avg'] ?? 0.0).toStringAsFixed(2)}',
              Icons.trending_up,
              Colors.orange,
            ),
          ],
        ),
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
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProfileTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Segments',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            SizedBox(height: 2.h),
            if (_userSegments.isEmpty)
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'No segments assigned yet',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: _userSegments.map((segment) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getSegmentColor(segment),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      segment.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: 3.h),
            Text(
              'Personalized Carousel Sequence',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            SizedBox(height: 2.h),
            ..._personalizedSequence.asMap().entries.map((entry) {
              final index = entry.key;
              final carousel = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 2.h),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        carousel.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryDark,
                        ),
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
}
