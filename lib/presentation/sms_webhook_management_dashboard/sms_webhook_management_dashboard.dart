import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/supabase_service.dart';
import '../../services/sms_provider_monitor.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/webhook_configuration_card_widget.dart';
import './widgets/event_processing_feed_widget.dart';
import './widgets/delivery_tracking_panel_widget.dart';
import './widgets/failover_monitoring_widget.dart';
import './widgets/bounce_management_panel_widget.dart';

/// SMS Webhook Management Dashboard
/// Comprehensive webhook infrastructure oversight with Telnyx and Twilio monitoring
class SmsWebhookManagementDashboard extends StatefulWidget {
  const SmsWebhookManagementDashboard({super.key});

  @override
  State<SmsWebhookManagementDashboard> createState() =>
      _SmsWebhookManagementDashboardState();
}

class _SmsWebhookManagementDashboardState
    extends State<SmsWebhookManagementDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = SupabaseService.instance.client;
  final _providerMonitor = SMSProviderMonitor.instance;

  Map<String, dynamic> _webhookStats = {};
  List<Map<String, dynamic>> _recentEvents = [];
  List<Map<String, dynamic>> _bounceList = [];
  Map<String, dynamic> _deliveryStats = {};
  bool _isLoading = true;
  StreamSubscription? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    _subscribeToRealtimeUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _loadWebhookStats(),
        _loadRecentEvents(),
        _loadBounceList(),
        _loadDeliveryStats(),
      ]);

      if (mounted) {
        setState(() {
          _webhookStats = results[0] as Map<String, dynamic>;
          _recentEvents = results[1] as List<Map<String, dynamic>>;
          _bounceList = results[2] as List<Map<String, dynamic>>;
          _deliveryStats = results[3] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _loadWebhookStats() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final response = await _supabase
          .from('sms_webhook_events')
          .select('provider, processed')
          .gte('received_at', todayStart.toIso8601String());

      final events = List<Map<String, dynamic>>.from(response);

      final telnyxTotal = events.where((e) => e['provider'] == 'telnyx').length;
      final twilioTotal = events.where((e) => e['provider'] == 'twilio').length;
      final telnyxProcessed = events
          .where((e) => e['provider'] == 'telnyx' && e['processed'] == true)
          .length;
      final twilioProcessed = events
          .where((e) => e['provider'] == 'twilio' && e['processed'] == true)
          .length;

      return {
        'telnyx_total': telnyxTotal,
        'twilio_total': twilioTotal,
        'telnyx_processed': telnyxProcessed,
        'twilio_processed': twilioProcessed,
        'telnyx_success_rate': telnyxTotal > 0
            ? (telnyxProcessed / telnyxTotal * 100).toStringAsFixed(1)
            : '0.0',
        'twilio_success_rate': twilioTotal > 0
            ? (twilioProcessed / twilioTotal * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      debugPrint('Error loading webhook stats: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _loadRecentEvents() async {
    try {
      final response = await _supabase
          .from('sms_webhook_events')
          .select()
          .order('received_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading recent events: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadBounceList() async {
    try {
      final response = await _supabase
          .from('sms_bounce_list')
          .select()
          .eq('is_suppressed', true)
          .order('first_bounced_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading bounce list: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _loadDeliveryStats() async {
    try {
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));

      final response = await _supabase
          .from('sms_delivery_log')
          .select('provider_used, delivery_status')
          .gte('sent_at', oneDayAgo.toIso8601String());

      final logs = List<Map<String, dynamic>>.from(response);

      final telnyxSent = logs
          .where((l) => l['provider_used'] == 'telnyx')
          .length;
      final twilioSent = logs
          .where((l) => l['provider_used'] == 'twilio')
          .length;
      final telnyxDelivered = logs
          .where(
            (l) =>
                l['provider_used'] == 'telnyx' &&
                l['delivery_status'] == 'delivered',
          )
          .length;
      final twilioDelivered = logs
          .where(
            (l) =>
                l['provider_used'] == 'twilio' &&
                l['delivery_status'] == 'delivered',
          )
          .length;
      final telnyxFailed = logs
          .where(
            (l) =>
                l['provider_used'] == 'telnyx' &&
                l['delivery_status'] == 'failed',
          )
          .length;
      final twilioFailed = logs
          .where(
            (l) =>
                l['provider_used'] == 'twilio' &&
                l['delivery_status'] == 'failed',
          )
          .length;

      return {
        'telnyx_sent': telnyxSent,
        'twilio_sent': twilioSent,
        'telnyx_delivered': telnyxDelivered,
        'twilio_delivered': twilioDelivered,
        'telnyx_failed': telnyxFailed,
        'twilio_failed': twilioFailed,
        'telnyx_delivery_rate': telnyxSent > 0
            ? (telnyxDelivered / telnyxSent * 100).toStringAsFixed(1)
            : '0.0',
        'twilio_delivery_rate': twilioSent > 0
            ? (twilioDelivered / twilioSent * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      debugPrint('Error loading delivery stats: $e');
      return {};
    }
  }

  void _subscribeToRealtimeUpdates() {
    _realtimeSubscription = _supabase
        .from('sms_webhook_events')
        .stream(primaryKey: ['event_id'])
        .listen((data) {
          if (mounted) {
            _loadData();
          }
        });
  }

  Future<void> _manualFailover(String toProvider) async {
    try {
      await _supabase.from('sms_provider_state').insert({
        'current_provider': toProvider,
        'previous_provider': _providerMonitor.getCurrentProvider(),
        'switch_reason': 'Manual failover triggered by admin',
        'is_manual_override': true,
        'override_by': _supabase.auth.currentUser?.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failover to $toProvider successful'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failover failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'SmsWebhookManagementDashboard',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'SMS Webhook Management',
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
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                'Telnyx Webhooks',
                                _webhookStats['telnyx_total']?.toString() ??
                                    '0',
                                '${_webhookStats['telnyx_success_rate'] ?? '0'}% processed',
                                Colors.blue,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: _buildMetricCard(
                                'Twilio Webhooks',
                                _webhookStats['twilio_total']?.toString() ??
                                    '0',
                                '${_webhookStats['twilio_success_rate'] ?? '0'}% processed',
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                'Delivery Rate',
                                '${_deliveryStats['telnyx_delivery_rate'] ?? '0'}%',
                                'Telnyx (24h)',
                                Colors.green,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: _buildMetricCard(
                                'Bounce Count',
                                _bounceList.length.toString(),
                                'Suppressed numbers',
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(
                      153,
                    ),
                    indicatorColor: theme.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Configuration'),
                      Tab(text: 'Event Feed'),
                      Tab(text: 'Delivery'),
                      Tab(text: 'Failover'),
                      Tab(text: 'Bounces'),
                    ],
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        WebhookConfigurationCardWidget(
                          onManualFailover: _manualFailover,
                        ),
                        EventProcessingFeedWidget(events: _recentEvents),
                        DeliveryTrackingPanelWidget(stats: _deliveryStats),
                        FailoverMonitoringWidget(onRefresh: _loadData),
                        BounceManagementPanelWidget(
                          bounceList: _bounceList,
                          onRefresh: _loadData,
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
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
