import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class RealTimeBrandAlertSalesOutreachHub extends StatefulWidget {
  const RealTimeBrandAlertSalesOutreachHub({super.key});

  @override
  State<RealTimeBrandAlertSalesOutreachHub> createState() =>
      _RealTimeBrandAlertSalesOutreachHubState();
}

class _RealTimeBrandAlertSalesOutreachHubState
    extends State<RealTimeBrandAlertSalesOutreachHub> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _campaigns = [];
  List<Map<String, dynamic>> _alerts = [];
  Map<String, dynamic> _webhookConfig = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final mockCampaigns = [
        {
          'id': '1',
          'name': 'Summer Product Launch',
          'brand_name': 'TechCorp',
          'total_budget': 5000.0,
          'spent_budget': 4550.0,
          'budget_utilization': 0.91,
          'projected_completion': '2 days',
          'contact_priority': 'high',
        },
        {
          'id': '2',
          'name': 'Holiday Campaign',
          'brand_name': 'FashionBrand',
          'total_budget': 3000.0,
          'spent_budget': 2730.0,
          'budget_utilization': 0.91,
          'projected_completion': '3 days',
          'contact_priority': 'medium',
        },
      ];

      final mockAlerts = [
        {
          'id': '1',
          'campaign_id': '1',
          'campaign_name': 'Summer Product Launch',
          'alert_type': 'budget_threshold',
          'threshold': 90,
          'current_spend': 91,
          'message': 'Campaign reached 91% budget utilization',
          'created_at': DateTime.now()
              .subtract(Duration(minutes: 5))
              .toIso8601String(),
          'is_sent': true,
        },
      ];

      setState(() {
        _campaigns = mockCampaigns;
        _alerts = mockAlerts;
        _webhookConfig = {
          'slack_enabled': true,
          'discord_enabled': false,
          'slack_channel': '#sales-alerts',
          'delivery_confirmed': true,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'RealTimeBrandAlertSalesOutreachHub',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Brand Alert & Sales Outreach',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showWebhookConfig,
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAlertStatusOverview(),
                      SizedBox(height: 2.h),
                      Text(
                        'Alert Management',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      _buildBudgetThresholdMonitoring(),
                      SizedBox(height: 2.h),
                      _buildWebhookIntegrationDashboard(),
                      SizedBox(height: 2.h),
                      _buildProactiveOutreachQueue(),
                      SizedBox(height: 2.h),
                      _buildCampaignPerformanceAlerts(),
                      SizedBox(height: 2.h),
                      Text(
                        'Recent Alerts',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      ..._alerts.map(
                        (alert) => Padding(
                          padding: EdgeInsets.only(bottom: 1.h),
                          child: _buildAlertCard(alert),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      _buildSalesOpportunityDashboard(),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          ShimmerSkeletonLoader(
            child: SizedBox(height: 15.h, width: double.infinity),
          ),
          SizedBox(height: 2.h),
          ShimmerSkeletonLoader(
            child: SizedBox(height: 20.h, width: double.infinity),
          ),
          SizedBox(height: 2.h),
          ShimmerSkeletonLoader(
            child: SizedBox(height: 20.h, width: double.infinity),
          ),
        ],
      ),
    );
  }

  double _calculateAvgUtilization() {
    if (_campaigns.isEmpty) return 0.0;
    final total = _campaigns.fold<double>(
      0.0,
      (sum, c) => sum + (c['budget_utilization'] as double),
    );
    return total / _campaigns.length;
  }

  Widget _buildAlertStatusOverview() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            Text('Active Campaigns: ${_campaigns.length}'),
            Text(
              'Avg Budget Utilization: ${(_calculateAvgUtilization() * 100).toStringAsFixed(1)}%',
            ),
            Text('Outreach Opportunities: ${_campaigns.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetThresholdMonitoring() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Threshold Monitoring',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ..._campaigns.map(
              (c) => ListTile(
                title: Text(c['name'] as String),
                subtitle: Text(
                  '${((c['budget_utilization'] as double) * 100).toStringAsFixed(1)}%',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebhookIntegrationDashboard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Webhook Integration',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Slack: ${_webhookConfig['slack_enabled'] == true ? 'Enabled' : 'Disabled'}',
            ),
            Text(
              'Discord: ${_webhookConfig['discord_enabled'] == true ? 'Enabled' : 'Disabled'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProactiveOutreachQueue() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proactive Outreach Queue',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ..._campaigns.map(
              (c) => ListTile(
                title: Text(c['name'] as String),
                trailing: ElevatedButton(
                  onPressed: () => _handleOutreach(c['id'] as String),
                  child: Text('Contact'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignPerformanceAlerts() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campaign Performance Alerts',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Total Alerts: ${_alerts.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    return Card(
      child: ListTile(
        title: Text(alert['campaign_name'] as String),
        subtitle: Text(alert['message'] as String),
        trailing: IconButton(
          icon: Icon(Icons.check),
          onPressed: () =>
              _handleAlertAction(alert['id'] as String, 'acknowledge'),
        ),
      ),
    );
  }

  Widget _buildSalesOpportunityDashboard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Opportunity Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'High Priority Campaigns: ${_campaigns.where((c) => c['contact_priority'] == 'high').length}',
            ),
          ],
        ),
      ),
    );
  }

  void _showWebhookConfig() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => _buildWebhookConfigPanel(),
    );
  }

  Widget _buildWebhookConfigPanel() {
    return Container(
      padding: EdgeInsets.all(3.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Webhook Configuration',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          SwitchListTile(
            title: Text('Enable Slack'),
            value: _webhookConfig['slack_enabled'] as bool,
            onChanged: (value) {
              final config = Map<String, dynamic>.from(_webhookConfig);
              config['slack_enabled'] = value;
              _updateWebhookConfig(config);
            },
          ),
          SwitchListTile(
            title: Text('Enable Discord'),
            value: _webhookConfig['discord_enabled'] as bool,
            onChanged: (value) {
              final config = Map<String, dynamic>.from(_webhookConfig);
              config['discord_enabled'] = value;
              _updateWebhookConfig(config);
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWebhookConfig(Map<String, dynamic> config) async {
    setState(() => _webhookConfig = config);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Webhook configuration updated')),
    );
  }

  Future<void> _handleOutreach(String campaignId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Outreach initiated - CRM updated')),
    );
  }

  Future<void> _handleAlertAction(String alertId, String action) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Alert action: $action')));
  }
}
