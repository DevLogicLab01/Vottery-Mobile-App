import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/billing_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/billing_history_chart_widget.dart';
import './widgets/billing_preferences_widget.dart';
import './widgets/invoice_list_widget.dart';
import './widgets/payment_methods_widget.dart';
import './widgets/subscription_cancellation_widget.dart';
import './widgets/subscription_tier_management_widget.dart';

/// Enhanced Settings & Account Dashboard with complete Stripe billing integration
class EnhancedSettingsAccountDashboard extends StatefulWidget {
  const EnhancedSettingsAccountDashboard({super.key});

  @override
  State<EnhancedSettingsAccountDashboard> createState() =>
      _EnhancedSettingsAccountDashboardState();
}

class _EnhancedSettingsAccountDashboardState
    extends State<EnhancedSettingsAccountDashboard>
    with SingleTickerProviderStateMixin {
  final BillingService _billingService = BillingService.instance;
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic>? _currentSubscription;
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _invoices = [];
  Map<String, dynamic>? _billingPreferences;
  List<Map<String, dynamic>> _billingAlerts = [];

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
      final subscription = await _subscriptionService.getCurrentSubscription();
      final paymentMethods = await _billingService.getPaymentMethods();
      final invoices = await _billingService.getInvoices();
      final preferences = await _billingService.getBillingPreferences();
      final alerts = await _billingService.getBillingAlerts(unreadOnly: true);

      setState(() {
        _currentSubscription = subscription;
        _paymentMethods = paymentMethods;
        _invoices = invoices;
        _billingPreferences = preferences;
        _billingAlerts = alerts;
      });
    } catch (e) {
      debugPrint('Load billing data error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'EnhancedSettingsAccountDashboard',
      onRetry: _loadData,
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
          title: 'Billing & Subscription',
          actions: [
            if (_billingAlerts.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: Stack(
                  children: [
                    IconButton(
                      icon: CustomIconWidget(
                        iconName: 'notifications',
                        size: 6.w,
                        color: AppTheme.textPrimaryLight,
                      ),
                      onPressed: () => _showBillingAlerts(),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(0.5.w),
                        decoration: BoxDecoration(
                          color: AppTheme.errorLight,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 4.w,
                          minHeight: 4.w,
                        ),
                        child: Text(
                          '${_billingAlerts.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildSubscriptionBanner(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSubscriptionTab(),
                        _buildPaymentMethodsTab(),
                        _buildBillingHistoryTab(),
                        _buildInvoicesTab(),
                        _buildPreferencesTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubscriptionBanner() {
    final isActive = _currentSubscription != null;
    final tier = _currentSubscription?['tier'] ?? 'free';

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [Colors.green, Colors.green.shade700]
              : [AppTheme.primaryLight, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: isActive ? 'check_circle' : 'workspace_premium',
            size: 12.w,
            color: Colors.white,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? '${tier.toUpperCase()} Plan Active' : 'Free Plan',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  isActive
                      ? 'Enjoying premium benefits'
                      : 'Upgrade to unlock premium features',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ],
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
        isScrollable: true,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Subscription'),
          Tab(text: 'Payment Methods'),
          Tab(text: 'Billing History'),
          Tab(text: 'Invoices'),
          Tab(text: 'Preferences'),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          SubscriptionTierManagementWidget(
            currentSubscription: _currentSubscription,
            onUpgrade: (tier) => _handleUpgrade(tier),
            onDowngrade: (tier) => _handleDowngrade(tier),
          ),
          SizedBox(height: 3.h),
          if (_currentSubscription != null)
            SubscriptionCancellationWidget(
              subscription: _currentSubscription!,
              onCancel: () => _handleCancellation(),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsTab() {
    return PaymentMethodsWidget(
      paymentMethods: _paymentMethods,
      onAdd: () => _handleAddPaymentMethod(),
      onRemove: (id) => _handleRemovePaymentMethod(id),
      onSetDefault: (id) => _handleSetDefaultPaymentMethod(id),
      onRefresh: () => _loadData(),
    );
  }

  Widget _buildBillingHistoryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          BillingHistoryChartWidget(invoices: _invoices),
          SizedBox(height: 3.h),
          _buildBillingStats(),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return InvoiceListWidget(
      invoices: _invoices,
      onDownload: (invoice) => _handleDownloadInvoice(invoice),
      onDispute: (invoice) => _handleDisputeInvoice(invoice),
    );
  }

  Widget _buildPreferencesTab() {
    return BillingPreferencesWidget(
      preferences: _billingPreferences,
      onUpdate: (prefs) => _handleUpdatePreferences(prefs),
    );
  }

  Widget _buildBillingStats() {
    final totalPaid = _invoices
        .where((inv) => inv['status'] == 'paid')
        .fold<double>(0, (sum, inv) => sum + (inv['amount'] as num).toDouble());

    final thisMonth = _invoices
        .where(
          (inv) =>
              inv['status'] == 'paid' &&
              DateTime.parse(inv['created_at'].toString()).month ==
                  DateTime.now().month,
        )
        .fold<double>(0, (sum, inv) => sum + (inv['amount'] as num).toDouble());

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Billing Statistics',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Paid',
                  '\$${totalPaid.toStringAsFixed(2)}',
                  Icons.payments,
                  Colors.green,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  'This Month',
                  '\$${thisMonth.toStringAsFixed(2)}',
                  Icons.calendar_today,
                  AppTheme.primaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  void _showBillingAlerts() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Billing Alerts',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: ListView.builder(
                itemCount: _billingAlerts.length,
                itemBuilder: (context, index) {
                  final alert = _billingAlerts[index];
                  return ListTile(
                    leading: Icon(Icons.warning, color: AppTheme.warningLight),
                    title: Text(alert['title'] ?? ''),
                    subtitle: Text(alert['message'] ?? ''),
                    onTap: () {
                      _billingService.markAlertAsRead(alert['id']);
                      Navigator.pop(context);
                      _loadData();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpgrade(String tier) async {
    final success = await _subscriptionService.upgradeTier(tier);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription upgraded successfully')),
      );
      _loadData();
    }
  }

  Future<void> _handleDowngrade(String tier) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Downgrade'),
        content: const Text(
          'Are you sure you want to downgrade? Changes take effect at the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _subscriptionService.upgradeTier(tier);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downgrade scheduled successfully')),
        );
        _loadData();
      }
    }
  }

  Future<void> _handleCancellation() async {
    final success = await _subscriptionService.cancelSubscription();
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Subscription cancelled')));
      _loadData();
    }
  }

  Future<void> _handleAddPaymentMethod() async {
    // TODO: Implement Stripe payment method collection UI
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add payment method - Coming soon')),
    );
  }

  Future<void> _handleRemovePaymentMethod(String id) async {
    final success = await _billingService.removePaymentMethod(id);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment method removed')));
      _loadData();
    }
  }

  Future<void> _handleSetDefaultPaymentMethod(String id) async {
    final success = await _billingService.setDefaultPaymentMethod(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default payment method updated')),
      );
      _loadData();
    }
  }

  Future<void> _handleDownloadInvoice(Map<String, dynamic> invoice) async {
    final path = await _billingService.generateInvoicePDF(invoice);
    if (path != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invoice downloaded: $path')));
    }
  }

  Future<void> _handleDisputeInvoice(Map<String, dynamic> invoice) async {
    // Show dispute dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        String disputeReason = '';
        return AlertDialog(
          title: const Text('Dispute Invoice'),
          content: TextField(
            onChanged: (value) => disputeReason = value,
            decoration: const InputDecoration(
              labelText: 'Reason for dispute',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, disputeReason),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      final success = await _billingService.submitPaymentDispute(
        invoiceId: invoice['id'],
        reason: 'User dispute',
        description: reason,
        amount: invoice['amount'],
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute submitted successfully')),
        );
      }
    }
  }

  Future<void> _handleUpdatePreferences(Map<String, dynamic> prefs) async {
    final success = await _billingService.updateBillingPreferences(
      emailAlertsEnabled: prefs['email_alerts_enabled'],
      failedPaymentAlerts: prefs['failed_payment_alerts'],
      renewalReminders: prefs['renewal_reminders'],
      autoRenewalEnabled: prefs['auto_renewal_enabled'],
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preferences updated')));
      _loadData();
    }
  }
}
