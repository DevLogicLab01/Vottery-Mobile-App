import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../core/app_export.dart';
import '../../services/webhook_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Webhook Integration Management Hub Screen
class WebhookIntegrationManagementHub extends StatefulWidget {
  const WebhookIntegrationManagementHub({super.key});

  @override
  State<WebhookIntegrationManagementHub> createState() =>
      _WebhookIntegrationManagementHubState();
}

class _WebhookIntegrationManagementHubState
    extends State<WebhookIntegrationManagementHub> {
  final WebhookService _webhookService = WebhookService.instance;

  List<Map<String, dynamic>> _webhookConfigs = [];
  List<Map<String, dynamic>> _deliveryLogs = [];
  Map<String, dynamic>? _selectedConfig;
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String _selectedTab = 'configurations';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final configs = await _webhookService.getWebhookConfigurations();
    final logs = await _webhookService.getDeliveryLogs(configId: '', limit: 50);

    setState(() {
      _webhookConfigs = configs;
      _deliveryLogs = logs;
      _isLoading = false;
    });
  }

  Future<void> _loadAnalytics(String configId) async {
    final analytics = await _webhookService.getDeliveryAnalytics(
      configId: configId,
    );
    setState(() => _analytics = analytics);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'WebhookIntegrationManagementHub',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Webhook Integration Hub',
          variant: CustomAppBarVariant.withBack,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: _selectedTab == 'configurations'
                        ? _buildConfigurationsTab()
                        : _buildDeliveryLogsTab(),
                  ),
                ],
              ),
        floatingActionButton: _selectedTab == 'configurations'
            ? FloatingActionButton.extended(
                onPressed: _showCreateWebhookDialog,
                icon: Icon(Icons.add),
                label: Text('Add Webhook'),
                backgroundColor: AppTheme.accentLight,
              )
            : null,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.all(2.w),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: _buildTabButton('configurations', 'Configurations')),
          SizedBox(width: 2.w),
          Expanded(child: _buildTabButton('logs', 'Delivery Logs')),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final isSelected = _selectedTab == tab;
    return ElevatedButton(
      onPressed: () => setState(() => _selectedTab = tab),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? AppTheme.primaryLight
            : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildConfigurationsTab() {
    if (_webhookConfigs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.webhook, size: 20.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No webhook configurations yet',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _webhookConfigs.length,
      itemBuilder: (context, index) {
        final config = _webhookConfigs[index];
        return _buildWebhookCard(config);
      },
    );
  }

  Widget _buildWebhookCard(Map<String, dynamic> config) {
    final isActive = config['is_active'] ?? false;
    final eventTypes = List<String>.from(config['event_types'] ?? []);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    config['name'] ?? 'Unnamed Webhook',
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (value) => _toggleWebhook(config['id'], value),
                  activeThumbColor: AppTheme.accentLight,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              config['endpoint_url'] ?? '',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 1.w,
              runSpacing: 1.h,
              children: eventTypes
                  .map(
                    (event) => Chip(
                      label: Text(event, style: TextStyle(fontSize: 10.sp)),
                      backgroundColor: AppTheme.primaryLight.withAlpha(26),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAnalytics(config),
                  icon: Icon(Icons.analytics, size: 4.w),
                  label: Text('Analytics'),
                ),
                TextButton.icon(
                  onPressed: () => _testWebhook(config),
                  icon: Icon(Icons.play_arrow, size: 4.w),
                  label: Text('Test'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteWebhook(config['id']),
                  icon: Icon(Icons.delete, size: 4.w, color: Colors.red),
                  label: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryLogsTab() {
    if (_deliveryLogs.isEmpty) {
      return Center(
        child: Text(
          'No delivery logs yet',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _deliveryLogs.length,
      itemBuilder: (context, index) {
        final log = _deliveryLogs[index];
        return _buildDeliveryLogCard(log);
      },
    );
  }

  Widget _buildDeliveryLogCard(Map<String, dynamic> log) {
    final status = log['delivery_status'] ?? 'pending';
    final statusColor = status == 'success'
        ? Colors.green
        : status == 'failed'
        ? Colors.red
        : Colors.orange;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: Icon(Icons.webhook, color: statusColor),
        title: Text(
          log['event_type'] ?? 'Unknown Event',
          style: google_fonts.GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status'),
            if (log['response_time_ms'] != null)
              Text('Response: ${log['response_time_ms']}ms'),
            if (log['attempt_count'] != null)
              Text('Attempts: ${log['attempt_count']}'),
          ],
        ),
        trailing: status == 'failed'
            ? IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => _retryDelivery(log['id']),
              )
            : null,
      ),
    );
  }

  void _showCreateWebhookDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final selectedEvents = <String>{};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Webhook'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: urlController,
                decoration: InputDecoration(labelText: 'Endpoint URL'),
              ),
              SizedBox(height: 2.h),
              Text('Select Events:'),
              ...[
                'vote.cast',
                'draw.completed',
                'winner.announced',
                'ticket.generated',
                'prize.distributed',
              ].map(
                (event) => CheckboxListTile(
                  title: Text(event),
                  value: selectedEvents.contains(event),
                  onChanged: (value) {
                    if (value == true) {
                      selectedEvents.add(event);
                    } else {
                      selectedEvents.remove(event);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _webhookService.createWebhookConfiguration(
                webhookUrl: urlController.text,
                eventTypes: selectedEvents.toList(),
              );
              Navigator.pop(context);
              _loadData();
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleWebhook(String configId, bool isActive) async {
    await _webhookService.updateWebhookConfiguration(
      configId: configId,
      isActive: isActive,
    );
    _loadData();
  }

  Future<void> _testWebhook(Map<String, dynamic> config) async {
    final result = await _webhookService.testWebhook(configId: config['id']);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Webhook test successful!'
              : 'Webhook test failed: ${result['message']}',
        ),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _showAnalytics(Map<String, dynamic> config) async {
    await _loadAnalytics(config['id']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Webhook Analytics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAnalyticRow(
              'Total Deliveries',
              _analytics['total_deliveries']?.toString() ?? '0',
            ),
            _buildAnalyticRow(
              'Success Rate',
              '${_analytics['success_rate']?.toString() ?? '0'}%',
            ),
            _buildAnalyticRow(
              'Avg Response Time',
              '${_analytics['average_response_time_ms']?.toString() ?? '0'}ms',
            ),
            _buildAnalyticRow(
              'Retries',
              _analytics['retry_count']?.toString() ?? '0',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: google_fonts.GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWebhook(String configId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Webhook'),
        content: Text('Are you sure you want to delete this webhook?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _webhookService.deleteWebhookConfiguration(configId);
      _loadData();
    }
  }

  Future<void> _retryDelivery(String logId) async {
    final success = await _webhookService.testWebhook(configId: logId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success['success'] == true ? 'Retry initiated' : 'Retry failed',
        ),
      ),
    );
    _loadData();
  }
}
