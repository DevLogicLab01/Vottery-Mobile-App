import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/cost_adjustment_sliders_widget.dart';
import './widgets/emergency_controls_widget.dart';
import './widgets/fraud_detection_widget.dart';
import './widgets/inflation_controls_widget.dart';
import './widgets/redemption_limits_widget.dart';
import './widgets/vp_supply_analytics_widget.dart';

/// VP Economy Management Dashboard
/// Admin dashboard for managing VP economy with dynamic cost controls,
/// inflation/deflation settings, fraud detection, and emergency VP freeze
class VPEconomyManagementDashboard extends StatefulWidget {
  const VPEconomyManagementDashboard({super.key});

  @override
  State<VPEconomyManagementDashboard> createState() =>
      _VPEconomyManagementDashboardState();
}

class _VPEconomyManagementDashboardState
    extends State<VPEconomyManagementDashboard>
    with SingleTickerProviderStateMixin {
  final VPService _vpService = VPService.instance;
  final _supabase = SupabaseService.instance.client;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _economyStats = {};
  List<Map<String, dynamic>> _topEarners = [];
  List<Map<String, dynamic>> _topSpenders = [];
  final List<Map<String, dynamic>> _fraudAlerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEconomyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEconomyData() async {
    setState(() => _isLoading = true);

    try {
      // Get total VP in circulation
      final vpBalanceResponse = await _supabase
          .from('vp_balance')
          .select('available_vp, lifetime_earned, lifetime_spent');

      final vpBalances = vpBalanceResponse as List<dynamic>? ?? [];
      final totalVPInCirculation = vpBalances.fold<int>(
        0,
        (sum, item) => sum + (item['available_vp'] as int? ?? 0),
      );
      final totalVPEarned = vpBalances.fold<int>(
        0,
        (sum, item) => sum + (item['lifetime_earned'] as int? ?? 0),
      );
      final totalVPSpent = vpBalances.fold<int>(
        0,
        (sum, item) => sum + (item['lifetime_spent'] as int? ?? 0),
      );

      // Get daily transaction volume
      final transactionsResponse = await _supabase
          .from('vp_transactions')
          .select('amount')
          .gte(
            'created_at',
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          );

      final transactions = transactionsResponse as List<dynamic>? ?? [];
      final dailyVolume = transactions.fold<int>(
        0,
        (sum, item) => sum + (item['amount'] as int? ?? 0).abs(),
      );

      // Get top earners
      final topEarnersResponse = await _supabase
          .from('vp_balance')
          .select('user_id, lifetime_earned, user_profiles!inner(name, email)')
          .order('lifetime_earned', ascending: false)
          .limit(10);

      // Get top spenders
      final topSpendersResponse = await _supabase
          .from('vp_balance')
          .select('user_id, lifetime_spent, user_profiles!inner(name, email)')
          .order('lifetime_spent', ascending: false)
          .limit(10);

      // Calculate inflation indicator
      final inflationRate = totalVPEarned > 0
          ? ((totalVPInCirculation - totalVPSpent) / totalVPEarned * 100)
          : 0.0;

      if (mounted) {
        setState(() {
          _economyStats = {
            'total_vp_circulation': totalVPInCirculation,
            'total_vp_earned': totalVPEarned,
            'total_vp_spent': totalVPSpent,
            'daily_transaction_volume': dailyVolume,
            'inflation_rate': inflationRate,
            'active_users': vpBalances.length,
          };
          _topEarners = List<Map<String, dynamic>>.from(
            topEarnersResponse ?? [],
          );
          _topSpenders = List<Map<String, dynamic>>.from(
            topSpendersResponse ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load economy data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadEconomyData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'VPEconomyManagementDashboard',
      onRetry: _loadEconomyData,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'VP Economy Management',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              onPressed: _refreshData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: theme.colorScheme.primary,
                child: Column(
                  children: [
                    // Economy Status Overview Header
                    _buildEconomyStatusHeader(theme),

                    SizedBox(height: 2.h),

                    // Tab Bar
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: theme.colorScheme.onPrimary,
                        unselectedLabelColor:
                            theme.colorScheme.onSurfaceVariant,
                        indicator: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tabs: const [
                          Tab(text: 'Controls'),
                          Tab(text: 'Analytics'),
                          Tab(text: 'Security'),
                        ],
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildControlsTab(theme),
                          _buildAnalyticsTab(theme),
                          _buildSecurityTab(theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEconomyStatusHeader(ThemeData theme) {
    final totalVP = _economyStats['total_vp_circulation'] ?? 0;
    final dailyVolume = _economyStats['daily_transaction_volume'] ?? 0;
    final inflationRate = _economyStats['inflation_rate'] ?? 0.0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Economy Status Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                theme,
                'Total VP in Circulation',
                totalVP.toString(),
                'account_balance_wallet',
              ),
              _buildStatCard(
                theme,
                'Daily Transaction Volume',
                dailyVolume.toString(),
                'trending_up',
              ),
              _buildStatCard(
                theme,
                'Inflation Rate',
                '${inflationRate.toStringAsFixed(2)}%',
                inflationRate > 0 ? 'arrow_upward' : 'arrow_downward',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    String iconName,
  ) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 1.w),
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
            SizedBox(height: 1.h),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CostAdjustmentSlidersWidget(onRefresh: _refreshData),
          SizedBox(height: 3.h),
          InflationControlsWidget(onRefresh: _refreshData),
          SizedBox(height: 3.h),
          RedemptionLimitsWidget(onRefresh: _refreshData),
          SizedBox(height: 3.h),
          EmergencyControlsWidget(onRefresh: _refreshData),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VPSupplyAnalyticsWidget(economyStats: _economyStats),
          SizedBox(height: 3.h),
          _buildLeaderboardsSection(theme),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FraudDetectionWidget(
            fraudAlerts: _fraudAlerts,
            onRefresh: _refreshData,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Earners & Spenders',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLeaderboardCard(
                theme,
                'Top Earners',
                _topEarners,
                'lifetime_earned',
                Colors.green,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildLeaderboardCard(
                theme,
                'Top Spenders',
                _topSpenders,
                'lifetime_spent',
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(
    ThemeData theme,
    String title,
    List<Map<String, dynamic>> users,
    String valueKey,
    Color accentColor,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                title.contains('Earners')
                    ? Icons.trending_up
                    : Icons.shopping_cart,
                color: accentColor,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...users.take(5).map((user) {
            final userProfile =
                user['user_profiles'] as Map<String, dynamic>? ?? {};
            final name = userProfile['name'] ?? 'Unknown User';
            final value = user[valueKey] ?? 0;

            return Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$value VP',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: accentColor,
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
}
