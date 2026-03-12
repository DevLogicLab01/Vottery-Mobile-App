import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/incident_response_service.dart';
import '../../services/performance_optimization_service.dart';
import '../../services/pagerduty_service.dart';

class AutomatedIncidentResponseCenter extends StatefulWidget {
  const AutomatedIncidentResponseCenter({super.key});

  @override
  State<AutomatedIncidentResponseCenter> createState() =>
      _AutomatedIncidentResponseCenterState();
}

class _AutomatedIncidentResponseCenterState
    extends State<AutomatedIncidentResponseCenter> {
  final IncidentResponseService _service = IncidentResponseService.instance;
  final PerformanceOptimizationService _performanceService =
      PerformanceOptimizationService.instance;
  final PagerDutyService _pagerdutyService = PagerDutyService.instance;
  List<Map<String, dynamic>> _incidents = [];
  List<Map<String, dynamic>> _optimizations = [];
  List<Map<String, dynamic>> _onCallSchedules = [];
  bool _isLoading = true;
  String _filterStatus = 'all';
  String _filterSeverity = 'all';

  @override
  void initState() {
    super.initState();
    _loadIncidents();
    _loadOptimizations();
    _loadOnCallSchedules();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);
    try {
      final incidents = await _service.getActiveIncidents();
      setState(() {
        _incidents = incidents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOptimizations() async {
    try {
      final optimizations = await _performanceService.getOptimizations(
        status: 'pending',
      );
      setState(() {
        _optimizations = optimizations;
      });
    } catch (e) {
      debugPrint('Load optimizations error: $e');
    }
  }

  Future<void> _loadOnCallSchedules() async {
    try {
      await _pagerdutyService.syncOnCallSchedules();
      final schedules = await _pagerdutyService.getOnCallSchedules();
      setState(() {
        _onCallSchedules = schedules;
      });
    } catch (e) {
      debugPrint('Load on-call schedules error: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredIncidents {
    return _incidents.where((incident) {
      if (_filterStatus != 'all' && incident['status'] != _filterStatus) {
        return false;
      }
      if (_filterSeverity != 'all' && incident['severity'] != _filterSeverity) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Incident Response Center'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateIncidentDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncidents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadIncidents,
              child: Column(
                children: [
                  _buildCommandDashboard(),
                  _buildFilters(),
                  Expanded(child: _buildIncidentsList()),
                ],
              ),
            ),
    );
  }

  Widget _buildCommandDashboard() {
    final activeCount = _incidents
        .where((i) => i['status'] != 'resolved')
        .length;
    final p0Count = _incidents.where((i) => i['severity'] == 'P0').length;
    final p1Count = _incidents.where((i) => i['severity'] == 'P1').length;
    final criticalOptimizations = _optimizations
        .where((o) => o['severity'] == 'critical')
        .length;

    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDashboardCard(
                'Active',
                activeCount.toString(),
                Colors.orange,
              ),
              _buildDashboardCard('P0', p0Count.toString(), Colors.red),
              _buildDashboardCard(
                'P1',
                p1Count.toString(),
                Colors.orange[700]!,
              ),
              _buildDashboardCard(
                'Critical Optimizations',
                criticalOptimizations.toString(),
                Colors.purple,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_onCallSchedules.isNotEmpty)
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.blue[700], size: 20),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'On-Call: ${_onCallSchedules.first['current_on_call_user_id'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/pagerduty-on-call-dashboard',
                      );
                    },
                    child: Text(
                      'View Schedule',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _filterStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
              ),
              items:
                  [
                        'all',
                        'detected',
                        'acknowledged',
                        'investigating',
                        'resolving',
                        'resolved',
                      ]
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase()),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() => _filterStatus = value!);
              },
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _filterSeverity,
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
              ),
              items: ['all', 'P0', 'P1', 'P2', 'P3', 'P4']
                  .map(
                    (severity) => DropdownMenuItem(
                      value: severity,
                      child: Text(severity),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _filterSeverity = value!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentsList() {
    if (_filteredIncidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48.sp, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No Incidents Found',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _filteredIncidents.length,
      itemBuilder: (context, index) {
        return _buildIncidentCard(_filteredIncidents[index]);
      },
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final severity = incident['severity'] as String;
    final status = incident['status'] as String;
    final title = incident['title'] as String;
    final affectedSystems =
        (incident['affected_systems'] as List?)?.cast<String>() ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _getSeverityColor(severity), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(4.w),
        childrenPadding: EdgeInsets.all(4.w),
        leading: Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: _getSeverityColor(severity),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Text(
            severity,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 1.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(fontSize: 10.sp, color: Colors.white),
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  '${affectedSystems.length} systems',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        children: [_buildIncidentDetails(incident)],
      ),
    );
  }

  Widget _buildIncidentDetails(Map<String, dynamic> incident) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        Text(
          incident['description'] ?? 'No description',
          style: TextStyle(fontSize: 12.sp),
        ),
        SizedBox(height: 2.h),
        Text(
          'Affected Systems',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children:
              ((incident['affected_systems'] as List?)?.cast<String>() ?? [])
                  .map(
                    (system) => Chip(
                      label: Text(system, style: TextStyle(fontSize: 11.sp)),
                      backgroundColor: Colors.blue[50],
                    ),
                  )
                  .toList(),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _updateIncidentStatus(incident['id'], 'acknowledged'),
                icon: const Icon(Icons.check, size: 16.0),
                label: const Text('Acknowledge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _updateIncidentStatus(incident['id'], 'resolved'),
                icon: const Icon(Icons.done_all, size: 16.0),
                label: const Text('Resolve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'P0':
        return Colors.red;
      case 'P1':
        return Colors.orange[700]!;
      case 'P2':
        return Colors.orange;
      case 'P3':
        return Colors.yellow[700]!;
      case 'P4':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'detected':
        return Colors.orange;
      case 'acknowledged':
        return Colors.yellow[700]!;
      case 'investigating':
        return Colors.blue;
      case 'resolving':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateIncidentStatus(
    String incidentId,
    String newStatus,
  ) async {
    // Placeholder for status update
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Incident status updated to $newStatus')),
    );
    await _loadIncidents();
  }

  void _showCreateIncidentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Incident'),
        content: const Text('Manual incident creation form would go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Incident created')));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
