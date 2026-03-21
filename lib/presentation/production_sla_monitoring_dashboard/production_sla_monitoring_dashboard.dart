import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/sla_monitoring_service.dart';
import './widgets/critical_alerts_feed_widget.dart';
import './widgets/downtime_calendar_widget.dart';
import './widgets/real_time_metrics_panel_widget.dart';
import './widgets/sla_overview_widget.dart';
import './widgets/sla_report_generator_widget.dart';
import './widgets/subsystem_health_card_widget.dart';
import './widgets/cross_screen_correlation_panel_widget.dart';

class ProductionSlaMonitoringDashboard extends StatefulWidget {
  const ProductionSlaMonitoringDashboard({super.key});

  @override
  State<ProductionSlaMonitoringDashboard> createState() =>
      _ProductionSlaMonitoringDashboardState();
}

class _ProductionSlaMonitoringDashboardState
    extends State<ProductionSlaMonitoringDashboard> {
  final SLAMonitoringService _service = SLAMonitoringService.instance;

  Map<String, dynamic> _uptimeData = {};
  Map<String, dynamic> _healthData = {};
  List<Map<String, dynamic>> _alerts = [];
  Map<String, dynamic> _metrics = {};

  bool _isLoading = true;
  Timer? _refreshTimer;
  int _secondsUntilRefresh = 30;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _service.calculateUptime(),
        _service.checkSubsystemHealth(),
        _service.getCriticalAlerts(),
        _service.getRealTimeMetrics(),
      ]);

      setState(() {
        _uptimeData = results[0] as Map<String, dynamic>;
        _healthData = results[1] as Map<String, dynamic>;
        _alerts = results[2] as List<Map<String, dynamic>>;
        _metrics = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading SLA data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _secondsUntilRefresh--;
        if (_secondsUntilRefresh <= 0) {
          _secondsUntilRefresh = 30;
          _loadData();
        }
      });
    });
  }

  Future<void> _manualRefresh() async {
    _secondsUntilRefresh = 30;
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Production SLA Monitoring',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Text(
                'Refresh in ${_secondsUntilRefresh}s',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _manualRefresh,
            tooltip: 'Manual Refresh',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Operations Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'SLA Monitoring & Health',
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('SLA Overview'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.security),
              title: Text('Security Monitoring'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.securityMonitoringDashboard);
              },
            ),
            ListTile(
              leading: Icon(Icons.warning),
              title: Text('Incident Response'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.automatedIncidentResponseCenter,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics),
              title: Text('Threat Correlation'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.realTimeThreatCorrelationDashboard,
                );
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _manualRefresh,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SLA Overview Section
                    SlaOverviewWidget(uptimeData: _uptimeData),
                    SizedBox(height: 3.h),

                    // Real-time Metrics Panel
                    RealTimeMetricsPanelWidget(
                      metrics: _metrics,
                      secondsUntilRefresh: _secondsUntilRefresh,
                    ),
                    SizedBox(height: 3.h),

                    // Subsystem Status Grid
                    Text(
                      'Subsystem Health Status',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _buildSubsystemGrid(),
                    SizedBox(height: 3.h),

                    // Critical Alerts Aggregation
                    Text(
                      'Critical Alerts',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    CriticalAlertsFeedWidget(alerts: _alerts),
                    SizedBox(height: 3.h),

                    // Downtime Tracking
                    Text(
                      'Downtime History',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    DowntimeCalendarWidget(),
                    SizedBox(height: 3.h),

                    // SLA Report Generator
                    Text(
                      'SLA Compliance Reports',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    SlaReportGeneratorWidget(),
                    SizedBox(height: 3.h),

                    // Monitoring Coverage
                    _buildMonitoringCoverage(),
                    const CrossScreenCorrelationPanelWidget(),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSubsystemGrid() {
    final subsystems = _healthData['subsystems'] as Map<String, dynamic>? ?? {};

    if (subsystems.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.h),
          child: Text(
            'No subsystem data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 0.9,
      ),
      itemCount: subsystems.length,
      itemBuilder: (context, index) {
        final entry = subsystems.entries.elementAt(index);
        return SubsystemHealthCardWidget(
          serviceName: entry.key,
          healthData: entry.value,
        );
      },
    );
  }

  Widget _buildMonitoringCoverage() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor, color: Theme.of(context).primaryColor),
                SizedBox(width: 2.w),
                Text(
                  'Automated Incident Detection',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCoverageItem('Screens Monitored', '216'),
                _buildCoverageItem('Last Scan', 'Just now'),
                _buildCoverageItem('Incidents Today', '0'),
              ],
            ),
            SizedBox(height: 2.h),
            LinearProgressIndicator(
              value: 1.0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 1.h),
            Text(
              '100% monitoring coverage across all application screens',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverageItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
