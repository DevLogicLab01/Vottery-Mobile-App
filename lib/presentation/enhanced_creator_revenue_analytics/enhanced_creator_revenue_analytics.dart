import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/enhanced_revenue_analytics_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class EnhancedCreatorRevenueAnalyticsScreen extends StatefulWidget {
  const EnhancedCreatorRevenueAnalyticsScreen({super.key});

  @override
  State<EnhancedCreatorRevenueAnalyticsScreen> createState() =>
      _EnhancedCreatorRevenueAnalyticsScreenState();
}

class _EnhancedCreatorRevenueAnalyticsScreenState
    extends State<EnhancedCreatorRevenueAnalyticsScreen> {
  final EnhancedRevenueAnalyticsService _analyticsService =
      EnhancedRevenueAnalyticsService.instance;
  final AuthService _auth = AuthService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _revenueBreakdown = {};
  List<Map<String, dynamic>> _historicalTrends = [];
  Map<String, dynamic> _taxPreview = {};
  Map<String, dynamic> _performanceMetrics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final breakdown = await _analyticsService.getRevenueBreakdown();
      final trends = await _analyticsService.getHistoricalTrends();
      final tax = await _analyticsService.getTaxLiabilityPreview();
      final metrics = await _analyticsService.getPerformanceMetrics();

      setState(() {
        _revenueBreakdown = breakdown;
        _historicalTrends = trends;
        _taxPreview = tax;
        _performanceMetrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load analytics data error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'EnhancedCreatorRevenueAnalytics',
      onRetry: _loadAnalyticsData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Revenue Analytics',
          variant: CustomAppBarVariant.withBack,
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportReport,
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: _loadAnalyticsData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRevenueBreakdownSection(theme),
                      SizedBox(height: 3.h),
                      _buildHistoricalTrendsSection(theme),
                      SizedBox(height: 3.h),
                      _buildTaxPreviewSection(theme),
                      SizedBox(height: 3.h),
                      _buildPerformanceMetricsSection(theme),
                      SizedBox(height: 3.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        ShimmerSkeletonLoader(
          child: Container(
            height: 20.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        ShimmerSkeletonLoader(
          child: Container(
            height: 30.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        ShimmerSkeletonLoader(
          child: Container(
            height: 25.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdownSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Breakdown',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        _buildRevenueSourceCard(
          theme,
          'Election Revenue',
          _revenueBreakdown['election_revenue'] ?? {},
          Icons.how_to_vote,
          AppTheme.vibrantYellow,
        ),
        SizedBox(height: 1.5.h),
        _buildRevenueSourceCard(
          theme,
          'Marketplace Revenue',
          _revenueBreakdown['marketplace_revenue'] ?? {},
          Icons.store,
          Colors.green,
        ),
        SizedBox(height: 1.5.h),
        _buildRevenueSourceCard(
          theme,
          'Ad Revenue',
          _revenueBreakdown['ad_revenue'] ?? {},
          Icons.ads_click,
          Colors.blue,
        ),
        SizedBox(height: 1.5.h),
        _buildRevenueSourceCard(
          theme,
          'Referral Revenue',
          _revenueBreakdown['referral_revenue'] ?? {},
          Icons.people,
          Colors.purple,
        ),
        SizedBox(height: 2.h),
        _buildPieChart(theme),
      ],
    );
  }

  Widget _buildRevenueSourceCard(
    ThemeData theme,
    String title,
    Map<String, dynamic> data,
    IconData icon,
    Color color,
  ) {
    final total = (data['total'] ?? 0.0) as double;
    final percentage = data['percentage'] ?? '0';
    final trend = data['trend'] ?? 'stable';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 6.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percentage%',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  Icon(
                    trend == 'up'
                        ? Icons.trending_up
                        : trend == 'down'
                        ? Icons.trending_down
                        : Icons.trending_flat,
                    color: trend == 'up'
                        ? Colors.green
                        : trend == 'down'
                        ? Colors.red
                        : Colors.grey,
                    size: 4.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    trend,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildPieChart(ThemeData theme) {
    final electionRevenue =
        (_revenueBreakdown['election_revenue']?['total'] ?? 0.0) as double;
    final marketplaceRevenue =
        (_revenueBreakdown['marketplace_revenue']?['total'] ?? 0.0) as double;
    final adRevenue =
        (_revenueBreakdown['ad_revenue']?['total'] ?? 0.0) as double;
    final referralRevenue =
        (_revenueBreakdown['referral_revenue']?['total'] ?? 0.0) as double;

    final total =
        electionRevenue + marketplaceRevenue + adRevenue + referralRevenue;

    if (total == 0) {
      return Container(
        height: 25.h,
        alignment: Alignment.center,
        child: Text(
          'No revenue data available',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      height: 25.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: electionRevenue,
              title: '${(electionRevenue / total * 100).toStringAsFixed(0)}%',
              color: AppTheme.vibrantYellow,
              radius: 50,
            ),
            PieChartSectionData(
              value: marketplaceRevenue,
              title:
                  '${(marketplaceRevenue / total * 100).toStringAsFixed(0)}%',
              color: Colors.green,
              radius: 50,
            ),
            PieChartSectionData(
              value: adRevenue,
              title: '${(adRevenue / total * 100).toStringAsFixed(0)}%',
              color: Colors.blue,
              radius: 50,
            ),
            PieChartSectionData(
              value: referralRevenue,
              title: '${(referralRevenue / total * 100).toStringAsFixed(0)}%',
              color: Colors.purple,
              radius: 50,
            ),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildHistoricalTrendsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historical Trends (12 Months)',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          height: 30.h,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: _historicalTrends.isEmpty
              ? Center(
                  child: Text(
                    'No historical data available',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '\$${value.toInt()}',
                              style: GoogleFonts.inter(fontSize: 9.sp),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < _historicalTrends.length) {
                              final month =
                                  _historicalTrends[value.toInt()]['month']
                                      as String;
                              return Text(
                                month.split('-')[1],
                                style: GoogleFonts.inter(fontSize: 9.sp),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _historicalTrends
                            .asMap()
                            .entries
                            .map(
                              (e) => FlSpot(
                                e.key.toDouble(),
                                (e.value['total_revenue'] as num).toDouble(),
                              ),
                            )
                            .toList(),
                        isCurved: true,
                        color: AppTheme.vibrantYellow,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTaxPreviewSection(ThemeData theme) {
    final grossEarnings = (_taxPreview['gross_earnings'] ?? 0.0) as double;
    final totalDeductions = (_taxPreview['total_deductions'] ?? 0.0) as double;
    final netTaxableIncome =
        (_taxPreview['net_taxable_income'] ?? 0.0) as double;
    final estimatedTotalTax =
        (_taxPreview['estimated_total_tax'] ?? 0.0) as double;
    final quarterlyEstimates = _taxPreview['quarterly_estimates'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tax Liability Preview',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            children: [
              _buildTaxRow(
                theme,
                'Gross Earnings',
                '\$${grossEarnings.toStringAsFixed(2)}',
              ),
              Divider(height: 2.h),
              _buildTaxRow(
                theme,
                'Deductible Expenses',
                '-\$${totalDeductions.toStringAsFixed(2)}',
              ),
              Divider(height: 2.h),
              _buildTaxRow(
                theme,
                'Net Taxable Income',
                '\$${netTaxableIncome.toStringAsFixed(2)}',
                isBold: true,
              ),
              Divider(height: 2.h),
              _buildTaxRow(
                theme,
                'Estimated Total Tax',
                '\$${estimatedTotalTax.toStringAsFixed(2)}',
                color: Colors.red,
                isBold: true,
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Quarterly Estimates',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        ...List.generate((quarterlyEstimates as List).length, (index) {
          final estimate = quarterlyEstimates[index];
          return Container(
            margin: EdgeInsets.only(bottom: 1.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  estimate['quarter'],
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '\$${(estimate['amount'] as num).toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Due: ${estimate['due_date']}',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTaxRow(
    ThemeData theme,
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetricsSection(ThemeData theme) {
    final revenuePerFollower =
        (_performanceMetrics['revenue_per_follower'] ?? 0.0) as double;
    final avgTransactionValue =
        (_performanceMetrics['average_transaction_value'] ?? 0.0) as double;
    final customerLifetimeValue =
        (_performanceMetrics['customer_lifetime_value'] ?? 0.0) as double;
    final annualProjection =
        (_performanceMetrics['annual_projection'] ?? 0.0) as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                'Revenue/Follower',
                '\$${revenuePerFollower.toStringAsFixed(2)}',
                Icons.person,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Avg Transaction',
                '\$${avgTransactionValue.toStringAsFixed(2)}',
                Icons.attach_money,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                'Customer LTV',
                '\$${customerLifetimeValue.toStringAsFixed(2)}',
                Icons.trending_up,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Annual Projection',
                '\$${annualProjection.toStringAsFixed(0)}',
                Icons.calendar_today,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.vibrantYellow, size: 6.w),
          SizedBox(height: 1.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport() async {
    try {
      final csv = await _analyticsService.exportRevenueReport();
      if (csv.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report exported successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to export report')));
    }
  }
}
