import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../services/security_monitoring_service.dart';

class SecurityMonitoringDashboard extends StatefulWidget {
  const SecurityMonitoringDashboard({super.key});

  @override
  State<SecurityMonitoringDashboard> createState() =>
      _SecurityMonitoringDashboardState();
}

class _SecurityMonitoringDashboardState
    extends State<SecurityMonitoringDashboard> {
  final SecurityMonitoringService _securityService =
      SecurityMonitoringService.instance;

  Map<String, int> _metrics = {};
  Map<String, List<Map<String, dynamic>>> _timelineData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final metrics = await _securityService.getTodaySecurityMetrics();
    final timeline = await _securityService.get24HourTimeline();

    setState(() {
      _metrics = metrics;
      _timelineData = timeline;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Monitoring'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Security Metrics Cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 2.h,
                      crossAxisSpacing: 3.w,
                      childAspectRatio: 1.3,
                      children: [
                        _buildSecurityMetricCard(
                          title: 'CORS Violations',
                          count: _metrics['cors_violations'] ?? 0,
                          icon: Icons.shield_outlined,
                          color: Colors.orange,
                          onTap: () => _showFilteredIncidents('cors_violation'),
                        ),
                        _buildSecurityMetricCard(
                          title: 'Rate Limit Breaches',
                          count: _metrics['rate_limit_breaches'] ?? 0,
                          icon: Icons.speed,
                          color: Colors.red,
                          onTap: () =>
                              _showFilteredIncidents('rate_limit_breach'),
                        ),
                        _buildSecurityMetricCard(
                          title: 'Webhook Replay Attacks',
                          count: _metrics['webhook_replay_attacks'] ?? 0,
                          icon: Icons.replay,
                          color: Colors.purple,
                          onTap: () =>
                              _showFilteredIncidents('webhook_replay_attack'),
                        ),
                        _buildSecurityMetricCard(
                          title: 'SQL Injection Attempts',
                          count: _metrics['sql_injection_attempts'] ?? 0,
                          icon: Icons.code,
                          color: Colors.deepOrange,
                          onTap: () =>
                              _showFilteredIncidents('sql_injection_attempt'),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),

                    // 24-Hour Activity Timeline
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '24-Hour Security Activity',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            SizedBox(
                              height: 30.h,
                              child: _buildTimelineChart(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),

                    // Real-Time Incident Feed
                    Text(
                      'Real-Time Incident Feed',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _securityService.getIncidentStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final incidents = snapshot.data!;

                        if (incidents.isEmpty) {
                          return Card(
                            child: Padding(
                              padding: EdgeInsets.all(4.w),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 48,
                                      color: Colors.green,
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'No security incidents detected',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: incidents.length,
                          itemBuilder: (context, index) {
                            final incident = incidents[index];
                            return _buildIncidentCard(incident);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimelineChart() {
    if (_timelineData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10.sp),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: TextStyle(fontSize: 10.sp),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          _buildLineChartBarData(
            _timelineData['cors_violations'] ?? [],
            Colors.orange,
          ),
          _buildLineChartBarData(
            _timelineData['rate_limit_breaches'] ?? [],
            Colors.red,
          ),
          _buildLineChartBarData(
            _timelineData['webhook_replay_attacks'] ?? [],
            Colors.purple,
          ),
          _buildLineChartBarData(
            _timelineData['sql_injection_attempts'] ?? [],
            Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(
    List<Map<String, dynamic>> data,
    Color color,
  ) {
    return LineChartBarData(
      spots: data
          .map(
            (point) => FlSpot(
              (point['hour'] as int).toDouble(),
              (point['count'] as int).toDouble(),
            ),
          )
          .toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(show: false),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final severity = incident['severity'] ?? 'unknown';
    final Color severityColor = _getSeverityColor(severity);
    final IconData icon = _getIncidentIcon(incident['incident_type']);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: severityColor.withAlpha(51),
          child: Icon(icon, color: severityColor),
        ),
        title: Text(
          incident['description'] ?? 'Security Incident',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.5.h),
            Text(
              timeago.format(DateTime.parse(incident['created_at'])),
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: severityColor),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showIncidentDetails(incident),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIncidentIcon(String? type) {
    switch (type) {
      case 'cors_violation':
        return Icons.shield_outlined;
      case 'rate_limit_breach':
        return Icons.speed;
      case 'webhook_replay_attack':
        return Icons.replay;
      case 'sql_injection_attempt':
        return Icons.code;
      default:
        return Icons.warning;
    }
  }

  Widget _buildSecurityMetricCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(height: 1.h),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIncidentDetails(Map<String, dynamic> incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildIncidentDetailModal(incident),
    );
  }

  Widget _buildIncidentDetailModal(Map<String, dynamic> incident) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(4.w),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Incident Details',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              _buildDetailRow('Type', incident['incident_type'] ?? 'N/A'),
              _buildDetailRow('Severity', incident['severity'] ?? 'N/A'),
              _buildDetailRow('Description', incident['description'] ?? 'N/A'),
              _buildDetailRow('Created At', incident['created_at'] ?? 'N/A'),
              if (incident['metadata'] != null)
                _buildDetailRow('Metadata', incident['metadata'].toString()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  void _showFilteredIncidents(String incidentType) {
    // Navigate to filtered incident list
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Showing $incidentType incidents')));
  }
}
