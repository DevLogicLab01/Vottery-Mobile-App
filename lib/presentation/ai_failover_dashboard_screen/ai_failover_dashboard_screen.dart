import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/ai_health_monitor_service.dart';
import '../../services/ai_failover_orchestrator.dart';
import '../../services/ai_service_cost_tracker.dart';
import '../../services/ai_service_router.dart';
import '../../services/ai_failover_service.dart';
import './widgets/service_health_overview_widget.dart';
import './widgets/manual_failover_controls_widget.dart';

/// AI Failover Dashboard Screen
/// Comprehensive monitoring with instant detection, cost tracking, and manual controls
class AIFailoverDashboardScreen extends StatefulWidget {
  const AIFailoverDashboardScreen({super.key});

  @override
  State<AIFailoverDashboardScreen> createState() =>
      _AIFailoverDashboardScreenState();
}

class _AIFailoverDashboardScreenState extends State<AIFailoverDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, ServiceHealthStatus> _serviceHealth = {};
  List<FailoverEvent> _failoverHistory = [];
  Map<String, dynamic> _costSummary = {};
  bool _isLoading = true;
  String? _error;
  bool _isPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeServices();
    _loadData();
    _subscribeToUpdates();
  }

  Future<void> _initializeServices() async {
    // Initialize health monitoring
    AIHealthMonitorService.instance.startMonitoring();

    // Initialize router
    await AIServiceRouter.instance.initialize();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isPermissionDenied = false;
    });

    try {
      final health = AIHealthMonitorService.instance.getCurrentHealth();
      final history = await AIFailoverOrchestrator.instance.getFailoverHistory(
        limit: 100,
      );
      final costSummary = await AIServiceCostTracker.instance
          .getDailyCostSummary();

      // Load active failovers from secured Supabase view
      await AIFailoverService.instance.getActiveFailovers();

      setState(() {
        _serviceHealth = health;
        _failoverHistory = history;
        _costSummary = costSummary;
        _isLoading = false;
      });
    } on PermissionDeniedException {
      setState(() {
        _isLoading = false;
        _isPermissionDenied = true;
        _error = 'Admin access required';
      });
      if (mounted) {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Admin Access Required'),
          ],
        ),
        content: const Text(
          'AI failover monitoring is restricted to administrators. '
          'Contact your system admin for access.',
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _subscribeToUpdates() {
    AIHealthMonitorService.instance.getHealthStream().listen((health) {
      if (mounted) {
        setState(() => _serviceHealth = health);
      }
    });

    AIFailoverOrchestrator.instance.getFailoverStream().listen((event) {
      if (mounted) {
        setState(() {
          _failoverHistory.insert(0, event);
        });
        _showFailoverNotification(event);
      }
    });
  }

  void _showFailoverNotification(FailoverEvent event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failover: ${event.failedService} → ${event.backupService}',
        ),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _tabController.animateTo(2),
        ),
      ),
    );
  }

  Future<void> _handleManualFailover({
    required String fromService,
    required String toService,
  }) async {
    try {
      await AIFailoverOrchestrator.instance.executeFailover(
        failedService: fromService,
        backupService: toService,
        reason: 'Manual failover triggered by admin',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual failover executed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failover failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Failover Dashboard',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        bottom: _isPermissionDenied
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                  Tab(icon: Icon(Icons.attach_money), text: 'Costs'),
                  Tab(icon: Icon(Icons.history), text: 'History'),
                  Tab(icon: Icon(Icons.settings), text: 'Config'),
                ],
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isPermissionDenied
          ? _buildPermissionDeniedUI()
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCostsTab(),
                _buildHistoryTab(),
                _buildConfigTab(),
              ],
            ),
    );
  }

  Widget _buildPermissionDeniedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey[400]),
          SizedBox(height: 2.h),
          Text(
            'Admin Access Required',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              'You do not have permission to view AI failover data. '
              'Contact your system administrator for access.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Health Overview
            ServiceHealthOverviewWidget(serviceHealth: _serviceHealth),
            SizedBox(height: 2.h),

            // Manual Failover Controls
            ManualFailoverControlsWidget(
              serviceHealth: _serviceHealth,
              onTriggerFailover: _handleManualFailover,
            ),
            SizedBox(height: 2.h),

            // Service Performance Charts
            SizedBox(height: 2.h),

            // Recent Failover Events
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCostsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cost Tracking Dashboard
            SizedBox(height: 2.h),

            // Cost Breakdown Chart
            SizedBox(height: 2.h),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Failover History Table
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alerting Rules Configuration
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
