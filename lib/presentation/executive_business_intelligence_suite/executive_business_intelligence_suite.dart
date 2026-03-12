import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/business_intelligence_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class ExecutiveBusinessIntelligenceSuite extends StatefulWidget {
  const ExecutiveBusinessIntelligenceSuite({super.key});

  @override
  State<ExecutiveBusinessIntelligenceSuite> createState() =>
      _ExecutiveBusinessIntelligenceSuiteState();
}

class _ExecutiveBusinessIntelligenceSuiteState
    extends State<ExecutiveBusinessIntelligenceSuite>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic> _executiveDashboard = {};
  Map<String, dynamic> _revenueAnalytics = {};
  Map<String, dynamic> _userIntelligence = {};
  Map<String, dynamic> _contentPerformance = {};
  Map<String, dynamic> _predictiveInsights = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadBusinessIntelligence();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessIntelligence() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        BusinessIntelligenceService.instance.getExecutiveDashboard(),
        BusinessIntelligenceService.instance.getRevenueAnalytics(),
        BusinessIntelligenceService.instance.getUserIntelligence(),
        BusinessIntelligenceService.instance.getContentPerformance(),
        BusinessIntelligenceService.instance.getPredictiveInsights(),
      ]);

      setState(() {
        _executiveDashboard = results[0];
        _revenueAnalytics = results[1];
        _userIntelligence = results[2];
        _contentPerformance = results[3];
        _predictiveInsights = results[4];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ExecutiveBusinessIntelligenceSuite',
      onRetry: _loadBusinessIntelligence,
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
          title: 'Business Intelligence',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadBusinessIntelligence,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKPIHeader(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRevenueAnalyticsTab(),
                          _buildUserIntelligenceTab(),
                          _buildContentPerformanceTab(),
                          _buildPredictiveInsightsTab(),
                          _buildExecutiveReportsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildKPIHeader() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildKPICard(
                'Revenue',
                '\$${(_executiveDashboard['monthly_revenue'] ?? 0.0).toStringAsFixed(0)}',
                '+${(_executiveDashboard['revenue_growth'] ?? 0.0).toStringAsFixed(1)}%',
                Colors.white,
              ),
              _buildKPICard(
                'Active Users',
                '${_executiveDashboard['active_users'] ?? 0}',
                '+${(_executiveDashboard['user_growth'] ?? 0.0).toStringAsFixed(1)}%',
                Colors.white,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildKPICard(
                'Engagement',
                '${(_executiveDashboard['engagement_rate'] ?? 0.0).toStringAsFixed(1)}%',
                'Rate',
                Colors.white,
              ),
              _buildKPICard(
                'Churn',
                '${(_executiveDashboard['churn_rate'] ?? 0.0).toStringAsFixed(1)}%',
                'Rate',
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 1.w),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: color.withAlpha(204)),
            ),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10.sp, color: color.withAlpha(179)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      height: 6.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTabChip('Revenue', 0),
          _buildTabChip('Users', 1),
          _buildTabChip('Content', 2),
          _buildTabChip('Insights', 3),
          _buildTabChip('Reports', 4),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, int index) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.animateTo(index)),
      child: Container(
        margin: EdgeInsets.only(right: 2.w),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppTheme.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Analytics',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildRevenueCard(
            'Subscription Revenue',
            _revenueAnalytics['subscription_revenue'] ?? 0.0,
            'subscriptions',
            Colors.blue,
          ),
          _buildRevenueCard(
            'Ad Revenue',
            _revenueAnalytics['ad_revenue'] ?? 0.0,
            'ads',
            Colors.green,
          ),
          _buildRevenueCard(
            'Creator Payouts',
            _revenueAnalytics['creator_payouts'] ?? 0.0,
            'payments',
            Colors.orange,
          ),
          _buildRevenueCard(
            'VP Purchases',
            _revenueAnalytics['vp_purchases'] ?? 0.0,
            'monetization_on',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(
    String label,
    double amount,
    String iconName,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              size: 8.w,
              color: color,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserIntelligenceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Intelligence',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Total Users',
            _userIntelligence['total_users']?.toString() ?? '0',
            'people',
          ),
          _buildMetricCard(
            'Active Users',
            _userIntelligence['active_users']?.toString() ?? '0',
            'person',
          ),
          _buildMetricCard(
            'Churn Prediction',
            '${(_userIntelligence['churn_prediction'] ?? 0.0).toStringAsFixed(1)}%',
            'trending_down',
          ),
          _buildMetricCard(
            'Lifetime Value',
            '\$${(_userIntelligence['lifetime_value'] ?? 0.0).toStringAsFixed(2)}',
            'attach_money',
          ),
        ],
      ),
    );
  }

  Widget _buildContentPerformanceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content Performance',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Total Content',
            _contentPerformance['total_content']?.toString() ?? '0',
            'article',
          ),
          _buildMetricCard(
            'Viral Content',
            _contentPerformance['viral_content']?.toString() ?? '0',
            'trending_up',
          ),
        ],
      ),
    );
  }

  Widget _buildPredictiveInsightsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Predictive Insights',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Growth Forecast',
            '${(_predictiveInsights['growth_forecast'] ?? 0.0).toStringAsFixed(1)}%',
            'trending_up',
          ),
          _buildMetricCard(
            'Churn Risk',
            '${(_predictiveInsights['churn_risk'] ?? 0.0).toStringAsFixed(1)}%',
            'warning',
          ),
          _buildMetricCard(
            'Revenue Forecast',
            '\$${(_predictiveInsights['revenue_forecast'] ?? 0.0).toStringAsFixed(0)}',
            'monetization_on',
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveReportsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Executive Reports',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildReportCard('Monthly Performance Report', 'monthly'),
          _buildReportCard('Quarterly Business Review', 'quarterly'),
          _buildReportCard('Annual Strategic Report', 'annual'),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String iconName) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            size: 10.w,
            color: AppTheme.primaryLight,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String reportType) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _generateReport(reportType),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            ),
            child: Text('Generate', style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(String reportType) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Generating $reportType report...')));
  }
}
