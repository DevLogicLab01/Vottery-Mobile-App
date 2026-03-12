import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/carousel_health_alerting_service.dart';
import '../../services/unified_carousel_ops_hub_service.dart';

/// Carousel Health Alerting Dashboard
/// Twilio SMS alert management with on-call scheduling and escalation workflows
class CarouselHealthAlertingDashboard extends StatefulWidget {
  const CarouselHealthAlertingDashboard({super.key});

  @override
  State<CarouselHealthAlertingDashboard> createState() =>
      _CarouselHealthAlertingDashboardState();
}

class _CarouselHealthAlertingDashboardState
    extends State<CarouselHealthAlertingDashboard> {
  final CarouselHealthAlertingService _alertService =
      CarouselHealthAlertingService.instance;
  final UnifiedCarouselOpsHubService _opsService =
      UnifiedCarouselOpsHubService.instance;

  Map<String, dynamic> _alertMetrics = {};
  List<Map<String, dynamic>> _alertHistory = [];
  List<Map<String, dynamic>> _activeIncidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _alertService.initialize();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final metrics = await _alertService.getAlertMetrics();
    final history = await _alertService.getAlertHistory(limit: 20);
    final incidents = await _opsService.getActiveIncidents();

    setState(() {
      _alertMetrics = metrics;
      _alertHistory = history;
      _activeIncidents = incidents;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carousel Health Alerting'),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAlertStatusOverview(),
                    SizedBox(height: 3.h),
                    _buildCriticalAlertConfiguration(),
                    SizedBox(height: 3.h),
                    _buildActiveIncidentsPanel(),
                    SizedBox(height: 3.h),
                    _buildAlertHistorySection(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTestAlertDialog(),
        icon: const Icon(Icons.send),
        label: const Text('Test Alert'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildAlertStatusOverview() {
    final alertsSent = _alertMetrics['alerts_sent_today'] ?? 0;
    final ackRate = _alertMetrics['acknowledgment_rate'] ?? '0.0';
    final currentOnCall = _alertMetrics['current_on_call'] ?? 'None';

    return Card(
      elevation: 4.0,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.red.shade700,
                  size: 24.0,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Alert Status Overview',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard(
                  'Sent Today',
                  alertsSent.toString(),
                  Icons.send,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'ACK Rate',
                  '$ackRate%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.green.shade700),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current On-Call',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          currentOnCall,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
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

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 40.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32.0),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlertConfiguration() {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Critical Alert Configuration',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildAlertCriteriaItem(
              'Performance Degradation',
              '>30% drop',
              Icons.trending_down,
              Colors.orange,
            ),
            _buildAlertCriteriaItem(
              'System Outage',
              'Any system offline',
              Icons.error,
              Colors.red,
            ),
            _buildAlertCriteriaItem(
              'Anomaly Detection',
              'Critical anomalies',
              Icons.warning,
              Colors.amber,
            ),
            _buildAlertCriteriaItem(
              'Error Rate',
              '>10% errors',
              Icons.bug_report,
              Colors.deepOrange,
            ),
            _buildAlertCriteriaItem(
              'Revenue Drop',
              '>40% decline',
              Icons.attach_money,
              Colors.red.shade700,
            ),
            _buildAlertCriteriaItem(
              'Fraud Spike',
              '>5x normal',
              Icons.security,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCriteriaItem(
    String title,
    String threshold,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20.0),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  threshold,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green, size: 20.0),
        ],
      ),
    );
  }

  Widget _buildActiveIncidentsPanel() {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Incidents',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _activeIncidents.isEmpty
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${_activeIncidents.length} Active',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: _activeIncidents.isEmpty
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _activeIncidents.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(3.h),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 48.0,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'No Active Incidents',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activeIncidents.length,
                    itemBuilder: (context, index) {
                      final incident = _activeIncidents[index];
                      return _buildIncidentCard(incident);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final severity = incident['severity'] as String? ?? 'medium';
    final title = incident['title'] as String? ?? 'Unknown Incident';
    final status = incident['status'] as String? ?? 'new';
    final incidentId = incident['incident_id'] as String;

    Color severityColor;
    switch (severity) {
      case 'critical':
        severityColor = Colors.red;
        break;
      case 'high':
        severityColor = Colors.orange;
        break;
      case 'medium':
        severityColor = Colors.amber;
        break;
      default:
        severityColor = Colors.blue;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: Container(width: 4.0, color: severityColor),
        title: Text(
          title,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Status: $status', style: TextStyle(fontSize: 11.sp)),
        trailing: status == 'new'
            ? ElevatedButton(
                onPressed: () => _acknowledgeIncident(incidentId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
                child: Text('ACK', style: TextStyle(fontSize: 11.sp)),
              )
            : Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildAlertHistorySection() {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SMS Alert History',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _alertHistory.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(3.h),
                      child: Text(
                        'No alerts sent yet',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _alertHistory.length,
                    itemBuilder: (context, index) {
                      final alert = _alertHistory[index];
                      return _buildAlertHistoryItem(alert);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertHistoryItem(Map<String, dynamic> alert) {
    final alertType = alert['alert_type'] as String? ?? 'unknown';
    final recipientPhone = alert['recipient_phone'] as String? ?? 'N/A';
    final deliveryStatus = alert['delivery_status'] as String? ?? 'sent';
    final sentAt = alert['sent_at'] as String?;

    return ListTile(
      leading: Icon(
        deliveryStatus == 'delivered' ? Icons.check_circle : Icons.send,
        color: deliveryStatus == 'delivered' ? Colors.green : Colors.blue,
      ),
      title: Text(
        alertType,
        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Text('To: $recipientPhone', style: TextStyle(fontSize: 11.sp)),
      trailing: sentAt != null
          ? Text(
              DateTime.parse(sentAt).toLocal().toString().substring(11, 16),
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
            )
          : null,
    );
  }

  Future<void> _acknowledgeIncident(String incidentId) async {
    try {
      await _alertService.acknowledgeIncident(incidentId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incident acknowledged')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to acknowledge incident: $e')),
      );
    }
    _loadData();
  }

  void _showTestAlertDialog() {
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Test Alert'),
        content: TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1234567890',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) return;

              Navigator.pop(context);
              final success = await _alertService.sendCriticalAlert(
                alertType: 'test_alert',
                message: 'Test alert from Carousel Health Monitoring Dashboard',
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Test alert sent successfully'
                          : 'Failed to send test alert',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('On-Call Schedule'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                // Navigate to on-call schedule management
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Alert Thresholds'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                // Navigate to threshold configuration
              },
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

  @override
  void dispose() {
    _alertService.dispose();
    super.dispose();
  }
}
