import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../services/status_page_service.dart';

class StatusPageScreen extends StatefulWidget {
  const StatusPageScreen({super.key});

  @override
  State<StatusPageScreen> createState() => _StatusPageScreenState();
}

class _StatusPageScreenState extends State<StatusPageScreen> {
  final _statusService = StatusPageService.instance;
  final _emailController = TextEditingController();

  bool _isLoading = true;
  String _overallStatus = 'operational';
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _currentIncidents = [];
  List<Map<String, dynamic>> _scheduledMaintenance = [];
  List<Map<String, dynamic>> _uptimeRecords = [];
  Map<String, dynamic> _uptimeStats = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final systemStatus = await _statusService.getSystemStatus();
    final incidents = await _statusService.getCurrentIncidents();
    final maintenance = await _statusService.getScheduledMaintenance();
    final uptime = await _statusService.getHistoricalUptime();
    final stats = await _statusService.getUptimeStatistics();

    if (mounted) {
      setState(() {
        _overallStatus = systemStatus['overall_status'] ?? 'operational';
        _services = List<Map<String, dynamic>>.from(
          systemStatus['services'] ?? [],
        );
        _currentIncidents = incidents;
        _scheduledMaintenance = maintenance;
        _uptimeRecords = uptime;
        _uptimeStats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribeToUpdates() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    final success = await _statusService.subscribeToUpdates(
      _emailController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Successfully subscribed to updates!'
                : 'Subscription failed. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _emailController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vottery Status'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.all(3.w),
                children: [
                  _buildOverallStatusCard(),
                  SizedBox(height: 2.h),
                  _buildSystemComponentsCard(),
                  SizedBox(height: 2.h),
                  if (_currentIncidents.isNotEmpty) ...[
                    _buildCurrentIncidentsCard(),
                    SizedBox(height: 2.h),
                  ],
                  if (_scheduledMaintenance.isNotEmpty) ...[
                    _buildScheduledMaintenanceCard(),
                    SizedBox(height: 2.h),
                  ],
                  _buildUptimeStatisticsCard(),
                  SizedBox(height: 2.h),
                  _buildHistoricalUptimeCalendar(),
                  SizedBox(height: 2.h),
                  _buildSubscribeCard(),
                  SizedBox(height: 2.h),
                  _buildFooter(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallStatusCard() {
    final statusConfig = _getStatusConfig(_overallStatus);

    return Card(
      color: statusConfig['color'].withAlpha(26),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Icon(
              statusConfig['icon'],
              size: 48.sp,
              color: statusConfig['color'],
            ),
            SizedBox(height: 1.h),
            Text(
              statusConfig['title'],
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: statusConfig['color'],
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              statusConfig['description'],
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Last updated: ${_formatTimestamp(DateTime.now().toIso8601String())}',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemComponentsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Components',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            ..._services.map((service) => _buildServiceStatusItem(service)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusItem(Map<String, dynamic> service) {
    final serviceName = service['service_name'] as String;
    final status = service['current_status'] as String;
    final responseTime = service['response_time_ms'];
    final uptime = service['uptime_percentage'];

    final statusConfig = _getStatusConfig(status);

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(statusConfig['icon'], color: statusConfig['color'], size: 20.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (responseTime != null)
                  Text(
                    'Response time: ${responseTime.toStringAsFixed(0)}ms',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                if (uptime != null)
                  Text(
                    'Uptime: ${uptime.toStringAsFixed(2)}%',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: statusConfig['color'],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentIncidentsCard() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Current Incidents',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            ..._currentIncidents.map(
              (incident) => _buildIncidentItem(incident),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentItem(Map<String, dynamic> incident) {
    final title = incident['title'] as String;
    final description = incident['description'] as String;
    final status = incident['status'] as String;
    final severity = incident['severity'] as String;
    final startedAt = incident['started_at'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 0.5.h),
          Text(
            description,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Ongoing for ${_formatDuration(startedAt)}',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledMaintenanceCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.blue, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Scheduled Maintenance',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            ..._scheduledMaintenance.map(
              (maintenance) => _buildMaintenanceItem(maintenance),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceItem(Map<String, dynamic> maintenance) {
    final title = maintenance['title'] as String;
    final description = maintenance['description'] as String;
    final maintenanceStart = maintenance['maintenance_start'] as String;
    final maintenanceEnd = maintenance['maintenance_end'] as String;
    final impactLevel = maintenance['impact_level'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 0.5.h),
          Text(
            description,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.schedule, size: 14.sp, color: Colors.grey[600]),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  '${_formatMaintenanceDate(maintenanceStart)} - ${_formatMaintenanceDate(maintenanceEnd)}',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: _getImpactColor(impactLevel),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Impact: $impactLevel',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUptimeStatisticsCard() {
    final ninetyDayUptime = _uptimeStats['90_day_uptime'] ?? 100.0;
    final thirtyDayUptime = _uptimeStats['30_day_uptime'] ?? 100.0;
    final sevenDayUptime = _uptimeStats['7_day_uptime'] ?? 100.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uptime Statistics',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildUptimeStatItem('90 Days', ninetyDayUptime),
                ),
                Expanded(
                  child: _buildUptimeStatItem('30 Days', thirtyDayUptime),
                ),
                Expanded(child: _buildUptimeStatItem('7 Days', sevenDayUptime)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUptimeStatItem(String label, double uptime) {
    return Column(
      children: [
        Text(
          '${uptime.toStringAsFixed(2)}%',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: uptime >= 99.9 ? Colors.green : Colors.orange,
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

  Widget _buildHistoricalUptimeCalendar() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historical Uptime (90 Days)',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 90)),
              lastDay: DateTime.now(),
              focusedDay: DateTime.now(),
              calendarFormat: CalendarFormat.month,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildUptimeCalendarDay(day);
                },
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green[700]!, '100%'),
                SizedBox(width: 2.w),
                _buildLegendItem(Colors.green[300]!, '99-100%'),
                SizedBox(width: 2.w),
                _buildLegendItem(Colors.yellow[600]!, '95-99%'),
                SizedBox(width: 2.w),
                _buildLegendItem(Colors.red, '<95%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUptimeCalendarDay(DateTime day) {
    final record = _uptimeRecords.firstWhere(
      (r) => r['record_date'] == day.toIso8601String().split('T')[0],
      orElse: () => {'uptime_percentage': 100.0},
    );

    final uptime = (record['uptime_percentage'] as num).toDouble();
    final color = _getUptimeColor(uptime);

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildSubscribeCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscribe to Updates',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'Get notified about incidents, maintenance, and monthly reports',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'Enter your email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 1.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _subscribeToUpdates,
                child: const Text('Subscribe'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        children: [
          Text(
            '© 2026 Vottery. All rights reserved.',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: () {}, child: const Text('Privacy Policy')),
              Text(' | ', style: TextStyle(color: Colors.grey[600])),
              TextButton(
                onPressed: () {},
                child: const Text('Terms of Service'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'operational':
        return {
          'icon': Icons.check_circle,
          'color': Colors.green,
          'title': 'All Systems Operational',
          'description': 'All services are running normally',
        };
      case 'degraded':
        return {
          'icon': Icons.warning,
          'color': Colors.orange,
          'title': 'Some Systems Degraded',
          'description': 'Some services are experiencing issues',
        };
      case 'outage':
        return {
          'icon': Icons.error,
          'color': Colors.red,
          'title': 'Major Outage',
          'description': 'Critical services are down',
        };
      default:
        return {
          'icon': Icons.help,
          'color': Colors.grey,
          'title': 'Status Unknown',
          'description': 'Unable to determine system status',
        };
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  Color _getImpactColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'no impact':
        return Colors.green;
      case 'minor disruption':
        return Colors.yellow[700]!;
      case 'service unavailable':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getUptimeColor(double uptime) {
    if (uptime == 100) return Colors.green[700]!;
    if (uptime >= 99) return Colors.green[300]!;
    if (uptime >= 95) return Colors.yellow[600]!;
    return Colors.red;
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) {
        return '${diff.inSeconds} seconds ago';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minutes ago';
      } else {
        return '${diff.inHours} hours ago';
      }
    } catch (e) {
      return timestamp;
    }
  }

  String _formatDuration(String startTime) {
    try {
      final start = DateTime.parse(startTime);
      final now = DateTime.now();
      final diff = now.difference(start);

      if (diff.inHours < 24) {
        return '${diff.inHours} hours';
      } else {
        return '${diff.inDays} days';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatMaintenanceDate(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }
}
