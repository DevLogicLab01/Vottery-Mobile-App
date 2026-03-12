import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../services/slack_notification_service.dart';

class SlackIncidentNotificationsDashboard extends StatefulWidget {
  const SlackIncidentNotificationsDashboard({super.key});

  @override
  State<SlackIncidentNotificationsDashboard> createState() =>
      _SlackIncidentNotificationsDashboardState();
}

class _SlackIncidentNotificationsDashboardState
    extends State<SlackIncidentNotificationsDashboard> {
  final _slackService = SlackNotificationService.instance;
  final _webhookController = TextEditingController();

  bool _isLoading = true;
  bool _isConnected = false;
  List<Map<String, dynamic>> _notificationHistory = [];
  final Map<String, dynamic> _notificationSettings = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _webhookController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final history = await _slackService.getNotificationHistory(limit: 50);

    setState(() {
      _notificationHistory = history;
      _isConnected = SlackNotificationService.slackWebhookUrl.isNotEmpty;
      _isLoading = false;
    });
  }

  Future<void> _testWebhook() async {
    if (_webhookController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a webhook URL')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _slackService.testWebhook(_webhookController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Webhook test successful!'
                : 'Webhook test failed. Check the URL.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slack Incident Notifications'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.all(3.w),
                children: [
                  _buildConnectionStatusCard(),
                  SizedBox(height: 2.h),
                  _buildWebhookConfigurationCard(),
                  SizedBox(height: 2.h),
                  _buildNotificationSettingsCard(),
                  SizedBox(height: 2.h),
                  _buildNotificationHistoryCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Card(
      color: _isConnected ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Icon(
              _isConnected ? Icons.check_circle : Icons.error,
              color: _isConnected ? Colors.green : Colors.red,
              size: 32.sp,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isConnected ? 'Connected' : 'Not Connected',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: _isConnected ? Colors.green[900] : Colors.red[900],
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _isConnected
                        ? 'Slack workspace is connected and ready'
                        : 'Configure webhook URL to enable notifications',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _isConnected ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebhookConfigurationCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Webhook Configuration',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Text(
              'Incident Alerts Webhook',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _webhookController,
              decoration: InputDecoration(
                hintText: 'https://hooks.slack.com/services/...',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.5.h,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () {
                    if (_webhookController.text.isNotEmpty) {
                      Clipboard.setData(
                        ClipboardData(text: _webhookController.text),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testWebhook,
                    icon: const Icon(Icons.send),
                    label: const Text('Test Webhook'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showWebhookSetupInstructions(),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Setup Guide'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Channels',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildChannelRoutingItem(
              'Security Incidents',
              '#security-alerts',
              Icons.security,
              Colors.red,
            ),
            _buildChannelRoutingItem(
              'Performance Alerts',
              '#performance-alerts',
              Icons.speed,
              Colors.orange,
            ),
            _buildChannelRoutingItem(
              'Payment Failures',
              '#payment-ops',
              Icons.payment,
              Colors.blue,
            ),
            _buildChannelRoutingItem(
              'System Outages',
              '#incidents',
              Icons.error,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelRoutingItem(
    String title,
    String channel,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  channel,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildNotificationHistoryCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification History',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            if (_notificationHistory.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 48.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'No notifications sent yet',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._notificationHistory
                  .take(10)
                  .map((message) => _buildNotificationHistoryItem(message)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHistoryItem(Map<String, dynamic> message) {
    final messageType = message['message_type'] as String;
    final channel = message['channel'] as String;
    final sentAt = message['sent_at'] as String;
    final deliveryStatus = message['delivery_status'] as String;

    final isDelivered = deliveryStatus == 'delivered';

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: isDelivered ? Colors.green[50] : Colors.red[50],
        border: Border.all(
          color: isDelivered ? Colors.green[200]! : Colors.red[200]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isDelivered ? Icons.check_circle : Icons.error,
            color: isDelivered ? Colors.green : Colors.red,
            size: 20.sp,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatMessageType(messageType),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Channel: $channel',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
                Text(
                  _formatTimestamp(sentAt),
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: isDelivered ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isDelivered ? 'Delivered' : 'Failed',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWebhookSetupInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slack Webhook Setup'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Follow these steps to set up Slack notifications:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSetupStep('1', 'Go to https://api.slack.com/apps'),
              _buildSetupStep('2', 'Create a new app or select existing app'),
              _buildSetupStep('3', 'Enable "Incoming Webhooks" feature'),
              _buildSetupStep(
                '4',
                'Add webhook to workspace and select channel',
              ),
              _buildSetupStep('5', 'Copy webhook URL and paste above'),
              _buildSetupStep('6', 'Click "Test Webhook" to verify'),
            ],
          ),
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

  Widget _buildSetupStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _formatMessageType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else {
        return '${diff.inDays} days ago';
      }
    } catch (e) {
      return timestamp;
    }
  }
}
