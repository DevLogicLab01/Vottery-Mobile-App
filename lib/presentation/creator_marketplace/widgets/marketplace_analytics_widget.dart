import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../services/marketplace_service.dart';

/// Enhanced Marketplace Analytics Widget
/// Comprehensive performance dashboard with conversion rates, buyer demographics,
/// demand forecasting, and revenue optimization recommendations
class MarketplaceAnalyticsWidget extends StatefulWidget {
  final Map<String, dynamic> analytics;

  const MarketplaceAnalyticsWidget({super.key, required this.analytics});

  @override
  State<MarketplaceAnalyticsWidget> createState() =>
      _MarketplaceAnalyticsWidgetState();
}

class _MarketplaceAnalyticsWidgetState
    extends State<MarketplaceAnalyticsWidget> {
  final MarketplaceService _marketplaceService = MarketplaceService.instance;

  bool _isLoadingEnhanced = false;
  Map<String, dynamic> _enhancedAnalytics = {};

  @override
  void initState() {
    super.initState();
    _loadEnhancedAnalytics();
  }

  Future<void> _loadEnhancedAnalytics() async {
    setState(() => _isLoadingEnhanced = true);

    try {
      final enhanced = await _marketplaceService
          .getEnhancedMarketplaceAnalytics();

      if (mounted) {
        setState(() {
          _enhancedAnalytics = enhanced;
          _isLoadingEnhanced = false;
        });
      }
    } catch (e) {
      debugPrint('Load enhanced analytics error: $e');
      if (mounted) {
        setState(() => _isLoadingEnhanced = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = widget.analytics['total_revenue'] ?? 0.0;
    final totalTransactions = widget.analytics['total_transactions'] ?? 0;
    final avgOrderValue = widget.analytics['average_order_value'] ?? 0.0;
    final conversionRate = widget.analytics['conversion_rate'] ?? 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRevenueOverview(totalRevenue, totalTransactions),
          SizedBox(height: 3.h),
          _buildMetricsGrid(avgOrderValue, conversionRate),
          SizedBox(height: 3.h),
          if (_isLoadingEnhanced)
            Center(child: CircularProgressIndicator())
          else
            ..._buildEnhancedSections(),
        ],
      ),
    );
  }

  List<Widget> _buildEnhancedSections() {
    return [
      _buildConversionRatesSection(),
      SizedBox(height: 3.h),
      _buildBuyerDemographicsSection(),
      SizedBox(height: 3.h),
      _buildDemandForecastingSection(),
      SizedBox(height: 3.h),
      _buildRevenueOptimizationSection(),
      SizedBox(height: 3.h),
      _buildCompetitiveAnalysisSection(),
    ];
  }

  Widget _buildRevenueOverview(double totalRevenue, int totalTransactions) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.primaryLight.withAlpha(179)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Marketplace Revenue',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withAlpha(204),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '\$${totalRevenue.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '$totalTransactions transactions',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(double avgOrderValue, double conversionRate) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Avg Order Value',
            '\$${avgOrderValue.toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildMetricCard(
            'Conversion Rate',
            '${conversionRate.toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.blue,
          ),
        ),
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
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConversionRatesSection() {
    final conversionMetrics =
        _enhancedAnalytics['conversion_metrics'] as List? ?? [];

    if (conversionMetrics.isEmpty) {
      return _buildEmptySection('No conversion data available');
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Conversion Rates',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          ...conversionMetrics.take(5).map((metric) {
            final serviceName =
                metric['marketplace_services']?['title'] ?? 'Unknown Service';
            final conversionRate = metric['conversion_rate'] ?? 0.0;
            final trendDirection = metric['trend_direction'] ?? 'stable';
            final trendPercentage = metric['trend_percentage'] ?? 0.0;

            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          serviceName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            trendDirection == 'up'
                                ? Icons.arrow_upward
                                : trendDirection == 'down'
                                ? Icons.arrow_downward
                                : Icons.remove,
                            color: trendDirection == 'up'
                                ? Colors.green
                                : trendDirection == 'down'
                                ? Colors.red
                                : Colors.grey,
                            size: 4.w,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${conversionRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  LinearProgressIndicator(
                    value: conversionRate / 100,
                    backgroundColor: Colors.grey.withAlpha(51),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBuyerDemographicsSection() {
    final demographics =
        _enhancedAnalytics['buyer_demographics'] as Map<String, dynamic>? ?? {};

    if (demographics.isEmpty) {
      return _buildEmptySection('No buyer demographics available');
    }

    final ageDistribution = demographics['age_distribution'] as Map? ?? {};
    final genderSplit = demographics['gender_split'] as Map? ?? {};
    final geoLocations = demographics['geographic_locations'] as Map? ?? {};

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buyer Demographics',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildDemographicChart('Age Distribution', ageDistribution),
          SizedBox(height: 2.h),
          _buildDemographicChart('Gender Split', genderSplit),
          SizedBox(height: 2.h),
          _buildDemographicChart('Top Locations', geoLocations),
        ],
      ),
    );
  }

  Widget _buildDemographicChart(String title, Map data) {
    if (data.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        ...data.entries.take(5).map((entry) {
          final percentage = (entry.value as num).toDouble();
          return Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: Row(
              children: [
                SizedBox(
                  width: 20.w,
                  child: Text(
                    entry.key,
                    style: TextStyle(fontSize: 11.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.withAlpha(51),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.accentLight,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 11.sp),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDemandForecastingSection() {
    final forecasts = _enhancedAnalytics['demand_forecasts'] as List? ?? [];

    if (forecasts.isEmpty) {
      return _buildEmptySection('No demand forecasts available');
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demand Forecasting',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          ...forecasts.take(3).map((forecast) {
            final category = forecast['service_category'] ?? 'Unknown';
            final period = forecast['forecast_period'] ?? '30_days';
            final predictedDemand = forecast['predicted_demand'] ?? 0;
            final peakPeriods = List<String>.from(
              forecast['peak_demand_periods'] ?? [],
            );

            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Predicted demand: $predictedDemand orders',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    if (peakPeriods.isNotEmpty) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        'Peak periods: ${peakPeriods.join(", ")}',
                        style: TextStyle(fontSize: 11.sp, color: Colors.blue),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRevenueOptimizationSection() {
    final recommendations =
        _enhancedAnalytics['optimization_recommendations'] as List? ?? [];

    if (recommendations.isEmpty) {
      return _buildEmptySection('No optimization recommendations available');
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.orange, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                'Revenue Optimization',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...recommendations.take(5).map((rec) {
            final recommendationType = rec['recommendation_type'] ?? '';
            final recommendationText = rec['recommendation_text'] ?? '';
            final expectedImpact = rec['expected_impact'] ?? 'medium';
            final impactPercentage = rec['impact_percentage'] ?? 0.0;

            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: _getImpactColor(expectedImpact).withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: _getImpactColor(expectedImpact).withAlpha(77),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatRecommendationType(recommendationType),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: _getImpactColor(expectedImpact),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getImpactColor(expectedImpact),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            '+${impactPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      recommendationText,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _dismissRecommendation(rec['id']),
                          child: Text('Dismiss'),
                        ),
                        SizedBox(width: 2.w),
                        ElevatedButton(
                          onPressed: () => _applyRecommendation(rec['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryLight,
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.h,
                            ),
                          ),
                          child: Text(
                            'Apply',
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompetitiveAnalysisSection() {
    final competitiveAnalysis =
        _enhancedAnalytics['competitive_analysis'] as List? ?? [];

    if (competitiveAnalysis.isEmpty) {
      return _buildEmptySection('No competitive analysis available');
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Competitive Pricing Analysis',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          ...competitiveAnalysis.take(3).map((analysis) {
            final serviceName =
                analysis['marketplace_services']?['title'] ?? 'Unknown Service';
            final creatorPrice = analysis['creator_price'] ?? 0.0;
            final marketAvgPrice = analysis['market_average_price'] ?? 0.0;
            final pricePositioning =
                analysis['price_positioning'] ?? 'at_market';
            final pricingRecommendation =
                analysis['pricing_recommendation'] ?? '';

            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Price',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppTheme.textSecondaryLight,
                              ),
                            ),
                            Text(
                              '\$${creatorPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Market Avg',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppTheme.textSecondaryLight,
                              ),
                            ),
                            Text(
                              '\$${marketAvgPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (pricingRecommendation.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Text(
                        pricingRecommendation,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.purple,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryLight),
        ),
      ),
    );
  }

  Color _getImpactColor(String impact) {
    switch (impact) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatRecommendationType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _applyRecommendation(String recommendationId) async {
    final success = await _marketplaceService.applyOptimizationRecommendation(
      recommendationId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recommendation applied successfully')),
      );
      _loadEnhancedAnalytics();
    }
  }

  Future<void> _dismissRecommendation(String recommendationId) async {
    final success = await _marketplaceService.dismissOptimizationRecommendation(
      recommendationId,
    );

    if (success && mounted) {
      _loadEnhancedAnalytics();
    }
  }
}
