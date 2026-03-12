import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/system_health_monitoring_service.dart';

class RealTimeSystemMonitoringDashboard extends StatefulWidget {
  const RealTimeSystemMonitoringDashboard({super.key});

  @override
  State<RealTimeSystemMonitoringDashboard> createState() =>
      _RealTimeSystemMonitoringDashboardState();
}

class _RealTimeSystemMonitoringDashboardState
    extends State<RealTimeSystemMonitoringDashboard> {
  final SystemHealthMonitoringService _monitoringService =
      SystemHealthMonitoringService.instance;

  Map<String, dynamic> _healthData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() => _isLoading = true);
    final data = await _monitoringService.checkAllServices();
    setState(() {
      _healthData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Monitoring'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _checkHealth),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _checkHealth,
              child: ListView(
                padding: EdgeInsets.all(4.w),
                children: [
                  _buildOverallHealthCard(),
                  SizedBox(height: 2.h),
                  _buildServicesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallHealthCard() {
    final overallHealth = _healthData['overall_health'] ?? 0;
    final color = overallHealth >= 90
        ? Colors.green
        : overallHealth >= 70
        ? Colors.orange
        : Colors.red;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Text(
              'Overall System Health',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Text(
              '$overallHealth',
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    final services = _healthData['services'] as Map<String, dynamic>? ?? {};

    return Column(
      children: services.entries.map((entry) {
        final healthScore = entry.value['health_score'] ?? 0;
        final color = healthScore >= 90
            ? Colors.green
            : healthScore >= 70
            ? Colors.orange
            : Colors.red;

        return Card(
          margin: EdgeInsets.only(bottom: 1.h),
          child: ListTile(
            leading: Icon(Icons.cloud, color: color),
            title: Text(entry.key.toUpperCase()),
            subtitle: Text('Status: ${entry.value['status']}'),
            trailing: Text(
              '$healthScore',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
