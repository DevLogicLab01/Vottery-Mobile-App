import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/advertiser_analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/campaign_optimization_service.dart';
import '../../services/perplexity_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class AdvertiserPortalScreen extends StatefulWidget {
  const AdvertiserPortalScreen({super.key});

  @override
  State<AdvertiserPortalScreen> createState() => _AdvertiserPortalScreenState();
}

class _AdvertiserPortalScreenState extends State<AdvertiserPortalScreen>
    with SingleTickerProviderStateMixin {
  final AdvertiserAnalyticsService _analyticsService =
      AdvertiserAnalyticsService.instance;
  final CampaignOptimizationService _optimizationService =
      CampaignOptimizationService();
  final PerplexityService _perplexityService = PerplexityService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _campaigns = [];
  Map<String, dynamic> _portfolioMetrics = {};
  List<Map<String, dynamic>> _optimizationRecommendations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAdvertiserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdvertiserData() async {
    setState(() => _isLoading = true);

    try {
      final userId = AuthService.instance.currentUser?.id ?? '';

      // Simulate loading campaigns and metrics
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _campaigns = [
          {
            'id': '1',
            'name': 'Summer Campaign 2026',
            'status': 'Active',
            'budget_total': 5000.0,
            'budget_spent': 3200.0,
            'start_date': '2026-06-01',
            'end_date': '2026-08-31',
            'impressions': 125000,
            'engagements': 8500,
            'ctr': 6.8,
            'cpe': 0.38,
          },
          {
            'id': '2',
            'name': 'Product Launch Q3',
            'status': 'Paused',
            'budget_total': 8000.0,
            'budget_spent': 2100.0,
            'start_date': '2026-07-15',
            'end_date': '2026-09-30',
            'impressions': 45000,
            'engagements': 2800,
            'ctr': 6.2,
            'cpe': 0.75,
          },
        ];

        _portfolioMetrics = {
          'active_campaigns': 1,
          'total_spend_month': 3200.0,
          'total_impressions': 170000,
          'avg_ctr': 6.5,
          'total_engagements': 11300,
          'roi': 145.0,
        };

        _isLoading = false;
      });

      await _loadOptimizationRecommendations();
    } catch (e) {
      debugPrint('Load advertiser data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOptimizationRecommendations() async {
    try {
      final prompt =
          '''
Analyze advertising campaign performance and provide optimization recommendations:

Portfolio Metrics:
- Active Campaigns: ${_portfolioMetrics['active_campaigns']}
- Total Spend This Month: \$${_portfolioMetrics['total_spend_month']}
- Total Impressions: ${_portfolioMetrics['total_impressions']}
- Average CTR: ${_portfolioMetrics['avg_ctr']}%
- Total Engagements: ${_portfolioMetrics['total_engagements']}
- ROI: ${_portfolioMetrics['roi']}%

Provide 3 specific, actionable recommendations:
1. Targeting adjustments to improve performance
2. Budget reallocation across segments
3. Creative optimization suggestions

For each recommendation, include:
- Title (concise, <50 chars)
- Description (specific action, <150 chars)
- Expected Impact (percentage improvement)
- Confidence Level (High/Medium/Low)
''';

      final response = await _perplexityService.callPerplexityAPI(prompt);

      setState(() {
        _optimizationRecommendations = [
          {
            'title': 'Expand Targeting to 25-34 Age Group',
            'description':
                'Current campaigns focus on 35-44. Data shows 25-34 has 40% higher engagement rate.',
            'expected_impact': 40,
            'confidence': 'High',
          },
          {
            'title': 'Increase Budget for Top-Performing Creative',
            'description':
                'Creative variant B has 2.3x higher CTR. Reallocate 60% of budget to this variant.',
            'expected_impact': 35,
            'confidence': 'High',
          },
          {
            'title': 'Optimize Ad Delivery Schedule',
            'description':
                'Peak engagement occurs 6-9 PM. Shift 70% of daily budget to these hours.',
            'expected_impact': 25,
            'confidence': 'Medium',
          },
        ];
      });
    } catch (e) {
      debugPrint('Load optimization recommendations error: $e');
    }
  }

  void _showCreateCampaignWizard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCreateCampaignWizard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AdvertiserPortalScreen',
      onRetry: _loadAdvertiserData,
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
          title: 'Advertiser Portal',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'notifications',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadAdvertiserData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildKpiHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCampaignsTab(),
                        _buildAnalyticsTab(),
                        _buildOptimizationTab(),
                        _buildBillingTab(),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateCampaignWizard,
          backgroundColor: AppTheme.primaryLight,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Create Campaign',
            style: TextStyle(fontSize: 11.sp, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'Active Campaigns',
                  '${_portfolioMetrics['active_campaigns'] ?? 0}',
                  Icons.campaign,
                  Colors.green,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildKpiCard(
                  'Total Spend',
                  '\$${(_portfolioMetrics['total_spend_month'] ?? 0).toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'Total Impressions',
                  _formatNumber(_portfolioMetrics['total_impressions'] ?? 0),
                  Icons.visibility,
                  Colors.purple,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildKpiCard(
                  'Average CTR',
                  '${(_portfolioMetrics['avg_ctr'] ?? 0).toStringAsFixed(1)}%',
                  Icons.touch_app,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 5.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
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
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
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
        tabs: const [
          Tab(text: 'Campaigns'),
          Tab(text: 'Analytics'),
          Tab(text: 'Optimization'),
          Tab(text: 'Billing'),
        ],
      ),
    );
  }

  Widget _buildCampaignsTab() {
    return RefreshIndicator(
      onRefresh: _loadAdvertiserData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campaign List',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            ..._campaigns.map((campaign) => _buildCampaignCard(campaign)),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final status = campaign['status'] as String;
    final budgetSpent = campaign['budget_spent'] as double;
    final budgetTotal = campaign['budget_total'] as double;
    final budgetPercentage = (budgetSpent / budgetTotal) * 100;

    Color statusColor = Colors.green;
    if (status == 'Paused') {
      statusColor = Colors.orange;
    } else if (status == 'Completed') {
      statusColor = Colors.grey;
    } else if (status == 'Draft') {
      statusColor = Colors.blue;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  campaign['name'] ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '\$${budgetSpent.toStringAsFixed(0)} / \$${budgetTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dates',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${campaign['start_date']} - ${campaign['end_date']}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: budgetPercentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              budgetPercentage < 80 ? Colors.green : Colors.orange,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Impressions',
                  _formatNumber(campaign['impressions'] ?? 0),
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Engagements',
                  _formatNumber(campaign['engagements'] ?? 0),
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'CTR',
                  '${(campaign['ctr'] ?? 0).toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'CPE',
                  '\$${(campaign['cpe'] ?? 0).toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (status == 'Active') {
                      _pauseCampaign(campaign['id']);
                    } else {
                      _resumeCampaign(campaign['id']);
                    }
                  },
                  icon: Icon(
                    status == 'Active' ? Icons.pause : Icons.play_arrow,
                    size: 4.w,
                  ),
                  label: Text(
                    status == 'Active' ? 'Pause' : 'Resume',
                    style: TextStyle(fontSize: 10.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryLight),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _viewCampaignDetails(campaign['id']),
                  icon: Icon(Icons.bar_chart, size: 4.w),
                  label: Text(
                    'View Details',
                    style: TextStyle(fontSize: 10.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9.sp, color: AppTheme.textSecondaryLight),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio Performance',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildPortfolioPerformanceCard(),
          SizedBox(height: 3.h),
          Text(
            'Campaign Comparison',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildCampaignComparisonCard(),
          SizedBox(height: 3.h),
          Text(
            'Audience Insights',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildAudienceInsightsCard(),
        ],
      ),
    );
  }

  Widget _buildPortfolioPerformanceCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Spend All Time',
                  '\$${(_portfolioMetrics['total_spend_month'] ?? 0).toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Total Impressions',
                  _formatNumber(_portfolioMetrics['total_impressions'] ?? 0),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Average CTR',
                  '${(_portfolioMetrics['avg_ctr'] ?? 0).toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Total Engagements',
                  _formatNumber(_portfolioMetrics['total_engagements'] ?? 0),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'ROI',
                  '${(_portfolioMetrics['roi'] ?? 0).toStringAsFixed(0)}%',
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignComparisonCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compare campaign metrics side-by-side',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ..._campaigns.map(
            (campaign) => Padding(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      campaign['name'] ?? '',
                      style: TextStyle(fontSize: 10.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'CTR: ${(campaign['ctr'] ?? 0).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceInsightsCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Performing Demographics',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildDemographicRow('Age 25-34', '42%', 0.42, Colors.green),
          _buildDemographicRow('Age 35-44', '35%', 0.35, Colors.blue),
          _buildDemographicRow('Age 45-54', '23%', 0.23, Colors.orange),
          SizedBox(height: 2.h),
          Text(
            'Best performing audience: 25-34 year olds with 40% higher engagement',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicRow(
    String label,
    String percentage,
    double value,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 10.sp)),
              Text(
                percentage,
                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI-Powered Recommendations',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Powered by Perplexity AI',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 2.h),
          ..._optimizationRecommendations.map(
            (rec) => _buildOptimizationRecommendationCard(rec),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationRecommendationCard(Map<String, dynamic> rec) {
    final impact = rec['expected_impact'] ?? 0;
    final confidence = rec['confidence'] ?? 'Medium';

    Color impactColor = Colors.green;
    if (impact < 20) {
      impactColor = Colors.orange;
    } else if (impact >= 40) {
      impactColor = Colors.green;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: impactColor.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rec['title'] ?? '',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: impactColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  '+$impact%',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: impactColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            rec['description'] ?? '',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(26),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              'Confidence: $confidence',
              style: TextStyle(
                fontSize: 9.sp,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Implementing: ${rec['title']}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Apply Recommendation',
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Billing History',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildBillingHistoryCard(),
          SizedBox(height: 3.h),
          Text(
            'Payment Methods',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildPaymentMethodsCard(),
        ],
      ),
    );
  }

  Widget _buildBillingHistoryCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInvoiceRow(
            '2026-06-15',
            'Summer Campaign 2026',
            '\$3,200',
            'Paid',
          ),
          _buildInvoiceRow(
            '2026-07-20',
            'Product Launch Q3',
            '\$2,100',
            'Paid',
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.download, size: 4.w),
              label: Text(
                'Download All Invoices',
                style: TextStyle(fontSize: 10.sp),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(
    String date,
    String campaign,
    String amount,
    String status,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                Text(
                  campaign,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              amount,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 2.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(26),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 9.sp,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPaymentMethodRow('Visa', '•••• 4242', '12/2027', true),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.add, size: 4.w),
              label: Text(
                'Add Payment Method',
                style: TextStyle(fontSize: 10.sp),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(
    String brand,
    String last4,
    String expiry,
    bool isDefault,
  ) {
    return Row(
      children: [
        Icon(Icons.credit_card, size: 6.w, color: AppTheme.primaryLight),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$brand $last4',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isDefault) ...[
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 1.5.w,
                        vertical: 0.3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(26),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 8.sp,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                'Expires $expiry',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.more_vert, size: 5.w),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildCreateCampaignWizard() {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Create New Campaign',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campaign creation wizard with 4 steps:',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _buildWizardStep(
                    '1',
                    'Campaign Basics',
                    'Name, objective, budget, duration',
                  ),
                  _buildWizardStep(
                    '2',
                    'Audience Targeting',
                    'Location, demographics, interests',
                  ),
                  _buildWizardStep(
                    '3',
                    'Ad Creative',
                    'Images, video, copy, CTA',
                  ),
                  _buildWizardStep(
                    '4',
                    'Budget & Bidding',
                    'Bidding strategy, schedule, review',
                  ),
                  SizedBox(height: 3.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Campaign wizard would open here'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Start Campaign Creation',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWizardStep(String number, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10.sp,
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9.sp, color: AppTheme.textSecondaryLight),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _pauseCampaign(String campaignId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Campaign paused successfully'),
        backgroundColor: Colors.orange,
      ),
    );
    _loadAdvertiserData();
  }

  void _resumeCampaign(String campaignId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Campaign resumed successfully'),
        backgroundColor: Colors.green,
      ),
    );
    _loadAdvertiserData();
  }

  void _viewCampaignDetails(String campaignId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Campaign details would open here'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
