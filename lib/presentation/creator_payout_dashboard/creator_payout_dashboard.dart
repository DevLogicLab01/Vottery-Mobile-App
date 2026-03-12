import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/stripe_connect_service.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/stripe_connect_onboarding_widget.dart';

/// Creator Payout Dashboard - Comprehensive earnings and withdrawal system
/// with Stripe Connect Express integration for seamless creator monetization
class CreatorPayoutDashboard extends StatefulWidget {
  const CreatorPayoutDashboard({super.key});

  @override
  State<CreatorPayoutDashboard> createState() => _CreatorPayoutDashboardState();
}

class _CreatorPayoutDashboardState extends State<CreatorPayoutDashboard>
    with SingleTickerProviderStateMixin {
  final StripeConnectService _stripeService = StripeConnectService.instance;
  final AuthService _auth = AuthService.instance;
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic>? _creatorAccount;
  List<Map<String, dynamic>> _payouts = [];
  List<Map<String, dynamic>> _dailyEarnings = [];
  Map<String, dynamic> _earningsSummary = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCreatorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCreatorData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Load creator account
      final accountResponse = await SupabaseService.instance.client
          .from('creator_accounts')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (accountResponse == null) {
        // Create creator account if doesn't exist
        await SupabaseService.instance.client.from('creator_accounts').insert({
          'user_id': userId,
          'pending_balance': 0.0,
          'total_earnings': 0.0,
        });

        // Reload
        final newAccount = await SupabaseService.instance.client
            .from('creator_accounts')
            .select()
            .eq('user_id', userId)
            .single();

        setState(() => _creatorAccount = newAccount);
      } else {
        setState(() => _creatorAccount = accountResponse);
      }

      // Load payouts
      if (_creatorAccount != null) {
        final payoutsResponse = await SupabaseService.instance.client
            .from('creator_payouts')
            .select()
            .eq('creator_id', _creatorAccount!['id'])
            .order('requested_at', ascending: false)
            .limit(50);

        setState(
          () => _payouts = List<Map<String, dynamic>>.from(payoutsResponse),
        );
      }

      // Calculate earnings summary
      _calculateEarningsSummary();

      // Generate daily earnings for chart (last 30 days)
      _generateDailyEarnings();
    } catch (e) {
      debugPrint('Load creator data error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load earnings data'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateEarningsSummary() {
    if (_creatorAccount == null) return;

    final totalEarnings = (_creatorAccount!['total_earnings'] ?? 0.0) as num;
    final pendingBalance = (_creatorAccount!['pending_balance'] ?? 0.0) as num;

    final pendingPayouts = _payouts
        .where((p) => p['status'] == 'requested' || p['status'] == 'processing')
        .fold<double>(
          0.0,
          (sum, p) => sum + ((p['amount'] ?? 0.0) as num).toDouble(),
        );

    final thisMonthEarnings = _payouts
        .where((p) {
          final requestedAt = DateTime.parse(p['requested_at']);
          final now = DateTime.now();
          return requestedAt.year == now.year && requestedAt.month == now.month;
        })
        .fold<double>(
          0.0,
          (sum, p) => sum + ((p['net_amount'] ?? 0.0) as num).toDouble(),
        );

    setState(() {
      _earningsSummary = {
        'total_earnings': totalEarnings.toDouble(),
        'available_balance': pendingBalance.toDouble(),
        'pending_payouts': pendingPayouts,
        'this_month_earnings': thisMonthEarnings,
      };
    });
  }

  void _generateDailyEarnings() {
    final now = DateTime.now();
    final dailyData = <Map<String, dynamic>>[];

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayEarnings = _payouts
          .where((p) {
            final requestedAt = DateTime.parse(p['requested_at']);
            return requestedAt.year == date.year &&
                requestedAt.month == date.month &&
                requestedAt.day == date.day &&
                p['status'] == 'completed';
          })
          .fold<double>(
            0.0,
            (sum, p) => sum + ((p['net_amount'] ?? 0.0) as num).toDouble(),
          );

      dailyData.add({'date': date, 'amount': dayEarnings});
    }

    setState(() => _dailyEarnings = dailyData);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CreatorPayoutDashboard',
      onRetry: _loadCreatorData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Creator Payouts',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: AppTheme.primaryLight),
              onPressed: _loadCreatorData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _loadCreatorData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Earnings Overview Section
                      _buildEarningsOverview(),

                      SizedBox(height: 2.h),

                      // Earnings Chart
                      _buildEarningsChart(),

                      SizedBox(height: 2.h),

                      // Stripe Connect Integration
                      if (_creatorAccount != null)
                        StripeConnectOnboardingWidget(
                          creatorAccount: _creatorAccount!,
                          onOnboardingComplete: _loadCreatorData,
                        ),

                      SizedBox(height: 2.h),

                      // Tabs Section
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppTheme.primaryLight,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: AppTheme.primaryLight,
                          tabs: const [
                            Tab(text: 'Transactions'),
                            Tab(text: 'Withdraw'),
                            Tab(text: 'Settlement'),
                            Tab(text: 'History'),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: 60.h,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Transaction History
                            _buildTransactionHistory(_payouts),

                            // Withdrawal Request
                            _buildWithdrawalRequest(),

                            // Settlement Reconciliation
                            _buildSettlementReconciliation(),

                            // Payout History
                            _buildTransactionHistory(
                              _payouts
                                  .where((p) => p['status'] == 'completed')
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEarningsOverview() {
    return Container(
      padding: EdgeInsets.all(2.h),
      margin: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Total: \$${_earningsSummary['total_earnings']?.toStringAsFixed(2) ?? '0.00'}',
          ),
          Text(
            'Available: \$${_earningsSummary['available_balance']?.toStringAsFixed(2) ?? '0.00'}',
          ),
          Text(
            'Pending: \$${_earningsSummary['pending_payouts']?.toStringAsFixed(2) ?? '0.00'}',
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsChart() {
    return Container(
      padding: EdgeInsets.all(2.h),
      margin: EdgeInsets.symmetric(horizontal: 2.h),
      height: 30.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: _dailyEarnings.isEmpty
          ? Center(child: Text('No earnings data'))
          : Center(child: Text('Earnings Chart')),
    );
  }

  Widget _buildTransactionHistory(List<Map<String, dynamic>> payouts) {
    return ListView.builder(
      padding: EdgeInsets.all(2.h),
      itemCount: payouts.length,
      itemBuilder: (context, index) {
        final payout = payouts[index];
        return Card(
          child: ListTile(
            title: Text('Amount: \$${(payout['amount'] ?? 0.0).toString()}'),
            subtitle: Text('Status: ${payout['status'] ?? 'Unknown'}'),
            trailing: Text(payout['requested_at'] ?? ''),
          ),
        );
      },
    );
  }

  Widget _buildWithdrawalRequest() {
    return Container(
      padding: EdgeInsets.all(2.h),
      child: Column(
        children: [
          Text(
            'Withdrawal Request',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          Text(
            'Available Balance: \$${_earningsSummary['available_balance']?.toStringAsFixed(2) ?? '0.00'}',
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: () {
              // Withdrawal logic
            },
            child: Text('Request Withdrawal'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementReconciliation() {
    return Container(
      padding: EdgeInsets.all(2.h),
      child: Column(
        children: [
          Text(
            'Settlement Reconciliation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          Text('No settlement data available'),
        ],
      ),
    );
  }
}
