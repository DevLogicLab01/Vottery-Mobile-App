import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/sms_alerts_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/emergency_contacts_widget.dart';
import './widgets/message_templates_widget.dart';
import './widgets/delivery_analytics_widget.dart';
import './widgets/cost_tracking_widget.dart';
import './widgets/send_alert_widget.dart';
import './widgets/scheduled_messages_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class SmsEmergencyAlertsHub extends StatefulWidget {
  const SmsEmergencyAlertsHub({super.key});

  @override
  State<SmsEmergencyAlertsHub> createState() => _SmsEmergencyAlertsHubState();
}

class _SmsEmergencyAlertsHubState extends State<SmsEmergencyAlertsHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _deliveryAnalytics = {};
  Map<String, dynamic> _costAnalytics = {};
  List<Map<String, dynamic>> _emergencyContacts = [];
  List<Map<String, dynamic>> _messageTemplates = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
        SmsAlertsService.instance.getDeliveryAnalytics(),
        SmsAlertsService.instance.getTotalCostAnalytics(),
        SmsAlertsService.instance.getEmergencyContacts(),
        SmsAlertsService.instance.getMessageTemplates(),
      ]);

      if (mounted) {
        setState(() {
          _deliveryAnalytics = results[0] as Map<String, dynamic>;
          _costAnalytics = results[1] as Map<String, dynamic>;
          _emergencyContacts = results[2] as List<Map<String, dynamic>>;
          _messageTemplates = results[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'SMSEmergencyAlertsHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'SMS Emergency Alerts Hub',
            variant: CustomAppBarVariant.withBack,
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  // Header with key metrics
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
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
                        Expanded(
                          child: _buildMetricCard(
                            'Delivery Rate',
                            '${_deliveryAnalytics['success_rate'] ?? '0.0'}%',
                            Icons.check_circle_outline,
                            Colors.green,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: _buildMetricCard(
                            'Total Sent',
                            '${_deliveryAnalytics['total'] ?? 0}',
                            Icons.send,
                            Colors.blue,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: _buildMetricCard(
                            'Budget Used',
                            '${_costAnalytics['budget_used_percentage'] ?? '0.0'}%',
                            Icons.attach_money,
                            Colors.orange,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: _buildMetricCard(
                            'Contacts',
                            '${_emergencyContacts.length}',
                            Icons.contacts,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab bar
                  Container(
                    color: theme.colorScheme.surface,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurface
                          .withAlpha(153),
                      indicatorColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: TextStyle(fontSize: 12.sp),
                      tabs: const [
                        Tab(text: 'Send Alert'),
                        Tab(text: 'Contacts'),
                        Tab(text: 'Templates'),
                        Tab(text: 'Delivery'),
                        Tab(text: 'Cost Tracking'),
                        Tab(text: 'Scheduled'),
                      ],
                    ),
                  ),

                  // Tab views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        SendAlertWidget(
                          contacts: _emergencyContacts,
                          templates: _messageTemplates,
                          onAlertSent: _loadData,
                        ),
                        EmergencyContactsWidget(
                          contacts: _emergencyContacts,
                          onContactsChanged: _loadData,
                        ),
                        MessageTemplatesWidget(
                          templates: _messageTemplates,
                          onTemplatesChanged: _loadData,
                        ),
                        DeliveryAnalyticsWidget(analytics: _deliveryAnalytics),
                        CostTrackingWidget(costAnalytics: _costAnalytics),
                        ScheduledMessagesWidget(onScheduleChanged: _loadData),
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
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
