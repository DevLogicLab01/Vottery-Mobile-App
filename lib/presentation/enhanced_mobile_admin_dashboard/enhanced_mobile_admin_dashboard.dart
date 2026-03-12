import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/admin_management_service.dart';
import '../../services/system_monitoring_service.dart';
import './widgets/admin_activity_log_widget.dart';
import './widgets/biometric_gate_widget.dart';
import './widgets/critical_alerts_widget.dart';
import './widgets/emergency_action_panel_widget.dart';
import './widgets/emergency_contacts_widget.dart';
import './widgets/system_health_monitoring_widget.dart';
import './widgets/participation_fee_controls_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

// Platform-specific imports for biometric auth

class EnhancedMobileAdminDashboard extends StatefulWidget {
  const EnhancedMobileAdminDashboard({super.key});

  @override
  State<EnhancedMobileAdminDashboard> createState() =>
      _EnhancedMobileAdminDashboardState();
}

class _EnhancedMobileAdminDashboardState
    extends State<EnhancedMobileAdminDashboard>
    with TickerProviderStateMixin {
  final AdminManagementService _adminService = AdminManagementService.instance;
  final SystemMonitoringService _monitoringService =
      SystemMonitoringService.instance;

  late TabController _tabController;
  Map<String, dynamic> _systemHealth = {};
  List<Map<String, dynamic>> _criticalAlerts = [];
  bool _isLoading = true;
  bool _biometricAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait<dynamic>([
        _monitoringService.getSystemHealthOverview(),
        _monitoringService.getSystemAlerts(
          severity: 'critical',
          status: 'active',
        ),
      ]);

      setState(() {
        _systemHealth = results[0] as Map<String, dynamic>;
        _criticalAlerts = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load data error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        _loadData();
        _startAutoRefresh();
      }
    });
  }

  Future<void> _authenticateBiometric() async {
    setState(() => _biometricAuthenticated = true);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'EnhancedMobileAdminDashboard',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Admin Control Center',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: _loadData,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Alerts'),
              Tab(text: 'Actions'),
              Tab(text: 'Contacts'),
              Tab(text: 'Activity'),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : TabBarView(
                controller: _tabController,
                children: [
                  EmergencyActionPanelWidget(
                    isAuthenticated: _biometricAuthenticated,
                    onAuthRequired: _showBiometricDialog,
                    onRefresh: _loadData,
                  ),
                  CriticalAlertsWidget(
                    alerts: _criticalAlerts,
                    onRefresh: _loadData,
                  ),
                  SystemHealthMonitoringWidget(
                    systemHealth: _systemHealth,
                    onRefresh: _loadData,
                  ),
                  ParticipationFeeControlsWidget(onRefresh: _loadData),
                  AdminActivityLogWidget(onRefresh: _loadData),
                ],
              ),
      ),
    );
  }

  Widget _buildSystemStatusHeader() {
    final apiLatency = _systemHealth['api_latency'] ?? 0;
    final dbLoad = _systemHealth['database_load'] ?? 0;
    final activeUsers = _systemHealth['active_users'] ?? 0;
    final errorRate = _systemHealth['error_rate'] ?? 0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
            child: _buildHealthMetric(
              'API Latency',
              '${apiLatency}ms',
              _getHealthColor(apiLatency, 200, 500),
            ),
          ),
          Expanded(
            child: _buildHealthMetric(
              'DB Load',
              '$dbLoad%',
              _getHealthColor(dbLoad, 70, 90),
            ),
          ),
          Expanded(
            child: _buildHealthMetric(
              'Active Users',
              activeUsers.toString(),
              Colors.blue,
            ),
          ),
          Expanded(
            child: _buildHealthMetric(
              'Error Rate',
              '$errorRate%',
              _getHealthColor(errorRate, 1, 5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getHealthColor(num value, num warning, num critical) {
    if (value < warning) return Colors.green;
    if (value < critical) return Colors.orange;
    return Colors.red;
  }

  void _showBiometricDialog() {
    showDialog(
      context: context,
      builder: (context) => BiometricGateWidget(
        onAuthenticated: () {
          Navigator.pop(context);
          _authenticateBiometric();
        },
      ),
    );
  }

  void _showEmergencyContacts() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const EmergencyContactsWidget(),
    );
  }
}
