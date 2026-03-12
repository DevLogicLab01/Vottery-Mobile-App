import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/carousel_roi_analytics_service.dart';
import '../../theme/app_theme.dart';

/// Carousel ROI Analytics Dashboard
/// Revenue analysis with zone-specific breakdown, sponsorship tracking, and forecasting
class CarouselROIAnalyticsDashboard extends StatefulWidget {
  const CarouselROIAnalyticsDashboard({super.key});

  @override
  State<CarouselROIAnalyticsDashboard> createState() =>
      _CarouselROIAnalyticsDashboardState();
}

class _CarouselROIAnalyticsDashboardState
    extends State<CarouselROIAnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  final CarouselROIAnalyticsService _roiService =
      CarouselROIAnalyticsService.instance;

  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic> _revenueByCarousel = {};
  Map<String, dynamic> _zoneAnalysis = {};
  List<Map<String, dynamic>> _sponsorships = [];
  Map<String, dynamic> _forecast = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final revenue = await _roiService.getRevenueByCarouselType();
      final zones = await _roiService.getRevenueByZone();
      final sponsors = await _roiService.getSponsorshipPerformance();
      final forecast = await _roiService.generateRevenueForecast(
        carouselType: 'horizontal_snap',
        forecastPeriod: '30_days',
      );

      setState(() {
        _revenueByCarousel = revenue['by_carousel_type'] as Map<String, dynamic>? ?? {};
        _zoneAnalysis = zones['by_zone'] as Map<String, dynamic>? ?? {};
        _sponsorships = sponsors;
        _forecast = forecast;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading ROI analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'ROI Analytics',
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
            Tab(text: 'Revenue'),
            Tab(text: 'Zones'),
            Tab(text: 'Sponsors'),
            Tab(text: 'Forecast'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRevenueTab(),
                _buildZonesTab(),
                _buildSponsorsTab(),
                _buildForecastTab(),
              ],
            ),
    );
  }

  Widget _buildRevenueTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Revenue Breakdown'),
            SizedBox(height: 2.h),
            _buildRevenueOverviewCards(),
            SizedBox(height: 3.h),
            _buildSectionTitle('Revenue by Carousel Type'),
            SizedBox(height: 2.h),
            _buildRevenueByCarouselChart(),
            SizedBox(height: 3.h),
            _buildSectionTitle('Performance Comparison'),
            SizedBox(height: 2.h),
            _buildPerformanceTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueOverviewCards() {
    final totalRevenue = _revenueByCarousel.values.fold<double>(
      0.0,
      (sum, carousel) =>
          sum + ((carousel['total_revenue'] as num?)?.toDouble() ?? 0.0),
    );

    final avgRPM = _revenueByCarousel.values.isNotEmpty
        ? _revenueByCarousel.values.fold<double>(
                0.0,
                (sum, carousel) =>
                    sum + ((carousel['rpm'] as num?)?.toDouble() ?? 0.0),
              ) /
              _revenueByCarousel.length
        : 0.0;

    return Wrap(
      spacing: 2.w,
      runSpacing: 2.h,
      children: [
        _buildMetricCard(
          'Total Revenue',
          '\$${totalRevenue.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildMetricCard(
          'Avg RPM',
          '\$${avgRPM.toStringAsFixed(2)}',
          Icons.trending_up,
          Colors.blue,
        ),
        _buildMetricCard(
          'Carousels',
          '${_revenueByCarousel.length}',
          Icons.view_carousel,
          Colors.purple,
        ),
        _buildMetricCard(
          'Profit Margin',
          '23%',
          Icons.pie_chart,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 43.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              Icon(icon, color: color, size: 20.sp),
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

  Widget _buildRevenueByCarouselChart() {
    final sections = _revenueByCarousel.entries.map((entry) {
      final revenue = (entry.value['total_revenue'] as num?)?.toDouble() ?? 0.0;
      return PieChartSectionData(
        value: revenue,
        title: '${entry.key.split('_')[0]}\n\$${revenue.toStringAsFixed(0)}',
        color: _getCarouselColor(entry.key),
        radius: 80,
        titleStyle: TextStyle(fontSize: 11.sp, color: Colors.white),
      );
    }).toList();

    return Container(
      height: 30.h,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Color _getCarouselColor(String carouselType) {
    switch (carouselType) {
      case 'horizontal_snap':
        return Colors.blue;
      case 'vertical_stack':
        return Colors.green;
      case 'gradient_flow':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPerformanceTable() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          ..._revenueByCarousel.entries.map((entry) {
            return _buildTableRow(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Type',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Revenue',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'RPM',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String type, Map<String, dynamic> data) {
    final revenue = (data['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final rpm = (data['rpm'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              type.replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textPrimaryDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '\$${revenue.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textPrimaryDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '\$${rpm.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Zone Performance'),
            SizedBox(height: 2.h),
            ..._zoneAnalysis.entries.map((entry) {
              return _buildZoneCard(entry.key, entry.value);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneCard(String zone, Map<String, dynamic> data) {
    final revenue = (data['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final arpu = (data['arpu'] as num?)?.toDouble() ?? 0.0;
    final userCount = data['user_count'] as int? ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            zone,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '\$${revenue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ARPU',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '\$${arpu.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Users',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '$userCount',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: _sponsorships.isEmpty
          ? Center(
              child: Text(
                'No sponsorships found',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: _sponsorships.length,
              itemBuilder: (context, index) {
                return _buildSponsorCard(_sponsorships[index]);
              },
            ),
    );
  }

  Widget _buildSponsorCard(Map<String, dynamic> sponsor) {
    final investment = (sponsor['investment'] as num?)?.toDouble() ?? 0.0;
    final revenue = (sponsor['revenue'] as num?)?.toDouble() ?? 0.0;
    final roi = (sponsor['roi'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sponsor['carousel_type'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryDark,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: roi > 0
                      ? Colors.green.withAlpha(51)
                      : Colors.red.withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'ROI: ${roi.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: roi > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Investment: \$${investment.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              Text(
                'Revenue: \$${revenue.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Text(
                'Impressions: ${sponsor['impressions_delivered'] ?? 0}',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Clicks: ${sponsor['clicks'] ?? 0}',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Conversions: ${sponsor['conversions'] ?? 0}',
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

  Widget _buildForecastTab() {
    final predictedRevenue =
        (_forecast['predicted_revenue'] as num?)?.toDouble() ?? 0.0;
    final confidenceLower =
        (_forecast['confidence_interval_lower'] as num?)?.toDouble() ?? 0.0;
    final confidenceUpper =
        (_forecast['confidence_interval_upper'] as num?)?.toDouble() ?? 0.0;

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('30-Day Revenue Forecast'),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: [
                  Text(
                    'Predicted Revenue',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '\$${predictedRevenue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Lower Bound',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                          Text(
                            '\$${confidenceLower.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Upper Bound',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                          Text(
                            '\$${confidenceUpper.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),
            if (_forecast['note'] != null)
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20.sp),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        _forecast['note'] as String,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textPrimaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryDark,
      ),
    );
  }
}