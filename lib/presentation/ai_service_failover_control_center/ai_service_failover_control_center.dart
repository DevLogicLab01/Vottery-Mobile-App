import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/enhanced_ai_orchestrator_service.dart';
import '../../services/ai_failover_service.dart';
import './widgets/failover_configuration_widget.dart';
import './widgets/failover_status_header_widget.dart';
import './widgets/incident_response_widget.dart';
import './widgets/service_health_card_widget.dart';
import './widgets/service_health_monitoring_widget.dart';
import './widgets/traffic_management_widget.dart';

/// AI Service Failover Control Center
///
/// Manages automatic AI service failover with instant Gemini backup
/// Features:
/// - Real-time service health monitoring
/// - Automatic failover detection (2-second threshold)
/// - Zero-downtime traffic switching
/// - Exponential backoff retry logic
/// - Manual override controls
class AIServiceFailoverControlCenter extends StatefulWidget {
  const AIServiceFailoverControlCenter({super.key});

  @override
  State<AIServiceFailoverControlCenter> createState() =>
      _AIServiceFailoverControlCenterState();
}

class _AIServiceFailoverControlCenterState
    extends State<AIServiceFailoverControlCenter> {
  Map<String, ServiceHealthStatus> _serviceHealth = {};
  List<FailoverEvent> _failoverHistory = [];
  Map<String, dynamic> _trafficStats = {};
  bool _isLoading = true;
  String? _error;
  bool _isPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _subscribeToHealthUpdates();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _isPermissionDenied = false;
      });

      // Load initial data
      final health = EnhancedAIOrchestratorService.getCurrentHealth();
      final history = await EnhancedAIOrchestratorService.getFailoverHistory(
        limit: 20,
      );
      final stats = await EnhancedAIOrchestratorService.getTrafficStats();

      // Load active failovers from secured Supabase view
      await AIFailoverService.instance.getActiveFailovers();

      setState(() {
        _serviceHealth = health;
        _failoverHistory = history;
        _trafficStats = stats;
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
            content: Text('Failed to load failover data: ${e.toString()}'),
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

  void _subscribeToHealthUpdates() {
    EnhancedAIOrchestratorService.getHealthStream().listen((health) {
      if (mounted) {
        setState(() => _serviceHealth = health);
      }
    });
  }

  Future<void> _triggerManualFailover({
    required String fromProvider,
    required String toProvider,
  }) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Manual Failover'),
          content: Text(
            'Switch traffic from $fromProvider to $toProvider?\n\n'
            'This will immediately redirect all AI requests to $toProvider.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Confirm Failover'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Manual failover from $fromProvider to $toProvider initiated',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh data
        await _initializeData();
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Service Failover Control Center',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeData,
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
          : RefreshIndicator(
              onRefresh: _initializeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Failover Status Header
                    FailoverStatusHeaderWidget(
                      serviceHealth: _serviceHealth,
                      trafficStats: _trafficStats,
                    ),
                    SizedBox(height: 2.h),

                    // Service Health Cards
                    Text(
                      'Service Health Overview',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildServiceHealthCards(),
                    SizedBox(height: 2.h),

                    // Service Health Monitoring
                    ServiceHealthMonitoringWidget(
                      serviceHealth: _serviceHealth,
                      onRefresh: _initializeData,
                    ),
                    SizedBox(height: 2.h),

                    // Failover Configuration
                    FailoverConfigurationWidget(
                      onTriggerFailover: _triggerManualFailover,
                    ),
                    SizedBox(height: 2.h),

                    // Traffic Management
                    TrafficManagementWidget(
                      trafficStats: _trafficStats,
                      serviceHealth: _serviceHealth,
                    ),
                    SizedBox(height: 2.h),

                    // Incident Response
                    IncidentResponseWidget(
                      failoverHistory: _failoverHistory,
                      onRefresh: _initializeData,
                    ),
                  ],
                ),
              ),
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
            onPressed: _initializeData,
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

  Widget _buildServiceHealthCards() {
    final providers = ['openai', 'anthropic', 'perplexity', 'gemini'];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 1.h,
        childAspectRatio: 1.5,
      ),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        final health = _serviceHealth[provider];

        return ServiceHealthCardWidget(
          provider: provider,
          health: health,
          onManualFailover: () => _showFailoverDialog(provider),
        );
      },
    );
  }

  Future<void> _showFailoverDialog(String fromProvider) async {
    final providers = [
      'openai',
      'anthropic',
      'perplexity',
      'gemini',
    ].where((p) => p != fromProvider).toList();

    final toProvider = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Failover from $fromProvider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select target provider:'),
            SizedBox(height: 2.h),
            ...providers.map(
              (provider) => ListTile(
                title: Text(provider.toUpperCase()),
                leading: Radio<String>(
                  value: provider,
                  groupValue: null,
                  onChanged: (value) => Navigator.pop(context, value),
                ),
                onTap: () => Navigator.pop(context, provider),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (toProvider != null) {
      await _triggerManualFailover(
        fromProvider: fromProvider,
        toProvider: toProvider,
      );
    }
  }
}
