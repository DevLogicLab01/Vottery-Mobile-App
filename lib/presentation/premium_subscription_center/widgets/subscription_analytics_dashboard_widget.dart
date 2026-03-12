import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/enhanced_subscription_service.dart';
import '../../../widgets/shimmer_skeleton_loader.dart';

/// Subscription Analytics Dashboard Widget
/// Displays MRR tracking, churn analysis, LTV cohort analysis, and revenue forecasting
class SubscriptionAnalyticsDashboardWidget extends StatefulWidget {
  const SubscriptionAnalyticsDashboardWidget({super.key});

  @override
  State<SubscriptionAnalyticsDashboardWidget> createState() =>
      _SubscriptionAnalyticsDashboardWidgetState();
}

class _SubscriptionAnalyticsDashboardWidgetState
    extends State<SubscriptionAnalyticsDashboardWidget> {
  final EnhancedSubscriptionService _subscriptionService =
      EnhancedSubscriptionService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  String _selectedTab = 'mrr';

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _subscriptionService.getSubscriptionAnalytics();
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading subscription analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SkeletonDashboard();
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 2.h),
          _buildTabSelector(),
          SizedBox(height: 2.h),
          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CustomIconWidget(
          iconName: 'analytics',
          size: 7.w,
          color: AppTheme.primaryLight,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subscription Analytics',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                'MRR, Churn, LTV & Revenue Forecasting',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: AppTheme.primaryLight),
          onPressed: _loadAnalyticsData,
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTab('mrr', 'MRR Tracking', Icons.trending_up),
          _buildTab('churn', 'Churn Analysis', Icons.person_remove),
          _buildTab('ltv', 'LTV Cohorts', Icons.groups),
          _buildTab('forecast', 'Revenue Forecast', Icons.insights),
        ],
      ),
    );
  }

  Widget _buildTab(String tabId, String label, IconData icon) {
    final isSelected = _selectedTab == tabId;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabId),
      child: Container(
        margin: EdgeInsets.only(right: 2.w),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondaryLight,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'mrr':
        return _buildMRRTrackingTab();
      case 'churn':
        return _buildChurnAnalysisTab();
      case 'ltv':
        return _buildLTVCohortsTab();
      case 'forecast':
        return _buildRevenueForecastTab();
      default:
        return Container();
    }
  }

  Widget _buildMRRTrackingTab() {
    final mrrData = _analyticsData['mrr_tracking'] as List? ?? [];
    final latestMRR = mrrData.isNotEmpty ? mrrData.last : {};

    return Column(
      children: [
        // MRR Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total MRR',
                '\$${latestMRR['total_mrr'] ?? 0}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildMetricCard(
                'Active Subs',
                '${latestMRR['active_subscriptions'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'ARPU',
                '\$${latestMRR['average_revenue_per_user'] ?? 0}',
                Icons.person,
                Colors.purple,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildMetricCard(
                'Net New MRR',
                '\$${latestMRR['net_new_mrr'] ?? 0}',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        // MRR Chart
        _buildMRRChart(mrrData),
        SizedBox(height: 3.h),
        // MRR Breakdown
        _buildMRRBreakdown(latestMRR),
      ],
    );
  }

  Widget _buildChurnAnalysisTab() {
    final churnData = _analyticsData['churn_analysis'] as List? ?? [];
    final latestChurn = churnData.isNotEmpty ? churnData.last : {};

    return Column(
      children: [
        // Churn Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Churn Rate',
                '${latestChurn['churn_rate'] ?? 0}%',
                Icons.trending_down,
                Colors.red,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildMetricCard(
                'Retention Rate',
                '${latestChurn['retention_rate'] ?? 0}%',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Churned Users',
                '${latestChurn['total_churned_users'] ?? 0}',
                Icons.person_remove,
                Colors.orange,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildMetricCard(
                'Churned Revenue',
                '\$${latestChurn['churned_revenue'] ?? 0}',
                Icons.money_off,
                Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        // Churn Chart
        _buildChurnChart(churnData),
        SizedBox(height: 3.h),
        // Churn Reasons
        _buildChurnReasons(latestChurn),
      ],
    );
  }

  Widget _buildLTVCohortsTab() {
    final ltvData = _analyticsData['ltv_cohorts'] as List? ?? [];

    return Column(
      children: [
        Text(
          'Lifetime Value by Cohort',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        ...ltvData.map((cohort) => _buildLTVCohortCard(cohort)),
      ],
    );
  }

  Widget _buildRevenueForecastTab() {
    final forecastData = _analyticsData['revenue_forecasts'] as List? ?? [];

    return Column(
      children: [
        Text(
          'Revenue Forecasting',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        _buildForecastChart(forecastData),
        SizedBox(height: 3.h),
        ...forecastData.map((forecast) => _buildForecastCard(forecast)),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 7.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMRRChart(List mrrData) {
    if (mrrData.isEmpty) {
      return SizedBox(
        height: 30.h,
        child: Center(child: Text('No MRR data available')),
      );
    }

    return Container(
      height: 30.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: mrrData
                  .asMap()
                  .entries
                  .map(
                    (e) => FlSpot(
                      e.key.toDouble(),
                      (e.value['total_mrr'] ?? 0).toDouble(),
                    ),
                  )
                  .toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChurnChart(List churnData) {
    if (churnData.isEmpty) {
      return SizedBox(
        height: 30.h,
        child: Center(child: Text('No churn data available')),
      );
    }

    return Container(
      height: 30.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: churnData
                  .asMap()
                  .entries
                  .map(
                    (e) => FlSpot(
                      e.key.toDouble(),
                      (e.value['churn_rate'] ?? 0).toDouble(),
                    ),
                  )
                  .toList(),
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastChart(List forecastData) {
    if (forecastData.isEmpty) {
      return SizedBox(
        height: 30.h,
        child: Center(child: Text('No forecast data available')),
      );
    }

    return Container(
      height: 30.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: forecastData
                  .asMap()
                  .entries
                  .map(
                    (e) => FlSpot(
                      e.key.toDouble(),
                      (e.value['predicted_mrr'] ?? 0).toDouble(),
                    ),
                  )
                  .toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMRRBreakdown(Map<String, dynamic> mrrData) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MRR Breakdown',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildBreakdownRow('New MRR', mrrData['new_mrr'] ?? 0, Colors.green),
          _buildBreakdownRow(
            'Expansion MRR',
            mrrData['expansion_mrr'] ?? 0,
            Colors.blue,
          ),
          _buildBreakdownRow(
            'Contraction MRR',
            mrrData['contraction_mrr'] ?? 0,
            Colors.orange,
          ),
          _buildBreakdownRow(
            'Churned MRR',
            mrrData['churned_mrr'] ?? 0,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, dynamic value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3.w,
                height: 3.w,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 2.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          Text(
            '\$$value',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChurnReasons(Map<String, dynamic> churnData) {
    final reasons = churnData['churn_reasons'] as Map? ?? {};

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Churn Reasons',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (reasons.isEmpty)
            Text('No churn reasons available')
          else
            ...reasons.entries.map(
              (entry) => Padding(
                padding: EdgeInsets.symmetric(vertical: 0.5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(entry.key), Text('${entry.value}%')],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLTVCohortCard(Map<String, dynamic> cohort) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${cohort['tier']} - ${cohort['cohort_month']}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                'Cohort Size: ${cohort['cohort_size']}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Average LTV: \$${cohort['average_ltv'] ?? 0}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Retention: M1: ${cohort['retention_month_1']}% | M3: ${cohort['retention_month_3']}% | M6: ${cohort['retention_month_6']}% | M12: ${cohort['retention_month_12']}%',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> forecast) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                forecast['forecast_month'] ?? '',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Confidence: ${forecast['confidence_level']}%',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Predicted MRR: \$${forecast['predicted_mrr'] ?? 0}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          if (forecast['actual_mrr'] != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              'Actual MRR: \$${forecast['actual_mrr']}',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            Text(
              'Accuracy: ${forecast['forecast_accuracy']}%',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
