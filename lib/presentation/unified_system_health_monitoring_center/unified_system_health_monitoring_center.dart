import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/gemini_cost_analyzer_service.dart';
import '../../services/perplexity_log_analysis_service.dart';
import '../../services/system_health_monitoring_service.dart';

class UnifiedSystemHealthMonitoringCenter extends StatefulWidget {
  const UnifiedSystemHealthMonitoringCenter({super.key});

  @override
  State<UnifiedSystemHealthMonitoringCenter> createState() =>
      _UnifiedSystemHealthMonitoringCenterState();
}

class _UnifiedSystemHealthMonitoringCenterState
    extends State<UnifiedSystemHealthMonitoringCenter>
    with SingleTickerProviderStateMixin {
  final SystemHealthMonitoringService _healthService =
      SystemHealthMonitoringService.instance;
  final GeminiCostAnalyzerService _costAnalyzer =
      GeminiCostAnalyzerService.instance;
  final PerplexityLogAnalysisService _logAnalysis =
      PerplexityLogAnalysisService.instance;

  late TabController _tabController;
  Timer? _refreshTimer;

  Map<String, dynamic> _healthData = {};
  List<Map<String, dynamic>> _activeAlerts = [];
  Map<String, dynamic> _costReport = {};
  Map<String, dynamic> _threatAnalysis = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _healthService.stopMonitoring();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _loadAllData(silent: true);
      }
    });
  }

  Future<void> _loadAllData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _healthService.checkAllServices(),
        _healthService.getActiveAlerts(),
        _costAnalyzer.generateCostReport(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        ),
        _logAnalysis.analyzeSystemLogs(timeWindow: const Duration(hours: 24)),
      ]);

      if (mounted) {
        setState(() {
          _healthData = results[0] as Map<String, dynamic>;
          _activeAlerts = results[1] as List<Map<String, dynamic>>;
          _costReport = (results[2] as Map<String, dynamic>)['report'] ?? {};
          _threatAnalysis = results[3] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load all data error: $e');
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Health Monitoring Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAllData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Services'),
            Tab(text: 'Alerts'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildServicesTab(),
                _buildAlertsTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final overallHealth = _healthData['overall_health'] ?? 0;
    final color = overallHealth >= 90
        ? Colors.green
        : overallHealth >= 70
        ? Colors.orange
        : Colors.red;

    return RefreshIndicator(
      onRefresh: () => _loadAllData(),
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Text(
                    'Overall System Health',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '$overallHealth',
                    style: TextStyle(
                      fontSize: 48.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  LinearProgressIndicator(
                    value: overallHealth / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          _buildQuickStatsCard(),
          SizedBox(height: 2.h),
          _buildThreatSummaryCard(),
          SizedBox(height: 2.h),
          _buildCostSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    final services = _healthData['services'] as Map<String, dynamic>? ?? {};
    final healthyCount = services.values
        .where((s) => s['status'] == 'healthy')
        .length;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Services',
                  '$healthyCount/${services.length}',
                  Icons.cloud,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Alerts',
                  '${_activeAlerts.length}',
                  Icons.warning,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Threats',
                  '${(_threatAnalysis['threats_detected'] as List?)?.length ?? 0}',
                  Icons.security,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildThreatSummaryCard() {
    final threatScore = _threatAnalysis['overall_threat_score'] ?? 0;
    final color = threatScore < 30
        ? Colors.green
        : threatScore < 70
        ? Colors.orange
        : Colors.red;

    return Card(
      child: ListTile(
        leading: Icon(Icons.security, color: color, size: 32),
        title: const Text('Threat Level'),
        subtitle: Text('Score: $threatScore/100'),
        trailing: Icon(Icons.chevron_right),
        onTap: () => _tabController.animateTo(2),
      ),
    );
  }

  Widget _buildCostSummaryCard() {
    final currentCost = _costReport['current_monthly_cost'] ?? 0.0;
    final savings = _costReport['potential_savings'] ?? 0.0;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.attach_money, color: Colors.green, size: 32),
        title: const Text('Monthly AI Cost'),
        subtitle: Text(
          '\$${currentCost.toStringAsFixed(2)} (Save \$${savings.toStringAsFixed(2)})',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _tabController.animateTo(3),
      ),
    );
  }

  Widget _buildServicesTab() {
    final services = _healthData['services'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: () => _loadAllData(),
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final entry = services.entries.elementAt(index);
          final serviceName = entry.key;
          final serviceData = entry.value as Map<String, dynamic>;
          final healthScore = serviceData['health_score'] ?? 0;
          final color = healthScore >= 90
              ? Colors.green
              : healthScore >= 70
              ? Colors.orange
              : Colors.red;

          return Card(
            margin: EdgeInsets.only(bottom: 2.h),
            child: ExpansionTile(
              leading: Icon(Icons.cloud, color: color, size: 32),
              title: Text(serviceName.toUpperCase()),
              subtitle: Text('Health: $healthScore/100'),
              trailing: Text(
                serviceData['status'] ?? 'unknown',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildServiceDetail(
                        'Uptime',
                        '${serviceData['uptime_percentage'] ?? 0}%',
                      ),
                      _buildServiceDetail(
                        'Response Time',
                        '${serviceData['response_time_ms'] ?? 0}ms',
                      ),
                      if (serviceData.containsKey('rate_limit_remaining'))
                        _buildServiceDetail(
                          'Rate Limit',
                          '${serviceData['rate_limit_remaining']}/${serviceData['rate_limit_total']}',
                        ),
                      if (serviceData.containsKey('delivery_rate'))
                        _buildServiceDetail(
                          'Delivery Rate',
                          '${serviceData['delivery_rate']}%',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp)),
          Text(
            value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return RefreshIndicator(
      onRefresh: () => _loadAllData(),
      child: _activeAlerts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 2.h),
                  Text('No Active Alerts', style: TextStyle(fontSize: 18.sp)),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: _activeAlerts.length,
              itemBuilder: (context, index) {
                final alert = _activeAlerts[index];
                final severity = alert['severity'] as String? ?? 'low';
                final color = severity == 'critical'
                    ? Colors.red
                    : severity == 'high'
                    ? Colors.orange
                    : Colors.yellow;

                return Card(
                  margin: EdgeInsets.only(bottom: 2.h),
                  child: ListTile(
                    leading: Icon(Icons.warning, color: color, size: 32),
                    title: Text(alert['alert_type'] ?? 'Unknown'),
                    subtitle: Text(alert['alert_message'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () => _acknowledgeAlert(alert['alert_id']),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: () => _loadAllData(),
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildCostAnalyticsCard(),
          SizedBox(height: 2.h),
          _buildThreatAnalyticsCard(),
        ],
      ),
    );
  }

  Widget _buildCostAnalyticsCard() {
    final currentCost = _costReport['current_monthly_cost'] ?? 0.0;
    final projectedCost = _costReport['projected_gemini_cost'] ?? 0.0;
    final savings = _costReport['potential_savings'] ?? 0.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cost Analytics',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildServiceDetail(
              'Current Monthly Cost',
              '\$${currentCost.toStringAsFixed(2)}',
            ),
            _buildServiceDetail(
              'Projected with Gemini',
              '\$${projectedCost.toStringAsFixed(2)}',
            ),
            _buildServiceDetail(
              'Potential Savings',
              '\$${savings.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatAnalyticsCard() {
    final threats = _threatAnalysis['threats_detected'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Threat Analytics',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildServiceDetail('Threats Detected (24h)', '${threats.length}'),
            _buildServiceDetail(
              'Logs Analyzed',
              '${_threatAnalysis['log_count'] ?? 0}',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    await _healthService.acknowledgeAlert(alertId);
    _loadAllData();
  }
}
