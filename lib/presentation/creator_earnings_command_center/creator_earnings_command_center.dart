import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/creator_earnings_service.dart';
import '../../services/creator_monetization_service.dart';
import '../../services/stripe_connect_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/earnings_visualization_widget.dart';
import './widgets/monetization_milestones_widget.dart';
import './widgets/payment_alerts_panel_widget.dart';
import './widgets/revenue_forecast_widget.dart';
import './widgets/stripe_integration_panel_widget.dart';
import './widgets/tier_progression_tracker_widget.dart';
import './widgets/unified_revenue_dashboard_widget.dart';

class CreatorEarningsCommandCenter extends StatefulWidget {
  const CreatorEarningsCommandCenter({super.key});

  @override
  State<CreatorEarningsCommandCenter> createState() =>
      _CreatorEarningsCommandCenterState();
}

class _CreatorEarningsCommandCenterState
    extends State<CreatorEarningsCommandCenter>
    with TickerProviderStateMixin {
  final CreatorEarningsService _earningsService =
      CreatorEarningsService.instance;
  final CreatorMonetizationService _monetizationService =
      CreatorMonetizationService.instance;
  final StripeConnectService _stripeService = StripeConnectService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _earningsSummary = {};
  Map<String, dynamic> _tierData = {};
  List<Map<String, dynamic>> _milestones = [];
  Map<String, dynamic> _stripeStatus = {};
  List<Map<String, dynamic>> _revenueBreakdown = [];
  Map<String, dynamic> _forecast = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _earningsService.getEarningsSummary(),
        _monetizationService.getCreatorTier(),
        _monetizationService.getMilestones(),
        _stripeService.getConnectAccountStatus(),
        _earningsService.getRevenueBreakdown(),
        _earningsService.getRevenueForecast(),
      ]);

      if (mounted) {
        setState(() {
          _earningsSummary = results[0] as Map<String, dynamic>;
          _tierData = results[1] as Map<String, dynamic>;
          _milestones = results[2] as List<Map<String, dynamic>>;
          _stripeStatus = results[3] as Map<String, dynamic>;
          _revenueBreakdown = results[4] as List<Map<String, dynamic>>;
          _forecast = results[5] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading creator earnings data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'Creator Earnings Command Center',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Creator Earnings Command Center',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Refresh Data',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportEarningsReport,
              tooltip: 'Export Report',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
              Tab(
                text: 'Revenue Streams',
                icon: Icon(Icons.attach_money, size: 20),
              ),
              Tab(
                text: 'Tier Progress',
                icon: Icon(Icons.trending_up, size: 20),
              ),
              Tab(text: 'Milestones', icon: Icon(Icons.emoji_events, size: 20)),
              Tab(
                text: 'Payment Alerts',
                icon: Icon(Icons.notifications_outlined, size: 20),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? _buildLoadingSkeleton()
            : RefreshIndicator(
                onRefresh: _loadData,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildRevenueStreamsTab(),
                    _buildTierProgressTab(),
                    _buildMilestonesTab(),
                    const PaymentAlertsPanelWidget(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        ShimmerSkeletonLoader(
          child: Container(
            height: 20.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        ShimmerSkeletonLoader(
          child: Container(
            height: 15.h,
            width: double.infinity,
            decoration: BoxDecoration(
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
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        _buildEarningsOverviewHeader(),
        SizedBox(height: 2.h),
        UnifiedRevenueDashboardWidget(
          earningsSummary: _earningsSummary,
          revenueBreakdown: _revenueBreakdown,
        ),
        SizedBox(height: 2.h),
        EarningsVisualizationWidget(
          revenueBreakdown: _revenueBreakdown,
          dailyEarnings: _earningsSummary['daily_earnings'] ?? [],
        ),
        SizedBox(height: 2.h),
        RevenueForecastWidget(
          forecast: _forecast,
          currentEarnings: _earningsSummary['total_usd_earned'] ?? 0.0,
        ),
        SizedBox(height: 2.h),
        StripeIntegrationPanelWidget(
          stripeStatus: _stripeStatus,
          onRefresh: _loadData,
        ),
      ],
    );
  }

  Widget _buildRevenueStreamsTab() {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        UnifiedRevenueDashboardWidget(
          earningsSummary: _earningsSummary,
          revenueBreakdown: _revenueBreakdown,
          showDetailed: true,
        ),
        SizedBox(height: 2.h),
        _buildRevenueSourceCards(),
      ],
    );
  }

  Widget _buildTierProgressTab() {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        TierProgressionTrackerWidget(
          tierData: _tierData,
          totalEarnings: _earningsSummary['total_usd_earned'] ?? 0.0,
        ),
      ],
    );
  }

  Widget _buildMilestonesTab() {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        MonetizationMilestonesWidget(
          milestones: _milestones,
          onMilestoneAchieved: _handleMilestoneAchieved,
        ),
      ],
    );
  }

  Widget _buildEarningsOverviewHeader() {
    final totalRevenue = _earningsSummary['total_usd_earned'] ?? 0.0;
    final availableBalance = _earningsSummary['available_balance_usd'] ?? 0.0;
    final pendingBalance = _earningsSummary['pending_balance_usd'] ?? 0.0;
    final currentTier = _tierData['current_tier'] ?? 'Bronze';
    final nextMilestone = _tierData['next_milestone_progress'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withAlpha(179),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Revenue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: Colors.amber,
                      size: 16.sp,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      currentTier,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '\$${totalRevenue.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildBalanceChip(
                  'Available',
                  '\$${availableBalance.toStringAsFixed(2)}',
                  Colors.green,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildBalanceChip(
                  'Pending',
                  '\$${pendingBalance.toStringAsFixed(2)}',
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next Milestone Progress',
                    style: TextStyle(
                      color: Colors.white.withAlpha(230),
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(
                    '${(nextMilestone * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: LinearProgressIndicator(
                  value: nextMilestone,
                  backgroundColor: Colors.white.withAlpha(51),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  minHeight: 8.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChip(String label, String amount, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(204),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            amount,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSourceCards() {
    final sources = [
      {
        'name': 'Election Fees',
        'amount': _earningsSummary['election_fees'] ?? 0.0,
        'icon': Icons.how_to_vote,
        'color': Colors.blue,
      },
      {
        'name': 'Marketplace Services',
        'amount': _earningsSummary['marketplace_revenue'] ?? 0.0,
        'icon': Icons.store,
        'color': Colors.purple,
      },
      {
        'name': 'Brand Partnerships',
        'amount': _earningsSummary['partnership_revenue'] ?? 0.0,
        'icon': Icons.handshake,
        'color': Colors.orange,
      },
      {
        'name': 'Subscription Income',
        'amount': _earningsSummary['subscription_revenue'] ?? 0.0,
        'icon': Icons.card_membership,
        'color': Colors.green,
      },
    ];

    return Column(
      children: sources.map((source) {
        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: (source['color'] as Color).withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  source['icon'] as IconData,
                  color: source['color'] as Color,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source['name'] as String,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Revenue stream',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${(source['amount'] as double).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: source['color'] as Color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _exportEarningsReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating earnings report...'),
          duration: Duration(seconds: 2),
        ),
      );

      await _earningsService.exportEarningsReport(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Earnings report exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMilestoneAchieved(Map<String, dynamic> milestone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            const Text('Milestone Achieved!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              milestone['title'] ?? 'Congratulations!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(milestone['description'] ?? ''),
            const SizedBox(height: 16),
            if (milestone['reward'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Reward: ${milestone['reward']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
