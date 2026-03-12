import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/unified_sms_service.dart';
import '../../services/sms_provider_monitor.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/current_provider_card_widget.dart';
import './widgets/provider_health_cards_widget.dart';
import './widgets/failover_history_timeline_widget.dart';
import './widgets/blocked_messages_panel_widget.dart';
import './widgets/health_metrics_chart_widget.dart';
import './widgets/admin_controls_widget.dart';

/// SMS Provider Dashboard
/// Real-time monitoring with health cards, failover history, and manual controls
class SmsProviderDashboard extends StatefulWidget {
  const SmsProviderDashboard({super.key});

  @override
  State<SmsProviderDashboard> createState() => _SmsProviderDashboardState();
}

class _SmsProviderDashboardState extends State<SmsProviderDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _unifiedService = UnifiedSMSService.instance;
  final _providerMonitor = SMSProviderMonitor.instance;

  String _currentProvider = 'telnyx';
  Map<String, dynamic> _deliveryStats = {};
  List<Map<String, dynamic>> _blockedMessages = [];
  List<Map<String, dynamic>> _failoverHistory = [];
  bool _isLoading = true;
  StreamSubscription? _providerSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeServices();
    _loadData();
    _subscribeToProviderChanges();
  }

  Future<void> _initializeServices() async {
    await _unifiedService.initialize();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _unifiedService.getDeliveryStats(),
        _unifiedService.getBlockedMessages(),
        _unifiedService.getFailoverHistory(),
      ]);

      if (mounted) {
        setState(() {
          _currentProvider = _unifiedService.getCurrentProvider();
          _deliveryStats = results[0] as Map<String, dynamic>;
          _blockedMessages = results[1] as List<Map<String, dynamic>>;
          _failoverHistory = results[2] as List<Map<String, dynamic>>;
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

  void _subscribeToProviderChanges() {
    _providerSubscription = _unifiedService.getProviderChangeStream().listen((
      event,
    ) {
      if (mounted) {
        setState(() => _currentProvider = event.toProvider);
        _showProviderChangeNotification(event);
        _loadData();
      }
    });
  }

  void _showProviderChangeNotification(ProviderChangeEvent event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Provider switched: ${event.fromProvider} → ${event.toProvider}',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _handleManualSwitch(String toProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Provider Switch'),
        content: Text(
          'Switch SMS provider to $toProvider?\n\n'
          'This will immediately route all SMS through $toProvider.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _unifiedService.switchProvider(toProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Provider switched to $toProvider'
                  : 'Failed to switch provider',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadData();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _providerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'SMSProviderDashboard',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'SMS Provider Dashboard',
            variant: CustomAppBarVariant.withBack,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Current Provider Status
                  CurrentProviderCardWidget(
                    currentProvider: _currentProvider,
                    deliveryStats: _deliveryStats,
                  ),

                  // Tab Bar
                  Container(
                    color: theme.colorScheme.surface,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurface
                          .withAlpha(153),
                      indicatorColor: theme.colorScheme.primary,
                      tabs: const [
                        Tab(
                          text: 'Health',
                          icon: Icon(Icons.favorite, size: 18),
                        ),
                        Tab(
                          text: 'History',
                          icon: Icon(Icons.history, size: 18),
                        ),
                        Tab(text: 'Blocked', icon: Icon(Icons.block, size: 18)),
                        Tab(
                          text: 'Controls',
                          icon: Icon(Icons.settings, size: 18),
                        ),
                      ],
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildHealthTab(),
                        _buildHistoryTab(),
                        _buildBlockedTab(),
                        _buildControlsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHealthTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProviderHealthCardsWidget(currentProvider: _currentProvider),
            SizedBox(height: 2.h),
            const HealthMetricsChartWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(3.w),
        child: FailoverHistoryTimelineWidget(history: _failoverHistory),
      ),
    );
  }

  Widget _buildBlockedTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(3.w),
        child: BlockedMessagesPanelWidget(blockedMessages: _blockedMessages),
      ),
    );
  }

  Widget _buildControlsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(3.w),
        child: AdminControlsWidget(
          currentProvider: _currentProvider,
          onSwitchProvider: _handleManualSwitch,
        ),
      ),
    );
  }
}
