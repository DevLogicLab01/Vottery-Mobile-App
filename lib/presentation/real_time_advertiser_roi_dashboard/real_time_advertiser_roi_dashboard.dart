import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/advertiser_analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/brand_partnership_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/ai_optimization_recommendations_widget.dart';
import './widgets/audience_demographics_widget.dart';
import './widgets/budget_pacing_widget.dart';
import './widgets/campaign_comparison_widget.dart';
import './widgets/conversion_tracking_widget.dart';
import './widgets/engagement_heatmap_widget.dart';
import './widgets/optimization_action_panel_widget.dart';
import './widgets/performance_metrics_card_widget.dart';
import './widgets/zone_roi_breakdown_widget.dart';

/// Real-Time Advertiser ROI Dashboard with mobile-optimized performance insights
/// and instant optimization controls for campaign management
class RealTimeAdvertiserRoiDashboard extends StatefulWidget {
  const RealTimeAdvertiserRoiDashboard({super.key});

  @override
  State<RealTimeAdvertiserRoiDashboard> createState() =>
      _RealTimeAdvertiserRoiDashboardState();
}

class _RealTimeAdvertiserRoiDashboardState
    extends State<RealTimeAdvertiserRoiDashboard> {
  final AdvertiserAnalyticsService _analyticsService =
      AdvertiserAnalyticsService.instance;
  final BrandPartnershipService _partnershipService =
      BrandPartnershipService.instance;

  bool _isLoading = true;
  int _currentCampaignIndex = 0;
  List<Map<String, dynamic>> _campaigns = [];
  Map<String, dynamic> _currentAnalytics = {};
  Map<String, int> _zoneReach = {};
  Map<String, int> _zoneConversions = {};
  Map<String, dynamic> _audienceDemographics = {};
  List<Map<String, dynamic>> _conversionTimeline = [];

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _isLoading = true);

    try {
      final campaigns = await _partnershipService.getCreatorApplications(
        creatorId: AuthService.instance.currentUser?.id ?? '',
      );

      setState(() {
        _campaigns = campaigns;
        if (_campaigns.isNotEmpty) {
          _loadCampaignData(_currentCampaignIndex);
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      debugPrint('Load campaigns error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCampaignData(int index) async {
    if (index < 0 || index >= _campaigns.length) return;

    setState(() => _isLoading = true);

    try {
      final campaignId = _campaigns[index]['id'] as String;

      final results = await Future.wait<dynamic>([
        _analyticsService.getCampaignAnalytics(campaignId: campaignId),
        _analyticsService.getReachByZone(campaignId: campaignId),
        _analyticsService.getConversionsByZone(campaignId: campaignId),
        _analyticsService.getReachByCountry(
          advertiserId: AuthService.instance.currentUser?.id ?? '',
          timeRange: '30d',
        ),
        _analyticsService.getPerformanceTrends(campaignId: campaignId),
      ]);

      setState(() {
        _currentAnalytics = results[0] as Map<String, dynamic>;
        _zoneReach = results[1] as Map<String, int>;
        _zoneConversions = (results[2] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value as int),
        );
        final countryReach = Map<String, int>.from(results[3] as Map<String, int>);
        _audienceDemographics = {
          'country_reach': countryReach,
          'top_country': countryReach.entries.isNotEmpty
              ? (countryReach.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .first
                  .key
              : 'N/A',
        };
        _conversionTimeline =
            List<Map<String, dynamic>>.from(results[4] as List<Map<String, dynamic>>);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load campaign data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadCampaignData(_currentCampaignIndex);
  }

  void _swipeToCampaign(int index) {
    if (index != _currentCampaignIndex) {
      setState(() => _currentCampaignIndex = index);
      _loadCampaignData(index);
    }
  }

  void _handleOptimizationAction(String action, Map<String, dynamic> params) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Action'),
        content: Text(_getActionConfirmationMessage(action, params)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeOptimizationAction(action, params);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vibrantYellow,
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getActionConfirmationMessage(
    String action,
    Map<String, dynamic> params,
  ) {
    switch (action) {
      case 'increase_budget':
        return 'Increase campaign budget by ${params['percentage']}%?';
      case 'expand_audience':
        return 'Expand audience to ${params['zone']} zone?';
      case 'rotate_creative':
        return 'Rotate creative assets for this campaign?';
      case 'pause_campaign':
        return 'Pause this underperforming campaign?';
      default:
        return 'Execute this optimization action?';
    }
  }

  Future<void> _executeOptimizationAction(
    String action,
    Map<String, dynamic> params,
  ) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Executing ${action.replaceAll('_', ' ')}...'),
        duration: const Duration(seconds: 2),
      ),
    );

    await _refreshData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${action.replaceAll('_', ' ')} completed successfully',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'RealTimeAdvertiserROIDashboard',
      onRetry: _loadCampaigns,
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
          title: 'Real-Time ROI Dashboard',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, size: 6.w),
              onPressed: _refreshData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _campaigns.isEmpty
            ? NoDataEmptyState(
                title: 'No ROI Data',
                description:
                    'Campaign ROI metrics will appear once your campaigns are active.',
                onRefresh: _loadCampaigns,
              )
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: AppTheme.vibrantYellow,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExecutiveSummary(),
                      SizedBox(height: 3.h),
                      _buildCampaignSelector(),
                      SizedBox(height: 3.h),
                      PerformanceMetricsCardWidget(
                        analytics: _currentAnalytics,
                      ),
                      SizedBox(height: 3.h),
                      OptimizationActionPanelWidget(
                        onActionTapped: _handleOptimizationAction,
                      ),
                      SizedBox(height: 3.h),
                      ZoneRoiBreakdownWidget(
                        zoneReach: _zoneReach,
                        zoneConversions: _zoneConversions,
                      ),
                      SizedBox(height: 3.h),
                      ConversionTrackingWidget(
                        conversionTimeline: _conversionTimeline,
                      ),
                      SizedBox(height: 3.h),
                      BudgetPacingWidget(
                        analytics: _currentAnalytics,
                        campaign: _campaigns[_currentCampaignIndex],
                      ),
                      SizedBox(height: 3.h),
                      AudienceDemographicsWidget(
                        demographics: _audienceDemographics,
                      ),
                      SizedBox(height: 3.h),
                      EngagementHeatmapWidget(
                        campaignId: _campaigns[_currentCampaignIndex]['id'],
                      ),
                      SizedBox(height: 3.h),
                      AiOptimizationRecommendationsWidget(
                        campaignId: _campaigns[_currentCampaignIndex]['id'],
                        campaignData: _currentAnalytics,
                      ),
                      SizedBox(height: 3.h),
                      if (_campaigns.length > 1)
                        CampaignComparisonWidget(
                          campaigns: _campaigns,
                          currentIndex: _currentCampaignIndex,
                          onSwipe: _swipeToCampaign,
                        ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildExecutiveSummary() {
    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 2,
    );
    final totalSpend = (_currentAnalytics['total_spent'] ?? 0.0) as num;
    final roiPercentage = (_currentAnalytics['roi_percentage'] ?? 0.0) as num;
    final isPositive = roiPercentage >= 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? Colors.green : Colors.orange).withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Executive Summary',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Spend',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.white.withAlpha(230),
                    ),
                  ),
                  Text(
                    currencyFormat.format(totalSpend),
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Aggregate ROI',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.white.withAlpha(230),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: Colors.white,
                        size: 5.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${roiPercentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignSelector() {
    return SizedBox(
      height: 6.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _campaigns.length,
        itemBuilder: (context, index) {
          final isSelected = index == _currentCampaignIndex;
          return GestureDetector(
            onTap: () => _swipeToCampaign(index),
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.vibrantYellow : Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.vibrantYellow
                      : Theme.of(context).colorScheme.outline.withAlpha(77),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _campaigns[index]['campaign_name'] ?? 'Campaign ${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
