import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/realtime_dashboard_service.dart';
import './widgets/connection_status_widget.dart';
import './widgets/dashboard_subscription_card_widget.dart';
import './widgets/interval_configuration_widget.dart';
import './widgets/presence_tracking_widget.dart';

class RealTimeDashboardRefreshControlCenter extends StatefulWidget {
  const RealTimeDashboardRefreshControlCenter({super.key});

  @override
  State<RealTimeDashboardRefreshControlCenter> createState() =>
      _RealTimeDashboardRefreshControlCenterState();
}

class _RealTimeDashboardRefreshControlCenterState
    extends State<RealTimeDashboardRefreshControlCenter> {
  final RealtimeDashboardService _dashboardService = RealtimeDashboardService();
  final AuthService _authService = AuthService.instance;
  bool _isLoading = true;
  Map<String, dynamic> _connectionStatus = {};

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() => _isLoading = true);
    try {
      await _dashboardService.connect();
      _updateConnectionStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateConnectionStatus() {
    setState(() {
      _connectionStatus = _dashboardService.getConnectionStatus();
    });
  }

  @override
  void dispose() {
    _dashboardService.disconnectAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Real-Time Dashboard Refresh',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryLight,
      ),
      drawer: _buildNavigationDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _initializeService,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConnectionStatusWidget(
                      connectionStatus: _connectionStatus,
                      onRefresh: _updateConnectionStatus,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Dashboard Subscriptions',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ...DashboardType.values.map((type) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 2.h),
                        child: DashboardSubscriptionCardWidget(
                          dashboardType: type,
                          dashboardService: _dashboardService,
                          onUpdate: _updateConnectionStatus,
                        ),
                      );
                    }),
                    SizedBox(height: 2.h),
                    IntervalConfigurationWidget(
                      dashboardService: _dashboardService,
                      onSave: _updateConnectionStatus,
                    ),
                    SizedBox(height: 2.h),
                    PresenceTrackingWidget(
                      dashboardService: _dashboardService,
                      userId: _authService.currentUser?.id ?? '',
                      username: _authService.currentUser?.email ?? 'Anonymous',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primaryLight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.dashboard, color: Colors.white, size: 40),
                SizedBox(height: 1.h),
                Text(
                  'Dashboard Control',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.refresh),
            title: Text('Refresh Control'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.analytics),
            title: Text('Analytics Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin-dashboard');
            },
          ),
          ListTile(
            leading: Icon(Icons.security),
            title: Text('Security Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/ai-security-dashboard');
            },
          ),
        ],
      ),
    );
  }
}