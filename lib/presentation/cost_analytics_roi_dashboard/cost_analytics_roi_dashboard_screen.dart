import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/infrastructure_cost_tracking_service.dart';
import './widgets/cache_roi_summary_widget.dart';
import './widgets/cost_recommendation_card_widget.dart';
import './widgets/service_cost_card_widget.dart';
import './widgets/total_cost_card_widget.dart';

class CostAnalyticsRoiDashboardScreen extends StatefulWidget {
  const CostAnalyticsRoiDashboardScreen({super.key});

  @override
  State<CostAnalyticsRoiDashboardScreen> createState() =>
      _CostAnalyticsRoiDashboardScreenState();
}

class _CostAnalyticsRoiDashboardScreenState
    extends State<CostAnalyticsRoiDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = InfrastructureCostTrackingService.instance;

  List<ServiceCost> _serviceCosts = [];
  CacheRoiMetrics? _cacheRoi;
  double _totalCost = 0.0;
  double _costPerQuery = 0.0;
  bool _isLoading = true;

  static const _tabs = [
    Tab(text: 'Overview'),
    Tab(text: 'Per-Service'),
    Tab(text: 'ROI Analysis'),
    Tab(text: 'Recommendations'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        _service.getServiceCosts(),
        _service.getCacheRoiMetrics(),
        _service.getTotalMonthlyCost(),
        _service.getCostPerQuery(),
      ]);
      setState(() {
        _serviceCosts = results[0] as List<ServiceCost>;
        _cacheRoi = results[1] as CacheRoiMetrics;
        _totalCost = results[2] as double;
        _costPerQuery = results[3] as double;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Cost Analytics & ROI',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
          tabs: _tabs,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPerServiceTab(),
                _buildRoiAnalysisTab(),
                _buildRecommendationsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final costPerUser = _totalCost / 10000; // per 10K MAU
    return ListView(
      children: [
        TotalCostCard(
          totalMonthlyCost: _totalCost,
          trendVsLastMonth: 3.2,
          costPerQuery: _costPerQuery,
          costPerUser: costPerUser,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          child: Text(
            'Cost Breakdown',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        _buildCostBreakdownChart(),
        SizedBox(height: 1.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.blue.shade600),
              SizedBox(width: 1.w),
              Text(
                'Target: < \$0.002 per query',
                style: TextStyle(fontSize: 11.sp, color: Colors.blue.shade700),
              ),
              const Spacer(),
              Text(
                'Current: \$${_costPerQuery.toStringAsFixed(4)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: _costPerQuery < 0.002
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildCostBreakdownChart() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Cost Distribution',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 2.h),
            ..._serviceCosts.map((sc) {
              final pct = _totalCost > 0 ? sc.monthlyCost / _totalCost : 0.0;
              final color = _serviceColor(sc.serviceName);
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18.w,
                      child: Text(
                        sc.serviceName,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 10,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
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

  Widget _buildPerServiceTab() {
    return ListView.builder(
      itemCount: _serviceCosts.length,
      itemBuilder: (_, i) =>
          ServiceCostCard(serviceCost: _serviceCosts[i], totalCost: _totalCost),
    );
  }

  Widget _buildRoiAnalysisTab() {
    if (_cacheRoi == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      children: [
        CacheRoiSummaryWidget(metrics: _cacheRoi!),
        SizedBox(height: 1.h),
      ],
    );
  }

  Widget _buildRecommendationsTab() {
    final recommendations = _service.getCostRecommendations();
    final totalAnnualSavings = recommendations.fold(
      0.0,
      (sum, r) => sum + r.annualSavings,
    );
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          color: Colors.green.shade50,
          child: Row(
            children: [
              Icon(Icons.savings, color: Colors.green.shade700, size: 22),
              SizedBox(width: 2.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Potential Savings',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    '\$${totalAnnualSavings.toStringAsFixed(0)}/year',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: recommendations.length,
            itemBuilder: (_, i) =>
                CostRecommendationCard(recommendation: recommendations[i]),
          ),
        ),
      ],
    );
  }

  Color _serviceColor(String name) {
    switch (name.toLowerCase()) {
      case 'supabase':
        return Colors.green.shade600;
      case 'datadog':
        return Colors.purple.shade600;
      case 'redis':
        return Colors.red.shade600;
      default:
        return Colors.blue.shade600;
    }
  }
}
