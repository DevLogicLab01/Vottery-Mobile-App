import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/ga4_analytics_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/creator_earnings_funnel_widget.dart';
import './widgets/custom_dimensions_widget.dart';
import './widgets/event_configuration_widget.dart';
import './widgets/kyc_completion_tracking_widget.dart';
import './widgets/real_time_event_monitor_widget.dart';
import './widgets/revenue_attribution_tracking_widget.dart';
import './widgets/settlement_success_metrics_widget.dart';
import './widgets/tracking_status_overview_widget.dart';

class AdvancedGoogleAnalyticsTrackingHub extends StatefulWidget {
  const AdvancedGoogleAnalyticsTrackingHub({super.key});

  @override
  State<AdvancedGoogleAnalyticsTrackingHub> createState() =>
      _AdvancedGoogleAnalyticsTrackingHubState();
}

class _AdvancedGoogleAnalyticsTrackingHubState
    extends State<AdvancedGoogleAnalyticsTrackingHub>
    with SingleTickerProviderStateMixin {
  final GA4AnalyticsService _analyticsService = GA4AnalyticsService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _trackingStatus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadTrackingStatus();
    _analyticsService.trackScreenView(
      screenName: 'Advanced Google Analytics Tracking Hub',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrackingStatus() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _trackingStatus = {
        'active_events': 47,
        'data_quality_score': 94.5,
        'events_today': 12847,
        'real_time_active': true,
        'last_sync': DateTime.now().subtract(const Duration(minutes: 2)),
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AdvancedGoogleAnalyticsTrackingHub',
      onRetry: _loadTrackingStatus,
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
          title: 'Advanced GA4 Tracking',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadTrackingStatus,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        drawer: _buildNavigationDrawer(),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  TrackingStatusOverviewWidget(
                    activeEvents: _trackingStatus['active_events'] ?? 0,
                    dataQualityScore:
                        _trackingStatus['data_quality_score'] ?? 0.0,
                    eventsToday: _trackingStatus['events_today'] ?? 0,
                    realTimeActive:
                        _trackingStatus['real_time_active'] ?? false,
                  ),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        CreatorEarningsFunnelWidget(),
                        KycCompletionTrackingWidget(),
                        SettlementSuccessMetricsWidget(),
                        RevenueAttributionTrackingWidget(),
                        CustomDimensionsWidget(),
                        EventConfigurationWidget(),
                        RealTimeEventMonitorWidget(),
                      ],
                    ),
                  ),
                ],
              ),
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
        labelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Earnings Funnel'),
          Tab(text: 'KYC Tracking'),
          Tab(text: 'Settlement'),
          Tab(text: 'Revenue Attribution'),
          Tab(text: 'Custom Dimensions'),
          Tab(text: 'Configuration'),
          Tab(text: 'Real-Time Monitor'),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primaryLight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomIconWidget(
                  iconName: 'analytics',
                  size: 12.w,
                  color: Colors.white,
                ),
                SizedBox(height: 2.h),
                Text(
                  'GA4 Analytics Admin',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'dashboard',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
            title: Text('Overview', style: TextStyle(fontSize: 12.sp)),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(0);
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'settings',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
            title: Text(
              'Event Configuration',
              style: TextStyle(fontSize: 12.sp),
            ),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(5);
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'monitor_heart',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
            title: Text('Real-Time Monitor', style: TextStyle(fontSize: 12.sp)),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(6);
            },
          ),
        ],
      ),
    );
  }
}
