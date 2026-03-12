import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/ga4_analytics_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/alert_monitoring_widget.dart';
import './widgets/earnings_funnel_widget.dart';
import './widgets/kyc_analytics_widget.dart';
import './widgets/monetization_dashboard_widget.dart';
import './widgets/revenue_attribution_widget.dart';
import './widgets/settlement_metrics_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class GoogleAnalyticsMonetizationTrackingHub extends StatefulWidget {
  const GoogleAnalyticsMonetizationTrackingHub({super.key});

  @override
  State<GoogleAnalyticsMonetizationTrackingHub> createState() =>
      _GoogleAnalyticsMonetizationTrackingHubState();
}

class _GoogleAnalyticsMonetizationTrackingHubState
    extends State<GoogleAnalyticsMonetizationTrackingHub>
    with SingleTickerProviderStateMixin {
  final GA4AnalyticsService _analyticsService = GA4AnalyticsService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _overviewMetrics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadOverviewMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOverviewMetrics() async {
    setState(() => _isLoading = true);

    // Mock overview metrics - in production, fetch from analytics backend
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _overviewMetrics = {
        'total_revenue': 125430.50,
        'active_creators': 1247,
        'avg_payout': 450.25,
        'settlement_success_rate': 0.967,
        'kyc_completion_rate': 0.823,
        'withdrawal_conversion': 0.745,
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'GoogleAnalyticsMonetizationTrackingHub',
      onRetry: _loadOverviewMetrics,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'GA4 Monetization Tracking',
          variant: CustomAppBarVariant.withBack,
        ),
        drawer: _buildNavigationDrawer(),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildOverviewHeader(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: const [
                          EarningsFunnelWidget(),
                          KycAnalyticsWidget(),
                          SettlementMetricsWidget(),
                          RevenueAttributionWidget(),
                          MonetizationDashboardWidget(),
                          AlertMonitoringWidget(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.accentLight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.analytics, size: 40, color: Colors.white),
                SizedBox(height: 1.h),
                Text(
                  'Analytics Hub',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Overview'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: const Text('Earnings Funnel'),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('KYC Analytics'),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Settlement Metrics'),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Revenue Attribution'),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(3);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewHeader() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentLight, AppTheme.accentLight.withAlpha(204)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Monetization Overview',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard(
                'Total Revenue',
                '\$${(_overviewMetrics['total_revenue'] ?? 0).toStringAsFixed(0)}',
                Icons.attach_money,
              ),
              _buildMetricCard(
                'Active Creators',
                '${_overviewMetrics['active_creators'] ?? 0}',
                Icons.people,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard(
                'Avg Payout',
                '\$${(_overviewMetrics['avg_payout'] ?? 0).toStringAsFixed(0)}',
                Icons.payment,
              ),
              _buildMetricCard(
                'Success Rate',
                '${((_overviewMetrics['settlement_success_rate'] ?? 0) * 100).toStringAsFixed(1)}%',
                Icons.check_circle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      width: 42.w,
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.grey[100],
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.accentLight,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.accentLight,
        labelStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Funnel'),
          Tab(text: 'KYC'),
          Tab(text: 'Settlement'),
          Tab(text: 'Revenue'),
          Tab(text: 'Dashboard'),
          Tab(text: 'Alerts'),
        ],
      ),
    );
  }
}
