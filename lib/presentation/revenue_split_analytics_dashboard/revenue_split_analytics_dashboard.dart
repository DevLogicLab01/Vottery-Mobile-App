import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/revenue_share_service.dart';
import '../../services/revenue_split_forecasting_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Revenue Split Analytics Dashboard
/// Delivers comprehensive performance insights and effectiveness tracking for
/// country-based revenue sharing strategies with predictive modeling and optimization recommendations.
class RevenueSplitAnalyticsDashboard extends StatefulWidget {
  const RevenueSplitAnalyticsDashboard({super.key});

  @override
  State<RevenueSplitAnalyticsDashboard> createState() =>
      _RevenueSplitAnalyticsDashboardState();
}

class _RevenueSplitAnalyticsDashboardState
    extends State<RevenueSplitAnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  final RevenueShareService _revenueService = RevenueShareService.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> _regionalAnalytics = [];
  Map<String, dynamic> _overviewMetrics = {};
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _aiOptimizations;
  bool _aiLoading = false;

  // Local cache for mobile - 5 min TTL to reduce refetches
  static Map<String, dynamic>? _cache;
  static DateTime? _cacheTime;
  static const _cacheTtl = Duration(minutes: 5);

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
    if (_cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheTtl) {
      setState(() {
        _regionalAnalytics = List<Map<String, dynamic>>.from(_cache!['regional'] ?? []);
        _overviewMetrics = Map<String, dynamic>.from(_cache!['overview'] ?? {});
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _revenueService.getRegionalRevenueAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      ),
      _revenueService.getSplitEffectivenessMetrics(),
    ]);

    if (mounted) {
      _cache = {
        'regional': results[0],
        'overview': results[1],
      };
      _cacheTime = DateTime.now();
      setState(() {
        _regionalAnalytics = results[0] as List<Map<String, dynamic>>;
        _overviewMetrics = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    _cache = null;
    _cacheTime = null;
    await _loadAnalyticsData();
  }

  Future<void> _generateAIRecommendations() async {
    setState(() {
      _aiOptimizations = null;
      _aiLoading = true;
    });
    try {
      final result = await RevenueSplitForecastingService.instance
          .generateClaudeOptimizations(
        {'creatorPercentage': 70, 'platformPercentage': 30},
        {'historical': _regionalAnalytics},
      );
      if (mounted) {
        setState(() {
          _aiOptimizations = result;
          _aiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _aiLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI optimization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildOptimizationInsightsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Split Optimization',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _aiLoading ? null : _generateAIRecommendations,
                icon: _aiLoading
                    ? SizedBox(
                        width: 16.sp,
                        height: 16.sp,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.auto_awesome, size: 18.sp),
                label: Text(_aiLoading ? 'Generating...' : 'Generate AI Recommendations'),
              ),
            ],
          ),
          if (_aiOptimizations != null) ...[
            SizedBox(height: 3.h),
            if (_aiOptimizations!['recommendations'] != null)
              ...((_aiOptimizations!['recommendations'] as List)
                  .map<Widget>((r) => Container(
                        margin: EdgeInsets.only(bottom: 2.h),
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (r['title'] ?? r['newSplit'] ?? 'Recommendation')
                                  .toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                              ),
                            ),
                            if (r['reasoning'] != null)
                              Padding(
                                padding: EdgeInsets.only(top: 1.h),
                                child: Text(
                                  r['reasoning'].toString(),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            if (r['impact'] != null || r['risk'] != null)
                              Padding(
                                padding: EdgeInsets.only(top: 1.h),
                                child: Text(
                                  'Impact: ${r['impact']} | Risk: ${r['risk']} | Confidence: ${r['confidence']}%',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ))
                  .toList()),
            if (_aiOptimizations!['strategicTiming'] != null) ...[
              SizedBox(height: 2.h),
              Text(
                'Strategic Timing',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                _aiOptimizations!['strategicTiming'] is String
                    ? _aiOptimizations!['strategicTiming'] as String
                    : _aiOptimizations!['strategicTiming'].toString(),
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
              ),
            ],
            if (_aiOptimizations!['implementationSteps'] != null) ...[
              SizedBox(height: 2.h),
              Text(
                'Implementation Steps',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 1.h),
              ...((_aiOptimizations!['implementationSteps'] as List)
                  .map<Widget>((s) => Padding(
                        padding: EdgeInsets.only(bottom: 0.5.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                            Expanded(
                              child: Text(
                                s is String ? s : (s['step'] ?? s['description'] ?? s).toString(),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList()),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalyticsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'RevenueSplitAnalyticsDashboard',
      onRetry: _loadAnalyticsData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Revenue Split Analytics',
          actions: [
            IconButton(
              icon: Icon(Icons.date_range, size: 20.sp),
              onPressed: _selectDateRange,
            ),
            IconButton(
              icon: Icon(Icons.refresh, size: 20.sp),
              onPressed: _refreshData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 2.h),
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: Theme.of(context).primaryColor,
                        labelStyle: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Split Performance'),
                          Tab(text: 'Creator Satisfaction'),
                          Tab(text: 'Geographic Revenue'),
                          Tab(text: 'Optimization Insights'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          Center(child: Text('Split Performance Analytics')),
                          Center(child: Text('Creator Satisfaction Analytics')),
                          Center(
                            child: Text('Geographic Revenue Visualization'),
                          ),
                          _buildOptimizationInsightsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}