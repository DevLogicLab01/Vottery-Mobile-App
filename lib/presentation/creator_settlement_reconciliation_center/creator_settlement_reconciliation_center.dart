import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/settlement_service.dart';
import '../../services/stripe_connect_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Creator Settlement & Reconciliation Center
/// Unified revenue dashboard with Stripe Connect and multi-currency support
class CreatorSettlementReconciliationCenter extends StatefulWidget {
  const CreatorSettlementReconciliationCenter({super.key});

  @override
  State<CreatorSettlementReconciliationCenter> createState() =>
      _CreatorSettlementReconciliationCenterState();
}

class _CreatorSettlementReconciliationCenterState
    extends State<CreatorSettlementReconciliationCenter>
    with SingleTickerProviderStateMixin {
  final SettlementService _settlementService = SettlementService.instance;
  final StripeConnectService _stripeService = StripeConnectService.instance;

  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _revenueBreakdown = {};
  List<Map<String, dynamic>> _settlementHistory = [];
  List<Map<String, dynamic>> _discrepancies = [];
  List<Map<String, dynamic>> _taxDocuments = [];

  final _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSettlementData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettlementData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _settlementService.getSettlementSummary(),
        _settlementService.getRevenueBreakdown(),
        _settlementService.getSettlementHistory(limit: 20),
        _settlementService.getReconciliationDiscrepancies(),
        _settlementService.getTaxDocuments(),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as Map<String, dynamic>;
          _revenueBreakdown = results[1] as Map<String, dynamic>;
          _settlementHistory = results[2] as List<Map<String, dynamic>>;
          _discrepancies = results[3] as List<Map<String, dynamic>>;
          _taxDocuments = results[4] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load settlement data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CreatorSettlementReconciliationCenter',
      onRetry: _loadSettlementData,
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
          title: 'Settlement Center',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadSettlementData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildBalanceHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRevenueBreakdownTab(),
                        _buildSettlementHistoryTab(),
                        _buildReconciliationTab(),
                        _buildTaxDocumentsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBalanceHeader() {
    final lifetimeEarnings = _summary['total_lifetime_earnings'] ?? 0.0;
    final pendingSettlement = _summary['pending_settlement'] ?? 0.0;
    final nextPayoutDate = _summary['next_payout_date'];

    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard(
                  'Lifetime Earnings',
                  _currencyFormat.format(lifetimeEarnings),
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildBalanceCard(
                  'Pending Settlement',
                  _currencyFormat.format(pendingSettlement),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next Payout:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  nextPayoutDate != null
                      ? DateFormat(
                          'MMM dd, yyyy',
                        ).format(DateTime.parse(nextPayoutDate))
                      : 'Not scheduled',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
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
        labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Revenue Breakdown'),
          Tab(text: 'Settlement History'),
          Tab(text: 'Reconciliation'),
          Tab(text: 'Tax Documents'),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdownTab() {
    final marketplace = _revenueBreakdown['marketplace'] ?? 0.0;
    final elections = _revenueBreakdown['elections'] ?? 0.0;
    final ads = _revenueBreakdown['ads'] ?? 0.0;
    final total = _revenueBreakdown['total'] ?? 0.0;

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildRevenueSourceCard(
          'Marketplace',
          marketplace,
          total,
          Icons.store,
          Colors.blue,
        ),
        SizedBox(height: 2.h),
        _buildRevenueSourceCard(
          'Elections',
          elections,
          total,
          Icons.how_to_vote,
          Colors.purple,
        ),
        SizedBox(height: 2.h),
        _buildRevenueSourceCard(
          'Ad Revenue',
          ads,
          total,
          Icons.ads_click,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildRevenueSourceCard(
    String source,
    double amount,
    double total,
    IconData icon,
    Color color,
  ) {
    final percentage = total > 0 ? (amount / total) * 100 : 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 8.w),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _currencyFormat.format(amount),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${percentage.toStringAsFixed(1)}% of total',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementHistoryTab() {
    if (_settlementHistory.isEmpty) {
      return _buildEmptyState('No settlement history', Icons.history);
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _settlementHistory.length,
      itemBuilder: (context, index) {
        return _buildSettlementCard(_settlementHistory[index]);
      },
    );
  }

  Widget _buildSettlementCard(Map<String, dynamic> settlement) {
    final periodStart = DateTime.parse(settlement['settlement_period_start']);
    final periodEnd = DateTime.parse(settlement['settlement_period_end']);
    final netAmount = settlement['net_amount'] ?? 0.0;
    final status = settlement['status'] ?? 'pending';
    final currency = settlement['currency'] ?? 'USD';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${DateFormat('MMM dd').format(periodStart)} - ${DateFormat('MMM dd, yyyy').format(periodEnd)}',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              _buildStatusBadge(status),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '$currency ${_currencyFormat.format(netAmount)}',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReconciliationTab() {
    if (_discrepancies.isEmpty) {
      return _buildEmptyState(
        'All settlements reconciled',
        Icons.check_circle_outline,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _discrepancies.length,
      itemBuilder: (context, index) {
        return _buildDiscrepancyCard(_discrepancies[index]);
      },
    );
  }

  Widget _buildDiscrepancyCard(Map<String, dynamic> discrepancy) {
    final expected = discrepancy['expected_amount'] ?? 0.0;
    final actual = discrepancy['actual_amount'] ?? 0.0;
    final difference = discrepancy['difference'] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Discrepancy Found',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildDiscrepancyRow('Expected', expected),
          _buildDiscrepancyRow('Actual', actual),
          _buildDiscrepancyRow('Difference', difference, isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildDiscrepancyRow(
    String label,
    double amount, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.orange : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxDocumentsTab() {
    if (_taxDocuments.isEmpty) {
      return _buildEmptyState('No tax documents', Icons.description);
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _taxDocuments.length,
      itemBuilder: (context, index) {
        return _buildTaxDocumentCard(_taxDocuments[index]);
      },
    );
  }

  Widget _buildTaxDocumentCard(Map<String, dynamic> document) {
    final docType = document['document_type'] ?? 'Unknown';
    final taxYear = document['tax_year'] ?? 0;
    final totalEarnings = document['total_earnings'] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.description, size: 10.w, color: AppTheme.primaryLight),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Form $docType',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Tax Year $taxYear',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _currencyFormat.format(totalEarnings),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.download, size: 6.w),
            onPressed: () => _downloadTaxDocument(document),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'processing':
        color = Colors.blue;
        label = 'Processing';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'failed':
        color = Colors.red;
        label = 'Failed';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20.w, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  void _downloadTaxDocument(Map<String, dynamic> document) {
    debugPrint('Download tax document: ${document['document_id']}');
  }
}
