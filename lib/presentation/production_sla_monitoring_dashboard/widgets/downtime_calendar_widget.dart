import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../services/sla_monitoring_service.dart';

class DowntimeCalendarWidget extends StatefulWidget {
  const DowntimeCalendarWidget({super.key});

  @override
  State<DowntimeCalendarWidget> createState() => _DowntimeCalendarWidgetState();
}

class _DowntimeCalendarWidgetState extends State<DowntimeCalendarWidget> {
  final SLAMonitoringService _service = SLAMonitoringService.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _incidents = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final ninetyDaysAgo = now.subtract(Duration(days: 90));

      final incidents = await _service.getDowntimeIncidents(
        startDate: ninetyDaysAgo,
        endDate: now,
      );

      final incidentMap = <DateTime, List<Map<String, dynamic>>>{};
      for (var incident in incidents) {
        final date = DateTime.parse(incident['started_at']);
        final dateKey = DateTime(date.year, date.month, date.day);
        incidentMap.putIfAbsent(dateKey, () => []).add(incident);
      }

      setState(() {
        _incidents = incidentMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading incidents: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: SizedBox(
          height: 50.h,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.now().subtract(Duration(days: 90)),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(128),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _showIncidentDetails(selectedDay);
              },
              eventLoader: (day) {
                final dateKey = DateTime(day.year, day.month, day.day);
                return _incidents[dateKey] ?? [];
              },
            ),
            SizedBox(height: 2.h),
            _buildLegend(),
            if (_selectedDay != null) ...[
              SizedBox(height: 2.h),
              _buildIncidentsList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(Colors.green, 'Operational (100%)'),
        _buildLegendItem(Colors.yellow, 'Degraded (95-100%)'),
        _buildLegendItem(Colors.orange, 'Outage (90-95%)'),
        _buildLegendItem(Colors.red, 'Major Outage (<90%)'),
      ],
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
        Text(label, style: TextStyle(fontSize: 10.sp)),
      ],
    );
  }

  Widget _buildIncidentsList() {
    final dateKey = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    final dayIncidents = _incidents[dateKey] ?? [];

    if (dayIncidents.isEmpty) {
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 2.w),
              Text(
                'No incidents on this day',
                style: TextStyle(color: Colors.green[700]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incidents on ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        ...dayIncidents.map((incident) => _buildIncidentCard(incident)),
      ],
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final severity = incident['severity'] ?? 'P3';
    final duration = incident['duration_minutes'] ?? 0;

    Color severityColor;
    switch (severity) {
      case 'P0':
        severityColor = Colors.red;
        break;
      case 'P1':
        severityColor = Colors.orange;
        break;
      case 'P2':
        severityColor = Colors.yellow;
        break;
      default:
        severityColor = Colors.blue;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: severityColor.withAlpha(51),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            severity,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: severityColor,
            ),
          ),
        ),
        title: Text(
          incident['title'] ?? 'Unknown Incident',
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Duration: $duration minutes',
          style: TextStyle(fontSize: 11.sp),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14.sp),
        onTap: () => _showIncidentDetailsModal(incident),
      ),
    );
  }

  void _showIncidentDetails(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    final dayIncidents = _incidents[dateKey] ?? [];

    if (dayIncidents.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incidents on ${day.day}/${day.month}/${day.year}',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            ...dayIncidents.map((incident) => _buildIncidentCard(incident)),
          ],
        ),
      ),
    );
  }

  void _showIncidentDetailsModal(Map<String, dynamic> incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Incident Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Title', incident['title'] ?? 'N/A'),
              _buildDetailRow('Severity', incident['severity'] ?? 'N/A'),
              _buildDetailRow(
                'Duration',
                '${incident['duration_minutes'] ?? 0} minutes',
              ),
              _buildDetailRow(
                'Root Cause',
                incident['root_cause'] ?? 'Under investigation',
              ),
              _buildDetailRow('Status', incident['status'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(value, style: TextStyle(fontSize: 12.sp)),
        ],
      ),
    );
  }
}
