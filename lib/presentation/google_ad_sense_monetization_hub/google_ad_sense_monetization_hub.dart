import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/adsense_service.dart';
import './widgets/ad_placement_manager_widget.dart';
import './widgets/gdpr_compliance_widget.dart';
import './widgets/optimization_tools_widget.dart';
import './widgets/performance_metrics_widget.dart';
import './widgets/revenue_analytics_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

class GoogleAdSenseMonetizationHub extends StatefulWidget {
  const GoogleAdSenseMonetizationHub({super.key});

  @override
  State<GoogleAdSenseMonetizationHub> createState() =>
      _GoogleAdSenseMonetizationHubState();
}

class _GoogleAdSenseMonetizationHubState
    extends State<GoogleAdSenseMonetizationHub>
    with SingleTickerProviderStateMixin {
  final AdSenseService _adSenseService = AdSenseService.instance;
  late TabController _tabController;

  Map<String, dynamic> _revenueData = {};
  Map<String, dynamic> _metricsData = {};
  List<Map<String, dynamic>> _placementData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      final results = await Future.wait([
        _adSenseService.getRevenueAnalytics(
          startDate: startDate,
          endDate: endDate,
        ),
        _adSenseService.getPerformanceMetrics(),
        _adSenseService.getPlacementPerformance(),
      ]);

      setState(() {
        _revenueData = results[0] as Map<String, dynamic>;
        _metricsData = results[1] as Map<String, dynamic>;
        _placementData = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load data error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'GoogleAdSenseMonetizationHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('AdSense Monetization Hub'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Ad Placement'),
              Tab(text: 'Revenue'),
              Tab(text: 'Performance'),
              Tab(text: 'Optimization'),
              Tab(text: 'Compliance'),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _placementData.isEmpty
            ? NoDataEmptyState(
                title: 'No Ad Placements',
                description:
                    'Configure ad placements to start earning revenue from your content.',
                onRefresh: _loadData,
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  AdPlacementManagerWidget(
                    placements: _placementData,
                    onRefresh: _loadData,
                  ),
                  RevenueAnalyticsWidget(
                    revenueData: _revenueData,
                    onRefresh: _loadData,
                  ),
                  PerformanceMetricsWidget(
                    metricsData: _metricsData,
                    onRefresh: _loadData,
                  ),
                  OptimizationToolsWidget(
                    placementData: _placementData,
                    onRefresh: _loadData,
                  ),
                  GdprComplianceWidget(onRefresh: _loadData),
                ],
              ),
      ),
    );
  }

  Widget _buildRevenueHeader() {
    final totalRevenue = _revenueData['total_revenue'] ?? 0.0;
    final dailyRevenue = _revenueData['daily_revenue'] ?? 0.0;
    final totalImpressions = _revenueData['total_impressions'] ?? 0;
    final ctr = _revenueData['ctr'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildHeaderStat(
              'Total Revenue',
              '\$${totalRevenue.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.green,
            ),
          ),
          Expanded(
            child: _buildHeaderStat(
              'Today',
              '\$${dailyRevenue.toStringAsFixed(2)}',
              Icons.today,
              Colors.blue,
            ),
          ),
          Expanded(
            child: _buildHeaderStat(
              'Impressions',
              totalImpressions.toString(),
              Icons.visibility,
              Colors.orange,
            ),
          ),
          Expanded(
            child: _buildHeaderStat(
              'CTR',
              '${ctr.toStringAsFixed(2)}%',
              Icons.touch_app,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
