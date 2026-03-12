import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/adsense_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/ad_loading_states_widget.dart';
import './widgets/ad_unit_configuration_widget.dart';
import './widgets/live_ad_serving_widget.dart';
import './widgets/performance_monitoring_widget.dart';
import './widgets/revenue_analytics_dashboard_widget.dart';
import './widgets/strategic_placement_manager_widget.dart';

class GoogleAdSenseLiveIntegrationHub extends StatefulWidget {
  const GoogleAdSenseLiveIntegrationHub({super.key});

  @override
  State<GoogleAdSenseLiveIntegrationHub> createState() =>
      _GoogleAdSenseLiveIntegrationHubState();
}

class _GoogleAdSenseLiveIntegrationHubState
    extends State<GoogleAdSenseLiveIntegrationHub>
    with SingleTickerProviderStateMixin {
  final AdSenseService _adSenseService = AdSenseService.instance;
  late TabController _tabController;

  bool _isLoading = true;
  bool _isAdSdkInitialized = false;
  Map<String, dynamic> _revenueData = {};
  List<Map<String, dynamic>> _adUnits = [];
  Map<String, dynamic> _performanceMetrics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initializeAdSdk();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeAdSdk() async {
    try {
      await MobileAds.instance.initialize();
      setState(() => _isAdSdkInitialized = true);
      debugPrint('Google Mobile Ads SDK initialized successfully');
    } catch (e) {
      debugPrint('Ad SDK initialization error: $e');
    }
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
        _loadAdUnits(),
      ]);

      setState(() {
        _revenueData = results[0] as Map<String, dynamic>;
        _performanceMetrics = results[1] as Map<String, dynamic>;
        _adUnits = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadAdUnits() async {
    return [
      {
        'id': 'banner_jolts_feed',
        'type': 'banner',
        'placement': 'Jolts Feed',
        'size': 'BANNER (320x50)',
        'status': 'active',
        'impressions': 12450,
        'clicks': 187,
        'revenue': 45.32,
      },
      {
        'id': 'interstitial_election_discovery',
        'type': 'interstitial',
        'placement': 'Election Discovery',
        'size': 'FULL_SCREEN',
        'status': 'active',
        'impressions': 3420,
        'clicks': 98,
        'revenue': 78.50,
      },
      {
        'id': 'rewarded_dashboard',
        'type': 'rewarded',
        'placement': 'User Dashboard',
        'size': 'FULL_SCREEN',
        'status': 'active',
        'impressions': 1850,
        'clicks': 245,
        'revenue': 125.75,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'GoogleAdSenseLiveIntegrationHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('AdSense Live Integration'),
          actions: [
            IconButton(
              icon: Icon(
                _isAdSdkInitialized ? Icons.check_circle : Icons.error,
                color: _isAdSdkInitialized ? Colors.green : Colors.red,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isAdSdkInitialized
                          ? 'Ad SDK Initialized'
                          : 'Ad SDK Not Initialized',
                    ),
                  ),
                );
              },
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Live Ads'),
              Tab(text: 'Ad Units'),
              Tab(text: 'Placements'),
              Tab(text: 'Revenue'),
              Tab(text: 'Loading States'),
              Tab(text: 'Performance'),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildRevenueHeader(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        LiveAdServingWidget(
                          isAdSdkInitialized: _isAdSdkInitialized,
                          onRefresh: _loadData,
                        ),
                        AdUnitConfigurationWidget(
                          adUnits: _adUnits,
                          onRefresh: _loadData,
                        ),
                        StrategicPlacementManagerWidget(
                          adUnits: _adUnits,
                          onRefresh: _loadData,
                        ),
                        RevenueAnalyticsDashboardWidget(
                          revenueData: _revenueData,
                          onRefresh: _loadData,
                        ),
                        AdLoadingStatesWidget(
                          isAdSdkInitialized: _isAdSdkInitialized,
                        ),
                        PerformanceMonitoringWidget(
                          metrics: _performanceMetrics,
                          onRefresh: _loadData,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRevenueHeader() {
    final totalRevenue = _revenueData['total_revenue'] ?? 0.0;
    final activeAdUnits = _adUnits.where((u) => u['status'] == 'active').length;
    final totalImpressions = _revenueData['total_impressions'] ?? 0;
    final avgCpm = _revenueData['ecpm'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
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
              'Active Ad Units',
              activeAdUnits.toString(),
              Icons.ad_units,
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
              'Avg CPM',
              '\$${avgCpm.toStringAsFixed(2)}',
              Icons.trending_up,
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
