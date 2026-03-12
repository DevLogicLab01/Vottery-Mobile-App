import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/advertiser_analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/brand_partnership_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/conversion_funnel_widget.dart';
import './widgets/performance_metrics_card_widget.dart';
import './widgets/roi_comparison_card_widget.dart';
import './widgets/zone_reach_chart_widget.dart';

class AdvertiserAnalyticsDashboard extends StatefulWidget {
  const AdvertiserAnalyticsDashboard({super.key});

  @override
  State<AdvertiserAnalyticsDashboard> createState() =>
      _AdvertiserAnalyticsDashboardState();
}

class _AdvertiserAnalyticsDashboardState
    extends State<AdvertiserAnalyticsDashboard> {
  final AdvertiserAnalyticsService _analyticsService =
      AdvertiserAnalyticsService.instance;
  final BrandPartnershipService _partnershipService =
      BrandPartnershipService.instance;

  bool _isLoading = true;
  String? _selectedCampaignId;
  List<Map<String, dynamic>> _campaigns = [];
  Map<String, dynamic> _analytics = {};
  Map<String, int> _zoneReach = {};
  Map<String, int> _zoneConversions = {};
  final List<Map<String, dynamic>> _campaignComparison = [];
  Map<String, int> _countryReach = {};

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _isLoading = true);

    try {
      final advertiserId = AuthService.instance.currentUser?.id ?? '';
      final campaigns = await _analyticsService.getVotteryAdsCampaigns(
        advertiserId: advertiserId,
      );

      setState(() {
        _campaigns = campaigns;
        if (_campaigns.isNotEmpty) {
          _selectedCampaignId = _campaigns.first['id'] as String?;
        }
      });

      if (_selectedCampaignId != null) {
        await _loadAnalytics(_selectedCampaignId!);
      }
    } catch (e) {
      debugPrint('Load campaigns error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnalytics(String campaignId) async {
    try {
      final advertiserId = AuthService.instance.currentUser?.id ?? '';
      final results = await Future.wait([
        _analyticsService.getVotteryAdsCampaignPerformance(
          advertiserId: advertiserId,
          timeRange: '30d',
        ),
        _analyticsService.getVotteryReachByZone(
          advertiserId: advertiserId,
          timeRange: '30d',
        ),
        _analyticsService.getVotteryReachByCountry(
          advertiserId: advertiserId,
          timeRange: '30d',
        ),
      ]);

      setState(() {
        _analytics = results[0];
        _zoneReach = results[1] as Map<String, int>;
        _countryReach = results[2] as Map<String, int>;
      });
    } catch (e) {
      debugPrint('Load analytics error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AdvertiserAnalyticsDashboard',
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
          title: 'Advertiser Analytics',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () {
                if (_selectedCampaignId != null) {
                  _loadAnalytics(_selectedCampaignId!);
                }
              },
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _campaigns.isEmpty
            ? NoDataEmptyState(
                title: 'No Campaign Data',
                description:
                    'Create your first campaign to see analytics and performance metrics.',
                onRefresh: _loadCampaigns,
              )
            : RefreshIndicator(
                onRefresh: _loadCampaigns,
                color: AppTheme.primaryLight,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCampaignSelector(),
                      SizedBox(height: 3.h),
                      _buildPerformanceMetrics(),
                      SizedBox(height: 3.h),
                      _buildConversionFunnel(),
                      SizedBox(height: 3.h),
                      _buildZoneReachChart(),
                      SizedBox(height: 3.h),
                      _buildCountryReachCard(),
                      SizedBox(height: 3.h),
                      _buildROIComparison(),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'analytics',
            size: 20.w,
            color: AppTheme.textSecondaryLight,
          ),
          SizedBox(height: 2.h),
          Text(
            'No Campaigns Yet',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Create your first campaign to see analytics',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Campaign',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedCampaignId,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.5.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: AppTheme.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: AppTheme.borderLight),
              ),
            ),
            items: _campaigns.map((campaign) {
              return DropdownMenuItem<String>(
                value: campaign['id'] as String,
                child: Text(
                  campaign['campaign_name'] ?? 'Unnamed Campaign',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCampaignId = value);
                _loadAnalytics(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return PerformanceMetricsCardWidget(
      totalImpressions: _analytics['total_impressions'] ?? 0,
      totalClicks: _analytics['total_clicks'] ?? 0,
      totalParticipants: _analytics['total_participants'] ?? 0,
      costPerParticipant: (_analytics['cost_per_participant'] ?? 0.0) as num,
      conversionRate: (_analytics['conversion_rate'] ?? 0.0) as num,
      engagementRate: (_analytics['engagement_rate'] ?? 0.0) as num,
      roiPercentage: (_analytics['roi_percentage'] ?? 0.0) as num,
    );
  }

  Widget _buildConversionFunnel() {
    return ConversionFunnelWidget(
      impressions: _analytics['total_impressions'] ?? 0,
      clicks: _analytics['total_clicks'] ?? 0,
      participants: _analytics['total_participants'] ?? 0,
    );
  }

  Widget _buildZoneReachChart() {
    return ZoneReachChartWidget(
      zoneReach: _zoneReach,
      zoneConversions: _zoneConversions,
    );
  }

  Widget _buildCountryReachCard() {
    if (_countryReach.isEmpty) return const SizedBox.shrink();
    final entries = _countryReach.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reach by Country',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.5.h),
          ...entries.take(10).map((e) {
            return Padding(
              padding: EdgeInsets.only(bottom: 0.8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: GoogleFonts.inter(fontSize: 11.sp)),
                  Text('${e.value}',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildROIComparison() {
    return ROIComparisonCardWidget(campaigns: _campaignComparison);
  }
}
