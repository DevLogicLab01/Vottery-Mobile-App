import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import './widgets/partnership_performance_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

class CreatorMonetizationAnalyticsDashboard extends StatefulWidget {
  const CreatorMonetizationAnalyticsDashboard({super.key});

  @override
  State<CreatorMonetizationAnalyticsDashboard> createState() =>
      _CreatorMonetizationAnalyticsDashboardState();
}

class _CreatorMonetizationAnalyticsDashboardState
    extends State<CreatorMonetizationAnalyticsDashboard> {
  bool _isLoading = true;
  bool _autoRefreshEnabled = true;
  Timer? _refreshTimer;
  String? _error;

  Map<String, dynamic> _earningsOverview = {};
  List<Map<String, dynamic>> _contentTypeBreakdown = [];
  List<Map<String, dynamic>> _geographicRevenue = [];
  List<Map<String, dynamic>> _partnershipPerformance = [];
  List<Map<String, dynamic>> _revenueForecasts = [];
  List<Map<String, dynamic>> _optimizationRecommendations = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    if (_autoRefreshEnabled) {
      _refreshTimer = Timer.periodic(Duration(minutes: 10), (_) {
        if (mounted) {
          _loadAnalyticsData(silent: true);
        }
      });
    }
  }

  Future<void> _loadAnalyticsData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _loadEarningsOverview(),
        _loadContentTypeBreakdown(),
        _loadGeographicRevenue(),
        _loadPartnershipPerformance(),
        _loadRevenueForecasts(),
        _loadOptimizationRecommendations(),
      ]);

      if (mounted) {
        setState(() {
          _earningsOverview = results[0] as Map<String, dynamic>;
          _contentTypeBreakdown = results[1] as List<Map<String, dynamic>>;
          _geographicRevenue = results[2] as List<Map<String, dynamic>>;
          _partnershipPerformance = results[3] as List<Map<String, dynamic>>;
          _revenueForecasts = results[4] as List<Map<String, dynamic>>;
          _optimizationRecommendations =
              results[5] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unable to load monetization analytics.';
        });
      }
    }
  }

  Future<Map<String, dynamic>> _loadEarningsOverview() async {
    await Future.delayed(Duration(milliseconds: 300));
    return {
      'total_revenue': 45678.50,
      'growth_percentage': 23.5,
      'forecast_confidence': 87.0,
      'period': 'Last 30 days',
    };
  }

  Future<List<Map<String, dynamic>>> _loadContentTypeBreakdown() async {
    await Future.delayed(Duration(milliseconds: 300));
    return [
      {
        'content_type': 'Plurality Elections',
        'revenue': 18500.00,
        'transaction_count': 245,
        'avg_revenue_per_election': 75.51,
        'engagement_rate': 0.68,
        'conversion_rate': 0.42,
      },
      {
        'content_type': 'Ranked Choice Elections',
        'revenue': 12300.00,
        'transaction_count': 156,
        'avg_revenue_per_election': 78.85,
        'engagement_rate': 0.72,
        'conversion_rate': 0.45,
      },
      {
        'content_type': 'Approval Voting',
        'revenue': 8900.00,
        'transaction_count': 123,
        'avg_revenue_per_election': 72.36,
        'engagement_rate': 0.65,
        'conversion_rate': 0.38,
      },
      {
        'content_type': 'Gamified Elections',
        'revenue': 5978.50,
        'transaction_count': 78,
        'avg_revenue_per_election': 76.65,
        'engagement_rate': 0.89,
        'conversion_rate': 0.62,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _loadGeographicRevenue() async {
    await Future.delayed(Duration(milliseconds: 300));
    return [
      {
        'zone': 'US_Canada',
        'revenue': 15200.00,
        'percentage': 33.3,
        'growth': 18.5,
      },
      {
        'zone': 'Western_Europe',
        'revenue': 12800.00,
        'percentage': 28.0,
        'growth': 22.3,
      },
      {
        'zone': 'Eastern_Europe',
        'revenue': 6500.00,
        'percentage': 14.2,
        'growth': 15.7,
      },
      {
        'zone': 'Middle_East_Asia',
        'revenue': 5400.00,
        'percentage': 11.8,
        'growth': 28.9,
      },
      {
        'zone': 'Latin_America',
        'revenue': 3200.00,
        'percentage': 7.0,
        'growth': 12.4,
      },
      {
        'zone': 'Australasia',
        'revenue': 1578.50,
        'percentage': 3.5,
        'growth': 9.2,
      },
      {'zone': 'Africa', 'revenue': 1000.00, 'percentage': 2.2, 'growth': 5.8},
    ];
  }

  Future<List<Map<String, dynamic>>> _loadPartnershipPerformance() async {
    await Future.delayed(Duration(milliseconds: 300));
    return [
      {
        'partner_name': 'TechCorp',
        'revenue_per_partnership': 2500.00,
        'completion_rate': 0.95,
        'brand_satisfaction_score': 4.8,
        'renewal_rate': 0.90,
      },
      {
        'partner_name': 'GlobalBrand',
        'revenue_per_partnership': 1800.00,
        'completion_rate': 0.88,
        'brand_satisfaction_score': 4.5,
        'renewal_rate': 0.85,
      },
      {
        'partner_name': 'StartupX',
        'revenue_per_partnership': 1200.00,
        'completion_rate': 0.92,
        'brand_satisfaction_score': 4.6,
        'renewal_rate': 0.80,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _loadRevenueForecasts() async {
    await Future.delayed(Duration(milliseconds: 300));
    return [
      {
        'horizon': '30 days',
        'predicted_amount': 52300.00,
        'confidence_level': 87.0,
        'forecast_method': 'ARIMA',
      },
      {
        'horizon': '60 days',
        'predicted_amount': 108500.00,
        'confidence_level': 82.0,
        'forecast_method': 'ARIMA',
      },
      {
        'horizon': '90 days',
        'predicted_amount': 167800.00,
        'confidence_level': 75.0,
        'forecast_method': 'ARIMA',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _loadOptimizationRecommendations() async {
    await Future.delayed(Duration(milliseconds: 300));
    return [
      {
        'recommendation':
            'Your Africa zone engagement is 40% below average - consider localized content with regional themes',
        'category': 'Geographic Expansion',
        'priority': 'high',
        'potential_impact': 3500.00,
      },
      {
        'recommendation':
            'Gamified elections generate 3x engagement - increase frequency from 20% to 40% of content',
        'category': 'Content Strategy',
        'priority': 'critical',
        'potential_impact': 8200.00,
      },
      {
        'recommendation':
            'Middle East Asia shows 28.9% growth - allocate more marketing budget to this region',
        'category': 'Marketing Optimization',
        'priority': 'medium',
        'potential_impact': 2800.00,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CreatorMonetizationAnalyticsDashboard',
      onRetry: _loadAnalyticsData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Creator Monetization Analytics',
          actions: [
            IconButton(
              icon: Icon(
                _autoRefreshEnabled ? Icons.pause_circle : Icons.play_circle,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _autoRefreshEnabled = !_autoRefreshEnabled;
                  if (_autoRefreshEnabled) {
                    _setupAutoRefresh();
                  } else {
                    _refreshTimer?.cancel();
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _loadAnalyticsData(),
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _earningsOverview.isEmpty
            ? NoEarningsEmptyState(
                onLearnMore: () {
                  // Navigate to monetization guide
                },
              )
            : RefreshIndicator(
                onRefresh: () => _loadAnalyticsData(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 2.h),
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: const Color(0xFF92400E),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monetization Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'Total Revenue: \$${_earningsOverview['total_revenue']}',
                              ),
                              Text(
                                'Growth: ${_earningsOverview['growth_percentage']}%',
                              ),
                              Text(
                                'Forecast Confidence: ${_earningsOverview['forecast_confidence']}%',
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Content Type Breakdown',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ..._contentTypeBreakdown.map(
                                (item) => Text(
                                  '${item['content_type']}: \$${item['revenue']}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Geographic Revenue Analysis',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ..._geographicRevenue.map(
                                (item) => Text(
                                  '${item['zone']}: \$${item['revenue']}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      PartnershipPerformanceWidget(
                        partnershipPerformance: _partnershipPerformance,
                      ),
                      SizedBox(height: 2.h),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Revenue Forecasts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ..._revenueForecasts.map(
                                (item) => Text(
                                  '${item['horizon']}: \$${item['predicted_amount']}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Optimization Recommendations',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ..._optimizationRecommendations.map(
                                (item) => Text(
                                  '${item['recommendation']}\nCategory: ${item['category']}\nPriority: ${item['priority']}\nPotential Impact: \$${item['potential_impact']}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
